# Sinh 4 byte (8 ký tự hex) random làm suffix cho bucket name.
# Mỗi lần `terraform destroy` rồi `apply` lại sẽ ra suffix mới.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket đầu tiên do Terraform tạo.
# Tên bucket = prefix cố định + suffix random => unique global.
resource "aws_s3_bucket" "demo" {
  # Ví dụ: tf-playbook-demo-a1b2c3d4
  bucket = "tf-playbook-demo-${random_id.bucket_suffix.hex}"

  # Tag riêng cho bucket này (sẽ merge với default_tags trong provider).
  tags = {
    Name        = "tf-playbook-demo"
    Environment = "learning"
  }
}

# Bật versioning cho bucket — best practice cho mọi bucket.
# (S3 bucket Terraform >= AWS provider 4.x phải khai báo versioning ở resource riêng.)
resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Chặn public access tuyệt đối cho bucket học (an toàn mặc định).
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket                  = aws_s3_bucket.demo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output: in tên và ARN bucket sau khi apply để dễ verify.
output "bucket_name" {
  description = "Tên bucket vừa tạo (unique global)"
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN của bucket"
  value       = aws_s3_bucket.demo.arn
}
