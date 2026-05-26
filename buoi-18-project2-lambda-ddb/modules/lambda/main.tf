# Module Lambda — đóng gói code Node.js 22, gắn IAM Role least privilege,
# tạo CloudWatch Log Group có retention rõ ràng.

# 1) Zip thư mục src/ thành lambda.zip (kèm node_modules nếu đã npm install).
data "archive_file" "this" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/lambda.zip"
  excludes    = [".gitignore", "package-lock.json"]
}

# 2) IAM Role cho Lambda — trust policy chỉ cho lambda.amazonaws.com assume.
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

# 3) Inline policy least privilege:
#    - Logs: chỉ phạm vi log group của chính function này.
#    - DynamoDB: chỉ table được truyền vào.
data "aws_iam_policy_document" "this" {
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }

  statement {
    sid    = "DynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Scan",
    ]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.function_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}

# 4) Log group tạo trước, Lambda phụ thuộc nó để retention được set ngay.
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# 5) Lambda function.
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.this.arn
  runtime       = var.runtime
  handler       = var.handler
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  environment {
    variables = var.environment_variables
  }

  # Đảm bảo log group đã tồn tại trước khi Lambda chạy lần đầu.
  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy.this,
  ]

  tags = var.tags
}
