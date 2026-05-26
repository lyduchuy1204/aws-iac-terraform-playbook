# Backend S3 native locking. Thay <YOUR_BUCKET_NAME> bằng bucket từ buổi 06.
# Trong giai đoạn học có thể dùng backend local — comment block dưới đây.
terraform {
  backend "s3" {
    bucket       = "<YOUR_BUCKET_NAME>"
    key          = "project1/network/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
