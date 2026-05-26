output "asg_name" {
  description = "Tên ASG"
  value       = aws_autoscaling_group.this.name
}

output "asg_arn" {
  description = "ARN ASG (dùng để attach Target Group ở buổi 13)"
  value       = aws_autoscaling_group.this.arn
}

output "launch_template_id" {
  value = aws_launch_template.this.id
}

output "ec2_security_group_id" {
  description = "SG ID của EC2 — buổi 13 sẽ thêm rule inbound từ ALB SG"
  value       = aws_security_group.ec2.id
}

output "iam_role_name" {
  description = "Tên IAM Role của EC2 — buổi 12 có thể attach thêm policy đọc Secrets Manager"
  value       = aws_iam_role.ec2.name
}

output "iam_role_arn" {
  value = aws_iam_role.ec2.arn
}

output "ami_id" {
  value = data.aws_ami.al2023.id
}
