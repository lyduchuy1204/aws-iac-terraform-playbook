variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "iam_user_names" {
  description = "Danh sách tên IAM user cần tạo"
  type        = list(string)
  default     = ["alice", "bob", "carol"]
}

variable "allowed_ports" {
  description = "Danh sách các port cần mở inbound trên Security Group demo"
  type = list(object({
    port        = number
    protocol    = string
    cidr        = string
    description = string
  }))
  default = [
    {
      port        = 80
      protocol    = "tcp"
      cidr        = "0.0.0.0/0"
      description = "HTTP công khai"
    },
    {
      port        = 443
      protocol    = "tcp"
      cidr        = "0.0.0.0/0"
      description = "HTTPS công khai"
    },
    {
      port        = 22
      protocol    = "tcp"
      cidr        = "10.0.0.0/16"
      description = "SSH chỉ trong VPC"
    },
  ]
}

variable "vpc_id" {
  description = "VPC ID để gắn Security Group. Để trống sẽ dùng default VPC của account."
  type        = string
  default     = ""
}
