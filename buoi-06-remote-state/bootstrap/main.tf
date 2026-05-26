# Lấy account-id để gắn vào tên bucket cho unique
data "aws_caller_identity" "current" {}

# Random suffix tránh va chạm tên (S3 bucket name unique toàn cầu)
resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  bucket_name = "${var.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}-${random_id.suffix.hex}"
}

# ─── S3 bucket lưu state ───────────────────────────────────────────────
resource "aws_s3_bucket" "state" {
  bucket = local.bucket_name

  # Bảo vệ KHÔNG cho destroy nhầm bucket state.
  # Khi học xong muốn destroy thật, hãy comment dòng này lại.
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Versioning: rollback được state khi apply lỗi
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Mã hoá at-rest bằng SSE-S3 (AES256). Đơn giản, không cần KMS key riêng cho học tập.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Chặn TẤT CẢ public access
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bắt buộc dùng object ownership "BucketOwnerEnforced" — không xài ACL nữa
resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
