output "function_name" {
  description = "Tên Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN Lambda function — dùng cho API Gateway integration ở buổi 19."
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN — dùng cho aws_api_gateway_integration."
  value       = aws_lambda_function.this.invoke_arn
}

output "role_arn" {
  description = "ARN IAM Role gắn vào Lambda."
  value       = aws_iam_role.this.arn
}

output "log_group_name" {
  description = "Tên CloudWatch Log Group của Lambda."
  value       = aws_cloudwatch_log_group.this.name
}
