# Region AWS triển khai — mặc định Singapore vì gần VN
variable "region" {
  description = "AWS region để tạo Log Group, Alarm, SNS"
  type        = string
  default     = "ap-southeast-1"
}

# Email nhận cảnh báo từ SNS — phải confirm subscription qua mail
variable "notification_email" {
  description = "Email nhận cảnh báo CloudWatch Alarm qua SNS"
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.notification_email))
    error_message = "notification_email phải là email hợp lệ (vd: you@example.com)."
  }
}

# Instance ID EC2 cần gắn alarm — lấy từ buổi 11 hoặc instance bất kỳ đang chạy
variable "instance_id" {
  description = "ID EC2 instance để monitor CPU (vd: i-0abcd1234ef567890)"
  type        = string

  validation {
    condition     = can(regex("^i-[0-9a-f]{8,17}$", var.instance_id))
    error_message = "instance_id phải có dạng i-xxxxxxxx (8–17 ký tự hex sau prefix)."
  }
}

# Tên Log Group — dùng cho EC2/app log
variable "log_group_name" {
  description = "Tên CloudWatch Log Group"
  type        = string
  default     = "/aws/ec2/buoi-14-app"
}

# Số ngày giữ log — nhỏ để tiết kiệm tiền ở môi trường học
variable "log_retention_days" {
  description = "Số ngày retention cho Log Group"
  type        = number
  default     = 7
}

# Tên SNS topic
variable "sns_topic_name" {
  description = "Tên SNS topic nhận cảnh báo"
  type        = string
  default     = "buoi-14-cpu-alarm-topic"
}

# Ngưỡng CPU để bắn alarm (đơn vị %)
variable "cpu_threshold_percent" {
  description = "Ngưỡng CPU % để bắn alarm"
  type        = number
  default     = 80
}
