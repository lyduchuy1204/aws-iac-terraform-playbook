variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "project" {
  type    = string
  default = "iac-playbook"
}

variable "bucket_suffix" {
  description = "Suffix unique cho tên bucket"
  type        = string
}

# Bucket app cho dev — KHÔNG bật versioning để tiết kiệm
module "app_bucket" {
  source = "../../modules/s3-bucket"

  name               = "${var.project}-app-dev-${var.bucket_suffix}"
  versioning_enabled = false # dev: không cần audit log
  force_destroy      = true  # dev: cho phép destroy khi còn object
}

output "bucket_arn" {
  value = module.app_bucket.bucket_arn
}
