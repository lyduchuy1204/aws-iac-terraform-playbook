variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  description = "Tên project, dùng làm prefix cho bucket"
  type        = string
  default     = "iac-playbook"
}
