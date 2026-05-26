output "bucket_arns" {
  description = "ARN của các bucket được module tạo ra"
  value = {
    logs   = module.logs_bucket.bucket_arn
    assets = module.assets_bucket.bucket_arn
  }
}

output "bucket_names" {
  description = "Tên các bucket"
  value = {
    logs   = module.logs_bucket.bucket_id
    assets = module.assets_bucket.bucket_id
  }
}
