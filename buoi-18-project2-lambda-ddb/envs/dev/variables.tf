variable "region" {
  description = "AWS region triển khai."
  type        = string
  default     = "ap-southeast-1"
}

variable "table_name" {
  description = "Tên DynamoDB table."
  type        = string
  default     = "items"
}

variable "function_name" {
  description = "Tên Lambda function."
  type        = string
  default     = "items-api-dev"
}
