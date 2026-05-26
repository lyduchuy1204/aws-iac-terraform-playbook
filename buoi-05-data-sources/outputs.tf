# =============================================================================
# Outputs — in kết quả các data source ra console sau khi apply
# =============================================================================

# 1) Account ID đang dùng — hữu ích để xác định môi trường (dev/prod khác account)
output "account_id" {
  description = "AWS Account ID hiện tại"
  value       = data.aws_caller_identity.current.account_id
}

# ARN của identity đang gọi (user/role)
output "caller_arn" {
  description = "ARN của caller (user hoặc role)"
  value       = data.aws_caller_identity.current.arn
}

# 2) Region hiện tại
output "current_region" {
  description = "Region đang dùng"
  value       = data.aws_region.current.name
}

# 3) Danh sách AZ khả dụng — dùng cho buổi 10 (VPC)
output "available_azs" {
  description = "Danh sách Availability Zone khả dụng trong region"
  value       = data.aws_availability_zones.available.names
}

# 4) AMI ID Amazon Linux 2023 mới nhất — sẽ dùng ở buổi 11 (EC2 Launch Template)
output "amazon_linux_2023_ami_id" {
  description = "AMI ID của Amazon Linux 2023 mới nhất trong region"
  value       = data.aws_ami.amazon_linux_2023.id
}

# Tên image — để debug, ví dụ: al2023-ami-2023.4.20240611.0-kernel-6.1-x86_64
output "amazon_linux_2023_ami_name" {
  description = "Tên AMI Amazon Linux 2023 (có timestamp)"
  value       = data.aws_ami.amazon_linux_2023.name
}

# 5) Default VPC ID (nếu có)
output "default_vpc_id" {
  description = "ID của default VPC trong region"
  value       = data.aws_vpc.default.id
}

output "default_vpc_cidr" {
  description = "CIDR block của default VPC"
  value       = data.aws_vpc.default.cidr_block
}
