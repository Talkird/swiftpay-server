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

# Get latest Ubuntu 22.04 x86_64 AMI (matches t3.micro architecture)
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

# Create VPC for SwiftPay
resource "aws_vpc" "swiftpay" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "swiftpay-vpc"
    Environment = var.environment
  }
}

# Private Subnet - where the EC2 instance will run
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.swiftpay.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "swiftpay-private-subnet"
    Environment = var.environment
  }
}

# Public Subnet - where NAT Gateway will be placed
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.swiftpay.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "swiftpay-public-subnet"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "swiftpay" {
  vpc_id = aws_vpc.swiftpay.id

  tags = {
    Name        = "swiftpay-igw"
    Environment = var.environment
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "swiftpay-nat-eip"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.swiftpay]
}

# NAT Gateway for private subnet outbound connectivity
resource "aws_nat_gateway" "swiftpay" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "swiftpay-nat-gateway"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.swiftpay]
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.swiftpay.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.swiftpay.id
  }

  tags = {
    Name        = "swiftpay-public-rt"
    Environment = var.environment
  }
}

# Route table for private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.swiftpay.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.swiftpay.id
  }

  tags = {
    Name        = "swiftpay-private-rt"
    Environment = var.environment
  }
}

# Public subnet route table association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private subnet route table association
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Group for EC2 instance (in private subnet)
resource "aws_security_group" "swiftpay_app" {
  name_prefix = "swiftpay-app-"
  description = "Security group for SwiftPay application server"
  vpc_id      = aws_vpc.swiftpay.id

  # Inbound - Application traffic (internal only)
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Application traffic from VPC"
  }

  # Outbound - Allow all (for package downloads, external APIs, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic via NAT Gateway"
  }

  tags = {
    Name        = "swiftpay-app-sg"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Optional: Security Group for Bastion/Jump Host (if needed for SSH access)
resource "aws_security_group" "bastion" {
  name_prefix = "swiftpay-bastion-"
  description = "Security group for SSH access"
  vpc_id      = aws_vpc.swiftpay.id

  # Inbound - SSH access (restrict to your IP in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # IMPORTANT: Change to your IP range in production!
    description = "SSH access"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "swiftpay-bastion-sg"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for Systems Manager access (allows GitHub Actions to deploy via Session Manager)
resource "aws_iam_role" "swiftpay_ssm" {
  name_prefix = "swiftpay-ssm-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "swiftpay-ssm-role"
    Environment = var.environment
  }
}

# Attach SSM managed policy to role
resource "aws_iam_role_policy_attachment" "swiftpay_ssm_policy" {
  role       = aws_iam_role.swiftpay_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for IAM role
resource "aws_iam_instance_profile" "swiftpay" {
  name_prefix = "swiftpay-profile-"
  role        = aws_iam_role.swiftpay_ssm.name
}

# Create EC2 instance in private subnet
resource "aws_instance" "swiftpay" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.swiftpay_app.id]
  iam_instance_profile   = aws_iam_instance_profile.swiftpay.name

  # SECURITY FIX: Disable public IP (Infracost recommendation)
  # Use NAT Gateway for outbound connectivity instead
  associate_public_ip_address = false

  # Enable EBS encryption for the root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = var.enable_ebs_encryption

    tags = {
      Name        = "swiftpay-root-volume"
      Environment = var.environment
    }
  }

  # Enable detailed CloudWatch monitoring
  monitoring = var.enable_detailed_monitoring

  # User data script - with security enhancements
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Update system packages
    apt-get update
    apt-get upgrade -y
    
    # Install security tools and dependencies
    apt-get install -y \
      curl \
      git \
      wget \
      unattended-upgrades \
      fail2ban
    
    # Enable automatic security updates
    dpkg-reconfigure -plow unattended-upgrades
    
    # Configure fail2ban for SSH protection
    systemctl enable fail2ban
    systemctl start fail2ban
    
    # Create application directory
    mkdir -p /opt/swiftpay
    cd /opt/swiftpay
    
    # Install Node.js (LTS)
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    
    # Set up basic hardening
    # Disable unnecessary services
    systemctl disable --now avahi-daemon || true
    
    echo "SwiftPay Server initialization complete"
  EOF
  )

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Security    = "High"
  }

  # Ensure proper ordering of resources
  depends_on = [aws_nat_gateway.swiftpay]
}
