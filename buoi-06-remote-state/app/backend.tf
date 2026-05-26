# ┌─────────────────────────────────────────────────────────────────────┐
# │  Backend S3 với native locking (chuẩn 2025+, KHÔNG dùng DynamoDB)   │
# └─────────────────────────────────────────────────────────────────────┘
#
# Hướng dẫn dùng:
# 1. Lần đầu: GIỮ NGUYÊN block bị comment bên dưới, chạy `terraform apply` ở app/
#    để tạo demo bucket với state local.
# 2. Sau đó: BỎ COMMENT block dưới đây, thay <YOUR_BUCKET_NAME> bằng output
#    `state_bucket_name` từ stack bootstrap.
# 3. Chạy `terraform init -migrate-state` để chuyển state local lên S3.
#
# terraform {
#   backend "s3" {
#     bucket       = "<YOUR_BUCKET_NAME>"        # ví dụ: tfstate-123456789012-a1b2c3
#     key          = "envs/demo/terraform.tfstate"
#     region       = "ap-southeast-1"
#     encrypt      = true
#     use_lockfile = true   # ← S3 native lock (Terraform >= 1.10), thay cho dynamodb_table
#   }
# }
