output "vpc_id" {
  description = "ID của VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR của VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Danh sách ID public subnet (theo thứ tự AZ)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Danh sách ID private subnet (theo thứ tự AZ)"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID của Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "ID các NAT Gateway"
  value       = aws_nat_gateway.this[*].id
}

output "azs" {
  description = "Availability Zones đang dùng"
  value       = var.azs
}
