variable "name" {
  description = "Tên bucket S3 (unique toàn cầu)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Tên bucket không hợp lệ."
  }
}

variable "versioning_enabled" {
  description = "Bật S3 versioning"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Cho phép destroy khi còn object"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tag bổ sung"
  type        = map(string)
  default     = {}
}
