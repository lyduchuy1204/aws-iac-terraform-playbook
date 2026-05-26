# Pin version Terraform và provider — buổi 03 đã giải thích lý do reproducibility
terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "aws-iac-terraform-playbook"
      Lesson    = "buoi-14-observability"
      ManagedBy = "Terraform"
    }
  }
}
