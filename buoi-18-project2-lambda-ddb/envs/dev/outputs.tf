output "lambda_function_name" {
  description = "Tên Lambda — dùng để invoke ở step test."
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN Lambda — buổi 19 sẽ tham chiếu để gắn API Gateway."
  value       = module.lambda.function_arn
}

output "lambda_invoke_arn" {
  description = "Invoke ARN — buổi 19 dùng cho aws_api_gateway_integration."
  value       = module.lambda.invoke_arn
}

output "dynamodb_table_name" {
  description = "Tên DynamoDB table."
  value       = module.dynamodb.table_name
}
