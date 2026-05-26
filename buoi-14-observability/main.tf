# =============================================================================
# Buổi 14 — Observability: Log Group + SNS + CloudWatch Metric Alarm
# =============================================================================

# -----------------------------------------------------------------------------
# 1) CloudWatch Log Group
#    - Retention 7 ngày (theo biến) để tiết kiệm chi phí ở môi trường học.
#    - EC2 muốn đẩy log vào group này phải cài CloudWatch Agent + IAM Role
#      có policy "CloudWatchAgentServerPolicy" (làm ở user-data của buổi 11).
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "app" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

  tags = {
    Purpose = "App & EC2 logs"
  }
}

# -----------------------------------------------------------------------------
# 2) SNS Topic — kênh broadcast cảnh báo
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "cpu_alarm" {
  name = var.sns_topic_name

  tags = {
    Purpose = "CloudWatch Alarm notifications"
  }
}

# -----------------------------------------------------------------------------
# 3) Email subscription
#    - SAU khi apply, AWS gửi email "AWS Notification - Subscription Confirmation"
#    - Bạn PHẢI bấm link "Confirm subscription" mới nhận được alert.
# -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.cpu_alarm.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# -----------------------------------------------------------------------------
# 4) CloudWatch Metric Alarm: CPU > 80% trong 5 phút
#    - period = 60s, evaluation_periods = 5  → 5 phút liên tiếp vượt ngưỡng
#    - statistic = Average  → trung bình mỗi chu kỳ
#    - dimensions InstanceId  → ràng vào EC2 cụ thể qua biến
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "buoi-14-ec2-cpu-high-${var.instance_id}"
  alarm_description   = "CPU > ${var.cpu_threshold_percent}% trong 5 phút trên EC2 ${var.instance_id}"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_threshold_percent

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  statistic   = "Average"

  # 5 chu kỳ × 60s = 5 phút
  period             = 60
  evaluation_periods = 5

  # Khi thiếu data, không tự bắn alarm (tránh false positive lúc instance vừa start)
  treat_missing_data = "notBreaching"

  dimensions = {
    InstanceId = var.instance_id
  }

  # Hành động khi vào ALARM / khi về OK
  alarm_actions = [aws_sns_topic.cpu_alarm.arn]
  ok_actions    = [aws_sns_topic.cpu_alarm.arn]

  tags = {
    Purpose = "CPU high watcher"
  }
}
