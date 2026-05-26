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

variable "vpc_id" {
  description = "VPC ID từ buổi 10"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs từ buổi 10"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "EC2 SG ID từ buổi 11 — sẽ là source duy nhất truy cập 3306"
  type        = string
}

variable "iam_role_name" {
  description = "Tên IAM Role EC2 từ buổi 11 — để attach policy đọc Secrets Manager"
  type        = string
}
