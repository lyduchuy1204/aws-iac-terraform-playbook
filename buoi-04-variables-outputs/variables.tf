# =====================================================================
# INPUT VARIABLES
# Mỗi variable nên có: type, description, và (nếu hợp lý) validation.
# =====================================================================

variable "aws_region" {
  description = "AWS region nơi tạo resource. Mặc định ap-southeast-1 (Singapore)."
  type        = string
  default     = "ap-southeast-1"

  validation {
    # Chỉ cho phép vài region phổ biến cho mục đích học, tránh tạo nhầm region đắt tiền.
    condition     = contains(["ap-southeast-1", "ap-southeast-2", "us-east-1", "us-west-2"], var.aws_region)
    error_message = "Region phải là một trong: ap-southeast-1, ap-southeast-2, us-east-1, us-west-2."
  }
}

variable "bucket_name_prefix" {
  description = "Prefix cho tên S3 bucket. Bucket name sẽ là '<prefix>-<random_hex>'."
  type        = string

  validation {
    # S3 bucket name: 3-63 ký tự, chữ thường, số, dấu chấm, dấu gạch ngang.
    # Ở đây giới hạn prefix 3-40 để chừa chỗ cho suffix random.
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,39}$", var.bucket_name_prefix))
    error_message = "Prefix phải 3-40 ký tự, chỉ chữ thường + số + dấu '-', bắt đầu bằng chữ/số."
  }
}

variable "environment" {
  description = "Môi trường triển khai (dev/staging/prod/learning)."
  type        = string
  default     = "learning"

  validation {
    condition     = contains(["dev", "staging", "prod", "learning"], var.environment)
    error_message = "Environment phải là một trong: dev, staging, prod, learning."
  }
}

variable "owner" {
  description = "Người sở hữu resource (dùng cho tag, cost allocation)."
  type        = string
  default     = "unknown"
}

variable "extra_tags" {
  description = "Tag bổ sung gắn vào bucket (map[string]string)."
  type        = map(string)
  default     = {}
}

variable "enable_versioning" {
  description = "Bật S3 versioning cho bucket. Khuyến nghị true."
  type        = bool
  default     = true
}
