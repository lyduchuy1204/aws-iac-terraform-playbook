output "db_endpoint" {
  description = "Endpoint host:port"
  value       = aws_db_instance.this.endpoint
}

output "db_host" {
  description = "Host (chưa kèm port)"
  value       = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "db_username" {
  value = var.db_username
}

# ⚠️ KHÔNG output password ra string thường — phải sensitive!
output "db_password" {
  description = "Password — KHÔNG in ra console khi apply"
  value       = random_password.db.result
  sensitive   = true
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "secret_arn" {
  description = "ARN của secret chứa credentials — EC2 đọc qua đây"
  value       = aws_secretsmanager_secret.db.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.db.name
}
