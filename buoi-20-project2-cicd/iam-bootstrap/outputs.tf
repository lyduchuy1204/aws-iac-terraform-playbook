output "oidc_provider_arn" {
  description = "ARN OIDC provider GitHub trong IAM."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "role_arn" {
  description = "ARN IAM Role để gán vào GitHub variable AWS_ROLE_TO_ASSUME."
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Tên IAM Role."
  value       = aws_iam_role.github_actions.name
}
