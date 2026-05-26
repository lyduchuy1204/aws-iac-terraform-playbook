# DynamoDB table on-demand cho Project 2.
# - billing PAY_PER_REQUEST: không cần provisioned capacity, hợp với workload học/dev.
# - point_in_time_recovery bật để demo recovery (có thể tắt để tiết kiệm).
resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key

  attribute {
    name = var.hash_key
    type = "S" # String
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = var.tags
}
