output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.swiftpay.id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.swiftpay.private_ip
}

output "nat_gateway_eip" {
  description = "Elastic IP address of NAT Gateway (for outbound traffic)"
  value       = aws_eip.nat.public_ip
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.swiftpay.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.swiftpay.id
}

output "private_subnet_id" {
  description = "Private subnet ID where EC2 instance runs"
  value       = aws_subnet.private.id
}

output "security_group_id" {
  description = "Security group ID for application"
  value       = aws_security_group.swiftpay_app.id
}

output "application_port" {
  description = "Port where application is running"
  value       = var.server_port
}

output "access_note" {
  description = "Note about accessing the instance"
  value       = "Instance is in a private subnet. Access via: 1) AWS Systems Manager Session Manager, 2) Bastion host, 3) VPN, or 4) Application Load Balancer (ALB)"
}
