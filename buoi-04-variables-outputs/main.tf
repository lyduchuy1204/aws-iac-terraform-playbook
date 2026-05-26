# =====================================================================
# LOCALS — biến tạm tính 1 lần, dùng nhiều nơi
# =====================================================================
locals {
  # Tag chung gắn vào mọi resource.
  # merge(map_a, map_b) — key trùng thì map_b thắng.
  common_tags = merge(
    {
      Environment = var.environment
      Owner       = var.owner
    },
    var.extra_tags
  )

  # Tên bucket cuối cùng (prefix + suffix random).
  bucket_name = "${var.bucket_name_prefix}-${random_id.bucket_suffix.hex}"
}

# =====================================================================
# RESOURCES
# =====================================================================

# Suffix random để bucket name unique global.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket — refactor từ buổi 03 dùng variable.
resource "aws_s3_bucket" "demo" {
  bucket = local.bucket_name

  tags = merge(
    local.common_tags,
    {
      Name = local.bucket_name
    }
  )
}

# Versioning có thể bật/tắt qua variable.
resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Block public access — luôn bật cho bucket học.
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket                  = aws_s3_bucket.demo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
