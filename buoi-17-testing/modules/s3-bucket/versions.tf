# Module yêu cầu Terraform >= 1.6 (terraform test GA) — khuyến nghị >= 1.11
terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
