# ┌────────────────────────────────────────────────────────────────────────┐
# │  Buổi 13 — Hoàn thiện Project 1                                        │
# │  Stack này tạo ALB và "kết nối" các stack network/compute/database     │
# │  bằng cách:                                                            │
# │    1. Tạo ALB ở public subnet (output từ buổi 10).                     │
# │    2. Attach ASG (buổi 11) vào Target Group.                           │
# │    3. Sửa EC2 SG (buổi 11) cho phép inbound 80 từ ALB SG.              │
# │  Database (buổi 12) đã tự kết nối với EC2 SG ở buổi 12.                │
# └────────────────────────────────────────────────────────────────────────┘

# ─── 1) Tạo ALB ────────────────────────────────────────────────────────────
module "alb" {
  source = "../../modules/alb"

  name              = "${var.project}-${var.env}"
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids

  target_port       = 80
  health_check_path = "/"
}

# ─── 2) Attach ASG (buổi 11) vào Target Group ──────────────────────────────
resource "aws_autoscaling_attachment" "asg_to_tg" {
  autoscaling_group_name = var.asg_name
  lb_target_group_arn    = module.alb.target_group_arn
}

# ─── 3) Cho phép ALB SG → EC2 SG (port 80) ────────────────────────────────
# EC2 SG đã có rule placeholder từ VPC CIDR ở buổi 11. Ta thêm rule mới
# cho phép từ ALB SG. (Nếu muốn siết hơn, vào buổi 11 sửa SG bỏ rule cũ.)
resource "aws_security_group_rule" "ec2_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = var.ec2_security_group_id
  source_security_group_id = module.alb.alb_security_group_id
  description              = "HTTP từ ALB SG (buổi 13)"
}
