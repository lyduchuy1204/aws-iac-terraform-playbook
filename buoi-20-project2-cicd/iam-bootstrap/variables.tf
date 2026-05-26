variable "region" {
  description = "AWS region triển khai (chỉ ảnh hưởng provider — IAM là global)."
  type        = string
  default     = "ap-southeast-1"
}

variable "github_repo" {
  description = "Repo GitHub được phép assume role, dạng \"owner/repo\" (KHÔNG kèm https://)."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repo))
    error_message = "github_repo phải có dạng \"owner/repo\", ví dụ \"my-org/aws-iac-terraform-playbook\"."
  }
}

variable "role_name" {
  description = "Tên IAM Role cho GitHub Actions."
  type        = string
  default     = "github-actions-deployer"
}
