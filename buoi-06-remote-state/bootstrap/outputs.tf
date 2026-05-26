output "state_bucket_name" {
  description = "Tên bucket lưu Terraform state — copy sang app/backend.tf"
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN của bucket state"
  value       = aws_s3_bucket.state.arn
}

output "region" {
  description = "Region của bucket state"
  value       = var.region
}
