output "iam_user_arns" {
  description = "Map tên user → ARN"
  value       = { for k, u in aws_iam_user.team : k => u.arn }
}

output "iam_user_names" {
  description = "Danh sách tên user đã tạo"
  value       = sort([for u in aws_iam_user.team : u.name])
}

output "security_group_id" {
  description = "ID của Security Group demo"
  value       = aws_security_group.demo.id
}
