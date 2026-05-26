# Input của module dynamodb.

variable "table_name" {
  description = "Tên DynamoDB table (ví dụ: items)."
  type        = string
}

variable "hash_key" {
  description = "Thuộc tính làm partition key. Mặc định 'id' (string)."
  type        = string
  default     = "id"
}

variable "tags" {
  description = "Tags chung gắn vào table."
  type        = map(string)
  default     = {}
}
