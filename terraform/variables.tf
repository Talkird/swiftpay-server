variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "instance_name" {
  description = "Name tag for EC2 instance"
  type        = string
  default     = "swiftpay-server"
}

variable "environment" {
  description = "Environment (Dev, Staging, Prod)"
  type        = string
  default     = "Prod"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "server_port" {
  description = "Port for Node.js server"
  type        = number
  default     = 3000
}

variable "enable_public_ip" {
  description = "Assign public IP to instance (DEPRECATED: Always use false with NAT Gateway)"
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet (for NAT Gateway)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "enable_ebs_encryption" {
  description = "Enable EBS encryption for root volume"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}
