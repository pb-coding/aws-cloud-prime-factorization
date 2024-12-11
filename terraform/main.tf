terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS
provider "aws" {
  region     = var.aws_region
}

resource "aws_key_pair" "admin" {
  key_name   = "my-admin-key"
  public_key = file("~/.ssh/my-admin-key.pub")
}

data "aws_vpc" "default" {
  default = true
}

# Create master server
resource "aws_instance" "master" {
  ami                    = "ami-066902f7df67250f8"
  instance_type          = "t3.large"
  key_name               = aws_key_pair.admin.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.default.id]

  user_data = <<-EOF
        #!/bin/bash
        set -e

        # Update and install dependencies
        apt-get update -y
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            build-essential gcc g++ cmake libgmp-dev git \
            python3 python3-pip python3-venv \
            libhwloc-dev gzip ssh rsync mysql-client wget \
            libgmp3-dev

        # Python dependencies
        pip3 install flask requests

        # Optional dependencies
        apt-get install -y libomp-dev

        # Ensure SSH private key is available
        mkdir -p /home/ubuntu/.ssh
        echo "${file("~/.ssh/my-admin-key")}" > /home/ubuntu/.ssh/id_rsa
        chmod 600 /home/ubuntu/.ssh/id_rsa
        chown -R ubuntu:ubuntu /home/ubuntu/.ssh

        # Add the SSH private key to the SSH agent
        eval $(ssh-agent -s)
        ssh-add /home/ubuntu/.ssh/id_rsa

        # Disable strict host key checking
        echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

        # Clone and build CADO-NFS
        su - ubuntu -c "git clone https://gitlab.inria.fr/cado-nfs/cado-nfs.git /home/ubuntu/cado-nfs"
        su - ubuntu -c "cd /home/ubuntu/cado-nfs && cmake -S . -B build && cmake --build build"

        su - ubuntu -c "touch /home/ubuntu/done"
  EOF
}

# Create worker servers
resource "aws_instance" "worker" {
  count         = 2
  ami           = "ami-066902f7df67250f8"
  instance_type = "t3.large"
  key_name      = aws_key_pair.admin.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.default.id]

  user_data = <<-EOF
        #!/bin/bash
        set -e

        # Update and install dependencies
        apt-get update -y
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            build-essential gcc g++ cmake libgmp-dev git \
            python3 python3-pip python3-venv \
            libhwloc-dev gzip ssh rsync mysql-client wget \
            libgmp3-dev

        # Python dependencies
        pip3 install flask requests

        # Optional dependencies
        apt-get install -y libomp-dev

        # Add public key to authorized_keys
        mkdir -p /home/ubuntu/.ssh
        echo "${file("~/.ssh/my-admin-key.pub")}" >> /home/ubuntu/.ssh/authorized_keys
        chmod 600 /home/ubuntu/.ssh/authorized_keys
        chmod 700 /home/ubuntu/.ssh
        chown -R ubuntu:ubuntu /home/ubuntu/.ssh

        # Disable strict host key checking
        echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

        # Clone and build CADO-NFS
        su - ubuntu -c "git clone https://gitlab.inria.fr/cado-nfs/cado-nfs.git /home/ubuntu/cado-nfs"
        su - ubuntu -c "cd /home/ubuntu/cado-nfs && cmake -S . -B build && cmake --build build"

        # Ensure cado-nfs-client.py is executable
        su - ubuntu -c "chmod +x /home/ubuntu/cado-nfs/cado-nfs-client.py"

        # Mark cloning as complete
        su - ubuntu -c "touch /home/ubuntu/done"
  EOF
}

resource "aws_security_group" "default" {
  name        = "prime-factorization-sg"
  description = "Allow SSH and internal traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Allow all traffic internally between instances
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}