# Tên bucket — phải tuân quy tắc S3 (3–63 ký tự, lowercase, không bắt đầu bằng "xn--")
variable "name" {
  description = "Tên S3 bucket (unique toàn cầu)"
  type        = string

  validation {
    # Quy tắc đơn giản: 3–63 ký tự, lowercase, số, dấu gạch ngang
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Tên bucket phải 3–63 ký tự lowercase/số/dấu gạch ngang, không bắt đầu/kết thúc bằng dấu gạch ngang."
  }
}

# Bật versioning hay không — production khuyên bật
variable "versioning_enabled" {
  description = "Bật S3 versioning"
  type        = bool
  default     = true
}

# Tag áp lên bucket
variable "tags" {
  description = "Tag áp lên bucket"
  type        = map(string)
  default     = {}
}
