# 🎓 Buổi 16 — Security & Best Practices

> Code Terraform "chạy được" ≠ "an toàn để chạy ở prod". Buổi này đưa quy trình + tool để **bắt lỗi bảo mật trước khi merge**, không phải sau khi đã apply.

---

## 🎯 Mục tiêu

- Cài và chạy được **`tflint`**, **`tfsec`** (hoặc `trivy iac`), **`checkov`** trên repo.
- Setup **`pre-commit`** tự động fmt + scan trước mỗi commit.
- Hiểu các tag chuẩn và áp vào mọi resource.
- Viết IAM policy **least privilege** cho Terraform runner ở prod (KHÔNG dùng `AdministratorAccess`).

---

## 📚 Lý thuyết — 4 công cụ phải biết

### 1. `terraform fmt` — Format code
Built-in, không phải scanner. Đảm bảo style nhất quán.
```bash
terraform fmt -recursive
```

### 2. `tflint` — Linter cú pháp + best-practice
- Bắt: typo `t3.microo`, resource thiếu argument bắt buộc, naming convention sai, tag thiếu.
- Có plugin riêng cho AWS, Azure, GCP. Buổi này dùng plugin AWS.
- Config: `.tflint.hcl` ở root repo.

### 3. `tfsec` (hoặc `trivy iac`) — Security scanner
- Bắt: bucket không bật encryption, SG mở `0.0.0.0/0` port 22, RDS không encrypt at rest, IAM policy quá rộng (`*:*`).
- **Lưu ý**: tfsec đã được Aqua Security gộp vào `trivy`. Có thể dùng `trivy config .` thay thế.

### 4. `checkov` — Compliance scanner (CIS, NIST, PCI-DSS)
- Bao trùm rộng hơn tfsec, có rule cho cả CloudFormation, Kubernetes, ARM.
- Phù hợp khi cần báo cáo compliance.

### Khi nào dùng cái nào?
| Tool | Phạm vi | Bắt được gì |
|---|---|---|
| `terraform fmt` | Style | Format code |
| `terraform validate` | Cú pháp | Lỗi syntax, type mismatch |
| `tflint` | HCL best-practice | Lỗi cấu hình, naming, tag thiếu |
| `tfsec` / `trivy` | Security | Lỗ hổng cấu hình AWS/cloud |
| `checkov` | Compliance | CIS, PCI-DSS, HIPAA rules |

**Khuyến nghị**: chạy cả 4 trong CI. Local dev tối thiểu fmt + validate + tflint qua pre-commit.

---

## 🛠️ Các bước thực hành

### Bước 1 — Cài tool

**Trên macOS / Linux:**
```bash
# tflint
brew install tflint
# hoặc: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# tfsec
brew install tfsec
# hoặc: curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# checkov (Python)
pip install checkov

# pre-commit
pip install pre-commit
```

**Trên Windows (PowerShell với Chocolatey):**
```powershell
choco install tflint tfsec checkov
pip install pre-commit
```

### Bước 2 — Copy config về root repo
- `.tflint.hcl` (file trong folder này)
- `.pre-commit-config.yaml` (file trong folder này)

### Bước 3 — Init plugin tflint
```bash
tflint --init
```

### Bước 4 — Cài pre-commit hook vào git
```bash
pre-commit install
# Test chạy thử toàn repo:
pre-commit run -a
```

### Bước 5 — Quét bảo mật Project 1
```bash
cd buoi-13-project1-alb-finish/  # hoặc nơi có code Project 1
tfsec .
checkov -d .
tflint --recursive
```

### Bước 6 — Đọc cảnh báo và fix

**Ví dụ cảnh báo `tfsec` thường gặp:**

```
Result #1 HIGH Bucket does not have encryption enabled
  ─────────────────────────────────────
   buoi-03-aws-provider-s3/main.tf:12

   resource "aws_s3_bucket" "data" {
     bucket = "my-data-${random_id.s.hex}"
   }
  ─────────────────────────────────────
   ID         aws-s3-encryption-customer-key
   Impact     The bucket objects could be read if compromised
   Resolution Configure bucket encryption
```

**Cách fix**: thêm resource `aws_s3_bucket_server_side_encryption_configuration`:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**Cảnh báo phổ biến khác và cách fix:**

| Cảnh báo | Resource | Cách fix |
|---|---|---|
| `aws-s3-block-public-acls` | `aws_s3_bucket` | Thêm `aws_s3_bucket_public_access_block` chặn public |
| `aws-vpc-no-public-ingress-sgr` | `aws_security_group` | Thay `0.0.0.0/0` port 22 bằng IP công ty hoặc dùng SSM |
| `aws-rds-encrypt-instance-storage-data` | `aws_db_instance` | `storage_encrypted = true` |
| `aws-rds-no-public-db` | `aws_db_instance` | `publicly_accessible = false` |
| `aws-cloudwatch-log-group-customer-key` | `aws_cloudwatch_log_group` | Set `kms_key_id` cho log group nhạy cảm |
| `aws-iam-no-policy-wildcards` | `aws_iam_policy` | Thay `Action = "*"` bằng list cụ thể |
| `aws-ec2-no-public-ip` | `aws_instance` | `associate_public_ip_address = false`, dùng NAT |

### Bước 7 — IAM least privilege cho Terraform runner (tóm tắt)

Ở **dev/staging** dùng `AdministratorAccess` cho gọn. Ở **prod** thì KHÔNG —
key Terraform runner mà lộ ra mạng là toàn quyền account: xoá RDS, tạo IAM user lạ,
huỷ Organizations. Ngoài ra audit log của `Administrator` đọc cũng vô nghĩa
(action nào cũng `Allow`), không có blast radius control khi có sự cố.

Folder này có sẵn template `iam-policy-terraform-runner.json` — copy paste, đổi
`PROD-ACCOUNT-ID` và prefix bucket theo môi trường thật.

> 📖 Phần deep-dive về IAM least privilege (giải thích từng `Sid`, snippet
> `aws:RequestedRegion`, workflow áp policy này qua OIDC role) ở
> [Buổi 21 — Vận hành & Rollback](../buoi-21-operations-rollback/README.md#-iam-least-privilege-cho-terraform-runner).

---

## ✅ Đầu ra (Checklist)

- [ ] Đã cài `tflint`, `tfsec` (hoặc `trivy`), `checkov`, `pre-commit` trên máy.
- [ ] Repo có `.tflint.hcl` và `.pre-commit-config.yaml`.
- [ ] `pre-commit run -a` pass clean trên Project 1.
- [ ] `tfsec` không còn warning HIGH/CRITICAL chưa giải trình.
- [ ] Mọi resource có 5 tag chuẩn (`tagging-strategy.md`).
- [ ] Có file `iam-policy-terraform-runner.json` mẫu, hiểu vì sao KHÔNG dùng `AdministratorAccess` ở prod (deep-dive ở B21).

---

## 🐞 Common Errors

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| `tflint --init` lỗi network | Plugin tải từ GitHub bị chặn | Set `GITHUB_TOKEN` env hoặc tải plugin offline |
| `pre-commit` chạy chậm lần đầu | Phải clone hook repo + cài tool | Lần sau cached, nhanh hơn |
| `tfsec` báo nhiều warning ở module Registry | Module bên thứ 3 chưa fix | Thêm `--exclude-downloaded-modules` |
| `terraform_validate` hook fail | Có nhiều root module trong repo | Để `--args=--init=false` hoặc cấu hình per-module |
| Cảnh báo "wildcard in Action" cho IAM Role do AWS quản lý | Service-linked role — bình thường | `tfsec:ignore:aws-iam-no-policy-wildcards` ở comment trên resource |

---

## ❓ Câu hỏi tự ôn

1. Phân biệt vai trò: `terraform fmt`, `tflint`, `tfsec`, `checkov`.
2. Vì sao chạy ở pre-commit tốt hơn chỉ chạy ở CI?
3. Nêu 3 cảnh báo `tfsec` thường gặp với S3 và cách fix.
4. Tag `ManagedBy` để làm gì? Lợi ích cho audit?
5. Khi `tfsec` báo false-positive, làm sao bỏ qua đúng cách (không tắt rule toàn repo)?

> 📖 Câu hỏi về `AdministratorAccess` và `aws:RequestedRegion` đã chuyển sang
> [Buổi 21 — Vận hành & Rollback](../buoi-21-operations-rollback/README.md#-câu-hỏi-tự-ôn).

---

## 📚 Tham khảo

- [tfsec rules](https://aquasecurity.github.io/tfsec/latest/checks/)
- [tflint AWS ruleset](https://github.com/terraform-linters/tflint-ruleset-aws)
- [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
- [Checkov](https://www.checkov.io/)
- [AWS — IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
