variable "name" {
  description = "Prefix tên resource"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs để đặt ALB (≥ 2 AZ)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "ALB cần ít nhất 2 public subnet ở 2 AZ."
  }
}

variable "target_port" {
  description = "Port mà EC2 lắng nghe"
  type        = number
  default     = 80
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "tags" {
  type    = map(string)
  default = {}
}
