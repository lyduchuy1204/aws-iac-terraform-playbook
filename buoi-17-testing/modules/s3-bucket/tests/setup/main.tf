# Helper module nhỏ cho test apply.tftest.hcl
# Sinh chuỗi random hex 8 ký tự dùng làm suffix bucket name (đảm bảo unique)

terraform {
  required_version = ">= 1.11"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "suffix" {
  value = random_id.suffix.hex
}
