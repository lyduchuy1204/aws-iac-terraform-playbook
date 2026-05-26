# =====================================================================
# OUTPUTS — in giá trị sau apply, hoặc expose ra cho module cha
# =====================================================================

output "bucket_name" {
  description = "Tên bucket vừa tạo (unique global)"
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN của bucket"
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "Region nơi bucket được tạo"
  value       = aws_s3_bucket.demo.region
}

output "common_tags_applied" {
  description = "Tag chung được áp dụng vào bucket (qua locals.common_tags)"
  value       = local.common_tags
}

output "versioning_status" {
  description = "Trạng thái versioning của bucket"
  value       = aws_s3_bucket_versioning.demo.versioning_configuration[0].status
}
