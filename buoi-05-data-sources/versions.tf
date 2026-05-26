# Pin version Terraform và provider — đảm bảo reproducibility cho team
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

  # Tag mặc định áp lên mọi resource (data source không bị áp tag)
  default_tags {
    tags = {
      Project   = "aws-iac-terraform-playbook"
      Lesson    = "buoi-05-data-sources"
      ManagedBy = "Terraform"
    }
  }
}
