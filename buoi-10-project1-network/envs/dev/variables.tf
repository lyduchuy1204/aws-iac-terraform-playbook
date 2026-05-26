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

variable "azs" {
  description = "2 Availability Zone trong region"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}
