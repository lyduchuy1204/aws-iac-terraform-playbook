variable "name" {
  description = "Prefix tên resource"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (lấy từ module network)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Danh sách private subnet ID để đặt ASG"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR của VPC, để cho phép ALB SG sau này (placeholder)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 3
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}
