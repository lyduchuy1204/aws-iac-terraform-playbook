# Pin version Terraform core và provider — giống buổi 03.
terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Provider AWS đọc region từ variable (KHÔNG hard-code như buổi 03).
provider "aws" {
  region = var.aws_region

  # default_tags chỉ chứa tag CỐ ĐỊNH cho mọi resource.
  # Tag biến đổi theo env (Environment, Owner) đặt trong locals.common_tags
  # rồi gắn vào từng resource (vì default_tags không hỗ trợ reference variable
  # ở mọi version 5.x — pattern an toàn là dùng locals).
  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "aws-iac-terraform-playbook"
    }
  }
}
