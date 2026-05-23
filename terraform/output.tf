output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.swiftpay.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.swiftpay.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.swiftpay.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.swiftpay.id
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i /path/to/key.pem ubuntu@${aws_instance.swiftpay.public_ip}"
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.swiftpay.public_ip}:${var.server_port}"
}
