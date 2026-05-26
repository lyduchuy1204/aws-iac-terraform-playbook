# Input của module apigateway.

variable "api_name" {
  description = "Tên REST API trên API Gateway."
  type        = string
}

variable "stage_name" {
  description = "Tên stage public (ví dụ: dev, prod)."
  type        = string
  default     = "dev"
}

variable "lambda_function_name" {
  description = "Tên Lambda function — cần để gắn aws_lambda_permission."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN Lambda (output `invoke_arn` của aws_lambda_function)."
  type        = string
}

variable "resource_path_part" {
  description = "Path segment cho resource (ví dụ: items)."
  type        = string
  default     = "items"
}

variable "tags" {
  description = "Tags chung."
  type        = map(string)
  default     = {}
}
