variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "demo_bucket_prefix" {
  description = "Prefix tên bucket demo (sẽ thêm random suffix)"
  type        = string
  default     = "iac-playbook-demo"
}
