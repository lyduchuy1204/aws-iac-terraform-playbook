# Bootstrap stack: KHÔNG cấu hình backend ở đây.
# State của bootstrap được giữ LOCAL (chicken-and-egg: bucket chưa tồn tại để chứa state).
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

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "iac-playbook"
      Stack     = "bootstrap"
    }
  }
}
