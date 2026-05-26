output "demo_bucket_name" {
  description = "Tên bucket demo trong stack app"
  value       = aws_s3_bucket.demo.id
}
