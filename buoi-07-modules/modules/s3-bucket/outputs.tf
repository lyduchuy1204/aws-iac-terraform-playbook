output "bucket_id" {
  description = "ID (= tên) của bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN của bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Domain name của bucket (dùng khi cần endpoint S3 trực tiếp)"
  value       = aws_s3_bucket.this.bucket_domain_name
}
