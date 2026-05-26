terraform {
  backend "s3" {
    bucket       = "<YOUR_BUCKET_NAME>"
    key          = "project1/alb/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
