# ─── Lấy default VPC nếu user không truyền vpc_id ───────────────────────────
data "aws_vpc" "default" {
  default = true
}

locals {
  effective_vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id
}

# ─── 1) Tạo nhiều IAM user bằng for_each (an toàn khi list thay đổi) ────────
resource "aws_iam_user" "team" {
  for_each = toset(var.iam_user_names) # toset bắt buộc khi for_each nhận list

  name = each.key
  path = "/learners/"

  tags = {
    Name = each.key
    Role = "learner"
  }
}

# ─── 2) Security Group có ingress rules sinh động bằng dynamic block ────────
resource "aws_security_group" "demo" {
  name_prefix = "buoi09-demo-"
  description = "SG demo dynamic ingress block"
  vpc_id      = local.effective_vpc_id

  # Sinh nhiều block "ingress" từ list var.allowed_ports
  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr]
    }
  }

  # Egress: cho phép tất cả ra ngoài
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "buoi09-demo-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
