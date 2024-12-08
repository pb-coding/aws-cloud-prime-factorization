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
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
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
  instance_type = "c5.12xlarge"
  key_name = aws_key_pair.admin.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.default.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake build-essential libgmp3-dev git
    git clone https://gitlab.inria.fr/cado-nfs/cado-nfs/ /root/cado-nfs
    cd /root/cado-nfs && make
  EOF
}

# Create worker servers
resource "aws_instance" "worker" {
  count         = 8
  ami           = "ami-066902f7df67250f8"
  instance_type = "c5.12xlarge"
  key_name      = aws_key_pair.admin.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.default.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential git
    git clone https://gitlab.inria.fr/cado-nfs/cado-nfs/ /root/cado-nfs
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