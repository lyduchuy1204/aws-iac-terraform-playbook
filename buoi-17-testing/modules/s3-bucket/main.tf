# =============================================================================
# Module s3-bucket — bản tối giản dùng để minh hoạ `terraform test`
# (Tương đương module ở buổi 07, có thể copy về dùng lại.)
# =============================================================================

# Bucket chính
resource "aws_s3_bucket" "this" {
  bucket = var.name
  tags   = var.tags
}

# Versioning (bật/tắt theo biến)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# Mặc định bật server-side encryption AES256 — best practice cho mọi bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Chặn public access mặc định — best practice
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
