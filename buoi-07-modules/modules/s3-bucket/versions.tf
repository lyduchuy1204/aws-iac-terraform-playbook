# Module CHỈ khai báo required_providers, KHÔNG có provider {} block.
# Provider sẽ được "thừa kế" từ root module gọi nó.
terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
