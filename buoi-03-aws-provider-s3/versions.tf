# Cấu hình version cho Terraform core và các provider được dùng.
terraform {
  # Cần Terraform >= 1.11 (đồng bộ với cả khoá học, để dùng được S3 native locking ở buổi 06).
  required_version = ">= 1.11"

  required_providers {
    # Provider AWS chính thức của HashiCorp.
    # ~> 5.0 = pessimistic: chấp nhận 5.x nhưng KHÔNG nhảy lên 6.x (có thể breaking).
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Provider random để sinh suffix cho S3 bucket name (cần unique global).
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Cấu hình provider AWS: chỉ cần khai báo region.
# Credential được đọc tự động từ:
#   1) Env: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
#   2) ~/.aws/credentials (đã chạy `aws configure`)
#   3) IAM Role (nếu chạy trên EC2/ECS)
provider "aws" {
  region = "ap-southeast-1" # Singapore — gần Việt Nam nhất

  # Default tag áp cho mọi resource AWS Terraform tạo (best practice).
  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "aws-iac-terraform-playbook"
    }
  }
}
