variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "project" {
  type    = string
  default = "iac-playbook"
}

variable "env" {
  type    = string
  default = "dev"
}

# ─── Inputs từ các stack trước ──────────────────────────────────────────────
variable "vpc_id" {
  description = "VPC ID từ buổi 10"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs từ buổi 10"
  type        = list(string)
}

variable "asg_name" {
  description = "Tên ASG từ buổi 11 — để gắn Target Group"
  type        = string
}

variable "ec2_security_group_id" {
  description = "EC2 SG ID từ buổi 11 — sẽ thêm rule inbound 80 từ ALB SG"
  type        = string
}
