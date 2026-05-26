# Input của module lambda.

variable "function_name" {
  description = "Tên Lambda function."
  type        = string
}

variable "source_dir" {
  description = "Đường dẫn tuyệt đối hoặc tương đối tới folder src/ chứa handler.js (+ node_modules)."
  type        = string
}

variable "handler" {
  description = "Handler entry point dạng <file>.<exported_function>."
  type        = string
  default     = "handler.handler"
}

variable "runtime" {
  description = "Lambda runtime. Khoá học bắt buộc nodejs22.x (Node 18 EOL 31/03/2026)."
  type        = string
  default     = "nodejs22.x"

  validation {
    condition     = var.runtime == "nodejs22.x"
    error_message = "Playbook yêu cầu runtime nodejs22.x. Không dùng nodejs18.x hay nodejs20.x."
  }
}

variable "timeout" {
  description = "Timeout (giây) cho mỗi invocation."
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Bộ nhớ Lambda (MB). 128 đủ cho mức học."
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Map env var truyền vào Lambda (ví dụ TABLE_NAME)."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Số ngày giữ CloudWatch Logs."
  type        = number
  default     = 7
}

variable "dynamodb_table_arn" {
  description = "ARN của DynamoDB table mà Lambda được phép truy cập (least privilege)."
  type        = string
}

variable "tags" {
  description = "Tags chung."
  type        = map(string)
  default     = {}
}
