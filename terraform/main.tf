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
  ami           = "ami-066902f7df67250f8"
  instance_type = "t3.small"
  key_name = aws_key_pair.admin.key_name
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

        # Clone and build CADO-NFS
        git clone https://gitlab.inria.fr/cado-nfs/cado-nfs.git /root/cado-nfs
        cd /root/cado-nfs
        cmake -S . -B build
        cmake --build build
    EOF
}

# Create worker servers
resource "aws_instance" "worker" {
  count         = 2
  ami           = "ami-066902f7df67250f8"
  instance_type = "t3.small"
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

        # Clone and build CADO-NFS
        git clone https://gitlab.inria.fr/cado-nfs/cado-nfs.git /root/cado-nfs
        cd /root/cado-nfs
        cmake -S . -B build
        cmake --build build
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