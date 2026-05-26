# Ví dụ resource có lifecycle protection — copy pattern này cho tài nguyên quan trọng.
# KHÔNG apply file này trực tiếp; dùng làm reference.

terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 1) RDS — vừa prevent_destroy ở Terraform vừa deletion_protection ở AWS.
resource "aws_db_instance" "main" {
  identifier             = "app-prod"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "REPLACE-FROM-SECRETS-MANAGER" # ví dụ; thực tế đọc từ Secrets Manager
  skip_final_snapshot    = false
  final_snapshot_identifier = "app-prod-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  # Tầng 1: AWS chặn delete API call.
  deletion_protection = true

  # Tầng 2: Terraform chặn destroy ngay từ plan.
  # Nếu cần xoá thật: phải xoá block này, commit + apply riêng, rồi mới destroy.
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Env       = "prod"
    Critical  = "true"
    ManagedBy = "Terraform"
  }
}

# 2) ALB — deletion_protection để khỏi xoá nhầm khi refactor module.
resource "aws_lb" "main" {
  name               = "app-prod-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = ["subnet-aaa", "subnet-bbb"]

  enable_deletion_protection = true

  lifecycle {
    prevent_destroy = true
  }
}

# 3) S3 bucket lưu data quan trọng — bật versioning + (production) MFA Delete.
resource "aws_s3_bucket" "data" {
  bucket = "company-prod-critical-data"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
    # MFA Delete chỉ enable được qua AWS CLI/SDK với MFA token thực tế,
    # không phải Terraform. Sau khi enable thủ công, Terraform vẫn quản lý
    # các config khác bình thường.
    # mfa_delete = "Enabled"  # ← thường KHÔNG để Terraform set
  }
}

# 4) DynamoDB table — point_in_time_recovery + deletion_protection (provider 5.x+).
resource "aws_dynamodb_table" "orders" {
  name         = "orders-prod"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  deletion_protection_enabled = true

  lifecycle {
    prevent_destroy = true
  }
}
