variable "name" {
  description = "Tên bucket S3 (phải unique toàn cầu, chỉ chữ thường + số + dấu gạch ngang)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Tên bucket phải dài 3–63, chỉ chữ thường/số/dấu gạch ngang, không bắt đầu/kết thúc bằng dấu gạch."
  }
}

variable "versioning_enabled" {
  description = "Bật S3 versioning (giữ lịch sử object) — true cho log/audit, false cho asset thường"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Cho phép terraform destroy xoá bucket kể cả khi còn object. CHỈ bật cho dev/learn."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tag bổ sung gắn lên bucket"
  type        = map(string)
  default     = {}
}
