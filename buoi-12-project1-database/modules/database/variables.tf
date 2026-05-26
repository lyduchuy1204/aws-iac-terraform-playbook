variable "name" {
  description = "Prefix tên resource"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Tối thiểu 2 private subnet ở 2 AZ khác nhau"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "DB Subnet Group cần ít nhất 2 subnet ở 2 AZ khác nhau."
  }
}

variable "ec2_security_group_id" {
  description = "Security Group ID của EC2 — sẽ là source duy nhất được phép vào port 3306"
  type        = string
}

variable "db_name" {
  description = "Tên database mặc định"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "admin"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage GB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Multi-AZ. Dev = false, prod = true"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Bảo vệ khỏi delete nhầm. Dev = false, prod = true"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
