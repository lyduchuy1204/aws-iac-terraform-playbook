# Cấu hình version cho Terraform core và các provider được dùng.
# Pin version giúp mọi người trong team chạy ra cùng kết quả.
terraform {
  # Yêu cầu Terraform >= 1.11 (cần cho S3 native locking ở các buổi sau).
  required_version = ">= 1.11"

  required_providers {
    # Provider "local" cho phép thao tác với file trên máy local (không cần cloud).
    # ~> 2.5 nghĩa là chấp nhận 2.5.x nhưng không lên 2.6, 3.x.
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
