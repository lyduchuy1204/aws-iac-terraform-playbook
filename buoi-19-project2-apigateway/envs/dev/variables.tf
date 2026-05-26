variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-southeast-1"
}

variable "api_name" {
  description = "Tên REST API."
  type        = string
  default     = "items-api-dev"
}

variable "stage_name" {
  description = "Tên stage."
  type        = string
  default     = "dev"
}

variable "lambda_state_bucket" {
  description = "Tên S3 bucket chứa state buổi 18 (terraform_remote_state)."
  type        = string
}

variable "lambda_state_key" {
  description = "Key state buổi 18 trong S3."
  type        = string
  default     = "buoi-18-project2-lambda-ddb/dev/terraform.tfstate"
}
