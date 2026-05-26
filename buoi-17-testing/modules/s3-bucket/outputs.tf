# Tên bucket (== input nếu không có random suffix)
output "bucket_name" {
  description = "Tên bucket đã tạo"
  value       = aws_s3_bucket.this.bucket
}

# ARN bucket — dạng arn:aws:s3:::<name>
output "bucket_arn" {
  description = "ARN của bucket"
  value       = aws_s3_bucket.this.arn
}

# ID bucket (== name với S3)
output "bucket_id" {
  description = "ID của bucket"
  value       = aws_s3_bucket.this.id
}
