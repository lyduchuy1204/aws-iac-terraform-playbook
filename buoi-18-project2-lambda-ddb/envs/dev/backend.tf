# Backend S3 với native locking (use_lockfile, từ Terraform 1.10+).
# Sửa bucket name cho khớp bootstrap stack ở buổi 06.
terraform {
  backend "s3" {
    bucket       = "REPLACE-ME-tfstate-<account-id>"
    key          = "buoi-18-project2-lambda-ddb/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
