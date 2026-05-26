# Output để debug và liên kết với buổi sau
output "log_group_name" {
  description = "Tên CloudWatch Log Group đã tạo"
  value       = aws_cloudwatch_log_group.app.name
}

output "log_group_arn" {
  description = "ARN của Log Group"
  value       = aws_cloudwatch_log_group.app.arn
}

output "sns_topic_arn" {
  description = "ARN của SNS topic — dùng để gắn thêm subscriber khác"
  value       = aws_sns_topic.cpu_alarm.arn
}

output "alarm_name" {
  description = "Tên CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.ec2_cpu_high.alarm_name
}
