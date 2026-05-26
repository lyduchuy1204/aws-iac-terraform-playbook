# Backend cho ENV DEV
# Thay <YOUR_BUCKET_NAME> bằng output `state_bucket_name` từ buổi 06.
terraform {
  backend "s3" {
    bucket       = "<YOUR_BUCKET_NAME>"
    key          = "envs/dev/terraform.tfstate" # ← KEY RIÊNG cho dev
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
