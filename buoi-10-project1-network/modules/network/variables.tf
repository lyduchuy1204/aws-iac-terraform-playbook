variable "name" {
  description = "Tên prefix cho các resource (ví dụ: iac-playbook-dev)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block của VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Danh sách Availability Zone (đúng 2 cái)"
  type        = list(string)

  validation {
    condition     = length(var.azs) == 2
    error_message = "Module này thiết kế cho 2 AZ."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR cho 2 public subnet, theo thứ tự với azs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR cho 2 private subnet, theo thứ tự với azs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "single_nat_gateway" {
  description = "Chỉ tạo 1 NAT Gateway (cost-saving cho dev). Production nên tắt."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tag bổ sung gắn lên resource"
  type        = map(string)
  default     = {}
}
