terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# Create EC2 instance
resource "aws_instance" "swiftpay" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  associate_public_ip_address = var.enable_public_ip

  # User data script - basic system setup
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get upgrade -y
    apt-get install -y git curl
  EOF
  )

  tags = {
    Name        = var.instance_name
    Environment = var.environment
  }
}
