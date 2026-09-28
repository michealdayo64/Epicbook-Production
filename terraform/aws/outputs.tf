output "public_ip_vm_ec2" {
  description = "EC2 public IP"
  value       = aws_instance.vm_ec2.public_ip
}

output "public_ip_agentpool" {
  description = "EC2 public IP"
  value       = aws_instance.vm_agentpool.public_ip
}

output "admin_user" {
  description = "Administrator username for the AWS Ubuntu VM"
  value       = "ubuntu"
}

/*output "db_host" {
  description = "RDS database endpoint"
  value       = aws_db_instance.book_review_db.address
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.book_review_db.db_name
}*/