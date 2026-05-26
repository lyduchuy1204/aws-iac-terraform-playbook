# =============================================================================
# Buổi 05 — Data Sources & Dependencies
#
# Mục đích: Query thông tin từ AWS (account ID, region, AMI mới nhất...)
# mà KHÔNG TẠO RESOURCE THẬT — nên buổi này không tốn tiền.
#
# Data source vs Resource:
#   - resource: Terraform sở hữu (create/update/delete).
#   - data:     Terraform CHỈ ĐỌC, không thay đổi gì trên AWS.
# =============================================================================

# -----------------------------------------------------------------------------
# 1) Lấy Account ID hiện tại — đang chạy bằng credentials nào?
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# 2) Lấy thông tin region hiện tại của provider
# -----------------------------------------------------------------------------
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# 3) Lấy danh sách AZ khả dụng trong region — dùng cho VPC ở các buổi sau
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# 4) Lấy AMI Amazon Linux 2023 mới nhất (most_recent = true)
#    - owners = ["amazon"] để chỉ lấy AMI chính chủ AWS
#    - filter "name" theo pattern AL2023 chính thức
#    - filter "architecture" để loại trừ ARM (graviton) nếu cần x86_64
#
#    Đây là cách đúng để "không hardcode AMI ID" — vì AMI ID khác nhau
#    theo region và đổi mỗi khi AWS phát hành bản mới.
# -----------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# -----------------------------------------------------------------------------
# 5) Lấy default VPC trong region (nếu account có)
#    Chỉ để minh hoạ — production thường tự tạo VPC chứ không xài default.
# -----------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}
