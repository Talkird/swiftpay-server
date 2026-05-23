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

# Create security group
resource "aws_security_group" "swiftpay" {
  name        = "swiftpay-sg"
  description = "Security group for swiftpay server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to your IP for security
  }

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.instance_name}-sg"
    Environment = var.environment
  }
}

# Create EC2 instance
resource "aws_instance" "swiftpay" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.swiftpay.id]
  associate_public_ip_address = var.enable_public_ip

  # User data script to deploy Node.js app
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              apt-get update
              apt-get upgrade -y
              
              # Install Node.js
              curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
              apt-get install -y nodejs
              
              # Clone repo and install dependencies
              cd /home/ubuntu
              git clone https://github.com/YOUR_GITHUB_USERNAME/swiftpay-server.git
              cd swiftpay-server
              npm install
              
              # Start the application
              npm start > /var/log/swiftpay.log 2>&1 &
              EOF
  )

  tags = {
    Name        = var.instance_name
    Environment = var.environment
  }
}
