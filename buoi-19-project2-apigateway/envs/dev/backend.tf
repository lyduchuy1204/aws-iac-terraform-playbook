# Backend S3 native locking — sửa bucket name cho khớp bootstrap stack ở buổi 06.
terraform {
  backend "s3" {
    bucket       = "REPLACE-ME-tfstate-<account-id>"
    key          = "buoi-19-project2-apigateway/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
