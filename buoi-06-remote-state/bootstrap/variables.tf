variable "region" {
  description = "AWS region để tạo bucket state"
  type        = string
  default     = "ap-southeast-1"
}

variable "bucket_name_prefix" {
  description = "Prefix tên bucket, sẽ thêm account-id + random suffix để đảm bảo unique"
  type        = string
  default     = "tfstate"
}
