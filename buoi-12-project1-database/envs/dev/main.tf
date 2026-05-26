module "database" {
  source = "../../modules/database"

  name                  = "${var.project}-${var.env}"
  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  ec2_security_group_id = var.ec2_security_group_id

  db_name        = "appdb"
  db_username    = "admin"
  instance_class = "db.t3.micro"

  multi_az            = false # dev
  deletion_protection = false # dev
}

# ─── Cho EC2 IAM Role đọc secret này ───────────────────────────────────────
data "aws_iam_policy_document" "read_db_secret" {
  statement {
    sid       = "ReadDBSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [module.database.secret_arn]
  }
}

resource "aws_iam_role_policy" "ec2_read_db_secret" {
  name   = "${var.project}-${var.env}-ec2-read-db-secret"
  role   = var.iam_role_name
  policy = data.aws_iam_policy_document.read_db_secret.json
}
