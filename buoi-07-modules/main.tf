# Suffix random tránh trùng tên bucket
resource "random_id" "suffix" {
  byte_length = 3
}

# ─── Lần gọi #1: bucket lưu LOG, BẬT versioning để giữ lịch sử audit ─────────
module "logs_bucket" {
  source = "./modules/s3-bucket"

  name               = "${var.project}-logs-${random_id.suffix.hex}"
  versioning_enabled = true
  force_destroy      = true # cho phép destroy ở môi trường học
  tags = {
    Purpose = "logs"
  }
}

# ─── Lần gọi #2: bucket lưu ASSET tĩnh, KHÔNG cần versioning ────────────────
module "assets_bucket" {
  source = "./modules/s3-bucket"

  name               = "${var.project}-assets-${random_id.suffix.hex}"
  versioning_enabled = false
  force_destroy      = true
  tags = {
    Purpose = "assets"
  }
}

# ─── Ví dụ dùng module Registry (KHÔNG apply nếu chưa muốn tốn tiền NAT) ────
# Tham khảo thôi: terraform-aws-modules/vpc/aws — module phổ biến nhất AWS Registry.
#
# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "5.5.1" # ← LUÔN pin version cho module Registry
#
#   name = "${var.project}-vpc-demo"
#   cidr = "10.0.0.0/16"
#
#   azs             = ["${var.region}a", "${var.region}b"]
#   public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
#   private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
#
#   enable_nat_gateway     = true
#   single_nat_gateway     = true # tiết kiệm tiền cho dev
#   enable_dns_hostnames   = true
#
#   tags = {
#     Demo = "registry-module"
#   }
# }
