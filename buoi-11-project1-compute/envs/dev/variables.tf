variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "project" {
  type    = string
  default = "iac-playbook"
}

variable "env" {
  type    = string
  default = "dev"
}

# ─── Input từ output buổi 10 (network) ──────────────────────────────────────
# Bạn có 2 cách:
#   1. Truyền tay qua tfvars (đơn giản nhất, dùng cho học).
#   2. Đọc qua remote state buổi 10 (xem comment trong main.tf).
variable "vpc_id" {
  description = "VPC ID lấy từ output buổi 10"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR VPC, mặc định 10.0.0.0/16"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_ids" {
  description = "Danh sách private subnet ID lấy từ output buổi 10"
  type        = list(string)
}
