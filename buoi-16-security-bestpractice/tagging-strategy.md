# 🏷️ Tagging Strategy

> Tag là thứ rẻ nhất nhưng đem lại lợi ích lớn nhất: **cost allocation, ownership, automation, security audit**. Quy ước này áp dụng cho mọi resource AWS có thể tag.

---

## 🎯 Tag bắt buộc (5 tag chuẩn)

| Tag | Bắt buộc | Mô tả | Ví dụ giá trị |
|---|---|---|---|
| `Owner` | ✅ | Team/cá nhân chịu trách nhiệm vận hành | `team-platform`, `alice@company.com` |
| `Environment` | ✅ | Môi trường chạy | `dev`, `staging`, `prod` |
| `Project` | ✅ | Dự án/sản phẩm dùng resource | `payment-gateway`, `data-platform` |
| `ManagedBy` | ✅ | Công cụ tạo ra resource | `Terraform`, `Console`, `CDK` |
| `CostCenter` | ✅ | Mã trung tâm chi phí cho billing | `CC-1001`, `engineering`, `marketing` |

## 📦 Tag tùy chọn (theo nhu cầu)

| Tag | Mô tả | Ví dụ |
|---|---|---|
| `Component` | Layer trong project | `network`, `compute`, `database` |
| `DataClassification` | Mức nhạy cảm dữ liệu | `public`, `internal`, `confidential`, `pii` |
| `Backup` | Cờ bật/tắt backup automation | `daily`, `none` |
| `AutoStop` | Lịch tự stop EC2 ngoài giờ | `weekend`, `nights` |
| `TicketURL` | Link Jira/issue tạo ra resource | `https://jira.company.com/browse/INFRA-123` |
| `Repository` | Repo Terraform quản lý resource | `github.com/company/aws-infra` |

---

## 🛠️ Triển khai trong Terraform

### Cách 1 — `default_tags` trong provider (KHUYẾN NGHỊ)

Áp tag mặc định cho mọi resource hỗ trợ:

```hcl
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Owner       = var.owner
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
    }
  }
}
```

> ⚠️ Một số resource (vd: `aws_autoscaling_group`) **không tự kế thừa** `default_tags` cho instance launched. Phải set thủ công qua `tag` block với `propagate_at_launch = true`.

### Cách 2 — `locals` + `merge`

Khi cần thêm tag riêng cho 1 resource:

```hcl
locals {
  common_tags = {
    Owner       = var.owner
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-logs-bucket"

  tags = merge(local.common_tags, {
    Component          = "logging"
    DataClassification = "internal"
  })
}
```

---

## ✅ Validate bằng tflint

Rule `aws_resource_missing_tags` trong `.tflint.hcl` sẽ chặn merge nếu thiếu tag bắt buộc:

```hcl
rule "aws_resource_missing_tags" {
  enabled = true
  tags = ["Owner", "Environment", "Project", "ManagedBy", "CostCenter"]
}
```

---

## 💰 Lợi ích billing

1. AWS Billing → **Cost Allocation Tags** → bật các tag bắt buộc.
2. Sau 24h, Cost Explorer cho phép filter chi phí theo tag.
3. Group theo `Project` để biết dự án nào tốn nhất.
4. Group theo `Environment` để so sánh dev/prod.

---

## 🔒 Lợi ích security & automation

- IAM policy có thể dùng `aws:ResourceTag/Environment` để giới hạn quyền theo env.
- Lambda/EventBridge có thể quét resource thiếu tag → cảnh báo Slack.
- Backup plan (AWS Backup) chọn resource theo tag `Backup=daily`.

---

## 📋 Checklist cho code review

- [ ] Mọi resource có đủ 5 tag bắt buộc.
- [ ] `Environment` đúng giá trị (`dev`/`staging`/`prod`), không viết hoa lung tung (`Dev`, `DEV`).
- [ ] `Owner` là email hoặc team ID có thể liên hệ — không phải "me", "admin".
- [ ] `ManagedBy = "Terraform"` cho mọi resource sinh ra từ IaC.
- [ ] `CostCenter` khớp với mã do finance cấp.
