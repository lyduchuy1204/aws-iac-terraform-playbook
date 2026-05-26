output "table_name" {
  description = "Tên DynamoDB table."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN DynamoDB table — dùng cho IAM policy least privilege."
  value       = aws_dynamodb_table.this.arn
}
