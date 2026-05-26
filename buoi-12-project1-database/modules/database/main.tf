# ─── Sinh password ngẫu nhiên ──────────────────────────────────────────────
# RDS không nhận một số ký tự đặc biệt: /, @, ", space → loại bỏ chúng.
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ─── DB Subnet Group ───────────────────────────────────────────────────────
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnet-group"
  })
}

# ─── DB Parameter Group MySQL 8.0 ──────────────────────────────────────────
resource "aws_db_parameter_group" "this" {
  name        = "${var.name}-mysql80"
  family      = "mysql8.0"
  description = "Custom parameter group for ${var.name} (MySQL 8.0)"

  # Ví dụ tinh chỉnh — nới lỏng để demo, prod cần điều chỉnh theo workload
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = var.tags
}

# ─── Security Group cho RDS ────────────────────────────────────────────────
resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "RDS MySQL — chỉ EC2 SG được vào 3306"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (RDS hiếm khi cần, nhưng để mặc định)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-db-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Tách rule ra resource riêng để tránh cycle khi reference EC2 SG
resource "aws_security_group_rule" "db_from_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = var.ec2_security_group_id
  description              = "MySQL từ EC2 SG"
}

# ─── RDS Instance ──────────────────────────────────────────────────────────
resource "aws_db_instance" "this" {
  identifier = "${var.name}-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2 # cho phép auto-scale storage

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false # RDS PHẢI private
  multi_az            = var.multi_az
  storage_encrypted   = true # encrypt at rest — bắt buộc

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  deletion_protection      = var.deletion_protection
  skip_final_snapshot      = true # dev: cho destroy nhanh, prod nên = false
  delete_automated_backups = true

  apply_immediately = true

  tags = merge(var.tags, {
    Name = "${var.name}-mysql"
  })

  lifecycle {
    # Dev: false để destroy nhanh.
    # PROD: chuyển thành true để tránh xoá nhầm DB.
    prevent_destroy = false

    ignore_changes = [
      password, # password đã ở Secrets Manager, không cho Terraform replace ngầm
    ]
  }
}

# ─── Secrets Manager — lưu user/password/host/port/dbname dạng JSON ────────
resource "aws_secretsmanager_secret" "db" {
  name        = "${var.name}/db/credentials"
  description = "Credentials cho RDS ${aws_db_instance.this.identifier}"

  # Dev: 0 = xoá ngay khi destroy. Prod: 7-30 ngày recovery window.
  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}
