output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.epicbook_vm.public_ip
}

output "admin_user" {
  description = "Administrator username for the AWS Ubuntu VM"
  value       = "ubuntu"
}

output "db_host" {
  description = "RDS database endpoint"
  value       = aws_db_instance.book_review_db.address
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.book_review_db.db_name
}