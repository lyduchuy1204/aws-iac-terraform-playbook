# ─── Security Group cho ALB ────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB SG: nhận HTTP từ Internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP từ Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ─── Application Load Balancer ─────────────────────────────────────────────
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  # Bảo vệ ALB khỏi delete nhầm — dev = false, prod = true
  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })
}

# ─── Target Group ──────────────────────────────────────────────────────────
resource "aws_lb_target_group" "this" {
  name     = "${var.name}-tg"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "instance" # ASG sẽ register instance ID

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
  }

  deregistration_delay = 30 # nhanh xoá instance cũ khi ASG scale-in

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# ─── Listener port 80 ──────────────────────────────────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = var.tags
}
