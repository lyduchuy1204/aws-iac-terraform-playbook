# Stack bootstrap: tạo OIDC provider GitHub + IAM Role để GitHub Actions assume.
# Chạy 1 lần duy nhất. State có thể giữ local hoặc backend S3 tuỳ ý.

# 1) OIDC provider GitHub.
#    - URL chuẩn: https://token.actions.githubusercontent.com
#    - audience: sts.amazonaws.com (mặc định cho aws-actions/configure-aws-credentials).
#    - thumbprint: từ 2023+, AWS xác thực OIDC qua thư viện cert; thumbprint vẫn là field
#      bắt buộc nhưng không còn được kiểm tra. Truyền giá trị chính thức để tương thích.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 2) Trust policy: chỉ workflow của repo cụ thể được phép assume role.
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Bắt buộc audience đúng (chống token reuse từ service khác).
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Giới hạn theo subject — pattern repo:owner/repo:* cho phép mọi
    # branch/tag/PR/environment của repo.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  description        = "Role cho GitHub Actions của repo ${var.github_repo} qua OIDC."
  assume_role_policy = data.aws_iam_policy_document.trust.json

  # Tối đa 1 giờ (giới hạn của AssumeRoleWithWebIdentity với OIDC).
  max_session_duration = 3600
}

# 3) Policy attach — least privilege placeholder.
#    PRODUCTION: thay bằng policy chỉ cho phép action/resource thực sự cần.
#    Mức học có thể tạm dùng PowerUser hoặc 1 inline policy cụ thể.
data "aws_iam_policy_document" "deploy" {
  # Cho phép quản lý các resource Project 2 (Lambda, DynamoDB, API Gateway, IAM Role, Logs).
  # ĐÂY LÀ PLACEHOLDER — bạn nên thu hẹp scope khi production.
  statement {
    sid    = "Project2Deploy"
    effect = "Allow"
    actions = [
      "lambda:*",
      "dynamodb:*",
      "apigateway:*",
      "logs:*",
      "iam:GetRole",
      "iam:PassRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:TagRole",
      "iam:UntagRole",
    ]
    resources = ["*"]
  }

  # Cho phép đọc/ghi state trong S3 backend (không cho xoá bucket).
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.deploy.json
}
