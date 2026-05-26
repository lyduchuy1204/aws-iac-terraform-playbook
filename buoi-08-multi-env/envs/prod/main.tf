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

# Bucket app cho prod — BẬT versioning để có audit & rollback object
module "app_bucket" {
  source = "../../modules/s3-bucket"

  name               = "${var.project}-app-prod-${var.bucket_suffix}"
  versioning_enabled = true  # prod: BẮT BUỘC versioning
  force_destroy      = false # prod: tuyệt đối KHÔNG force_destroy
}

output "bucket_arn" {
  value = module.app_bucket.bucket_arn
}
