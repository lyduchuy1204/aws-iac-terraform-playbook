# Stack APP minh hoạ: tạo 1 S3 bucket bất kỳ để có cái gì đó nằm trong state remote.
# Resource này chỉ để học, không có giá trị production.

resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "demo" {
  bucket = "${var.demo_bucket_prefix}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
