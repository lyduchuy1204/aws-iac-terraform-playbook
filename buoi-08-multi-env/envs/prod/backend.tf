# Backend cho ENV PROD
# Thay <YOUR_BUCKET_NAME> bằng output `state_bucket_name` từ buổi 06.
# Lý tưởng: prod state ở 1 bucket KHÁC (hoặc account khác) cho cô lập tốt hơn.
terraform {
  backend "s3" {
    bucket       = "<YOUR_BUCKET_NAME>"
    key          = "envs/prod/terraform.tfstate" # ← KEY RIÊNG cho prod
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
