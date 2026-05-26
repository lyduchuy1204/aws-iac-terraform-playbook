output "rest_api_id" {
  description = "ID REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "execution_arn" {
  description = "Execution ARN — dùng cho lambda permission source_arn."
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "invoke_url" {
  description = "Invoke URL của stage (https://<id>.execute-api.<region>.amazonaws.com/<stage>)."
  value       = aws_api_gateway_stage.this.invoke_url
}

output "stage_name" {
  description = "Tên stage."
  value       = aws_api_gateway_stage.this.stage_name
}
