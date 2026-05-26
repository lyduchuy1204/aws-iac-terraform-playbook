# 🎓 Buổi 21 — Vận hành, Rollback & Mở rộng

> **Thời lượng**: ~3 giờ · **Loại**: Lý thuyết + thực hành · **Code thực hành**: ✅ (examples)

---

## 🎯 Mục tiêu

Sau buổi này, bạn biết cách **sống chung** với Terraform trong môi trường production:

- Phát hiện drift, import resource có sẵn vào state.
- Có 4 chiến lược rollback rõ ràng, biết khi nào dùng cái nào.
- Cài sẵn các bảo vệ phòng ngừa (`prevent_destroy`, `deletion_protection`, MFA Delete, plan artifact).
- Biết ước tính chi phí trước khi apply (`infracost`).

> 💡 **Trọng tâm buổi 21**: phần 2 — Rollback Strategies. Đọc 3 lần, làm 1 lần.

---

## 🗂️ Cấu trúc folder

```
buoi-21-operations-rollback/
├── README.md
└── examples/
    ├── rollback-script.sh        ← bash script: backup state, restore version, plan
    └── prevent-destroy.tf        ← reference resource có lifecycle protection
```

---

## Phần 1 — Drift detection & Import

### 1.1 Drift là gì

Drift là khi state Terraform và infra thực tế lệch nhau. Nguyên nhân thường gặp:
- Ai đó sửa tay trên Console.
- Auto-scaling tạo resource mới ngoài Terraform (ví dụ ASG sinh EC2).
- Resource bị tool khác (Ansible, CloudFormation) sửa.

### 1.2 Phát hiện drift

Demo nhanh:

```bash
# Tạo S3 bucket bằng Terraform
terraform apply

# Lên Console, sửa tag bucket bằng tay (ví dụ thêm tag Owner=hacker)
# Quay lại CLI:
terraform plan
```

Output sẽ thấy diff:

```
~ resource "aws_s3_bucket" "demo" {
    ~ tags = {
        - "Owner" = "hacker" -> null
      }
  }
```

Plan đề xuất xoá tag để khớp code. Lựa chọn:
- **Apply để bring back về code** (an toàn, "code is truth").
- Hoặc **cập nhật code** thêm `Owner = "hacker"` rồi apply (hiếm — thường drift là sai).

### 1.3 `terraform plan -refresh-only`

Plan thường đã refresh state mặc định. Nếu muốn chỉ kiểm tra mà không update state:

```bash
terraform plan -refresh-only
terraform apply -refresh-only   # chỉ ghi nhận drift vào state, không thay infra
```

### 1.4 Import resource có sẵn

Tình huống: ai đó tạo S3 bucket `legacy-bucket` bằng tay, giờ muốn quản lý bằng Terraform.

#### Bước 1 — Viết block resource khớp config thực tế

```hcl
resource "aws_s3_bucket" "legacy" {
  bucket = "legacy-bucket"
}
```

#### Bước 2 — Import vào state

```bash
# Cách cũ (CLI, vẫn dùng được):
terraform import aws_s3_bucket.legacy legacy-bucket

# Cách mới (block, từ TF 1.5+, có lợi: review qua plan):
```

```hcl
import {
  to = aws_s3_bucket.legacy
  id = "legacy-bucket"
}
```

```bash
terraform plan      # xem diff
terraform apply     # state được import + apply config nếu cần
```

#### Bước 3 — Iterate code đến khi `plan` không có thay đổi

Có thể phải thêm dần `versioning`, `tags`, `server_side_encryption_configuration`... Mục tiêu: `plan` ra `No changes`.

---

## Phần 2 — 🔥 Rollback Strategies

> Khi `apply` lỗi giữa chừng hoặc apply nhầm, làm gì? **4 cách theo mức độ nghiêm trọng**.

### 📋 Quick lookup — chọn cách rollback

| Tình huống thực tế | Dùng cách | Mất data? |
|---|---|---|
| Đổi tag/scaling/env var, KHÔNG đụng data | A — Git revert | ❌ Không |
| State corrupt, hoặc apply nhầm code (chưa đụng data nhiều) | B — S3 versioning restore | ❌ Không |
| 1 EC2/Lambda lệch nội tại, cần "tạo lại sạch" | C — `apply -replace=` | ⚠️ Mất nếu là RDS/EBS |
| State trỏ sai resource hoặc Terraform "quên" tài nguyên thật | D — `state rm` + `import` | ❌ Không (sửa state, KHÔNG đụng infra) |

> 💡 Đừng cố nhớ thuộc. Bookmark bảng này, khi sự cố mở ra dò.

### A. Git revert + CI/CD apply lại (an toàn nhất, ưu tiên #1)

```bash
git revert <commit-bad>
git push origin main
# CI workflow terraform-apply tự chạy, đẩy infra về version cũ
```

**Phù hợp khi**:
- Thay đổi không ảnh hưởng data: tag, naming, scaling number, env var, IAM policy.
- Pipeline CI/CD đã có sẵn (buổi 20).

**KHÔNG phù hợp khi**:
- Đã `destroy` resource có data (RDS, S3 có object) — git revert chỉ phục hồi code, KHÔNG phục hồi data đã mất.

---

### B. S3 state versioning restore

Tình huống: state file bị apply nhầm → infra thật chưa thay đổi nhiều, hoặc state corrupt → cần quay state về thời điểm trước.

> 📌 **Tiền đề**: bucket state đã bật **versioning** (buổi 06 đã hướng dẫn).

#### Bước thủ công (tự gõ):

```bash
# 1) Backup state hiện tại trước khi đụng vào
aws s3 cp "s3://my-tfstate-bucket/envs/dev/terraform.tfstate" \
  "state-backup-$(date +%s).tfstate"

# 2) Liệt kê version cũ
aws s3api list-object-versions \
  --bucket my-tfstate-bucket \
  --prefix envs/dev/terraform.tfstate \
  --query 'Versions[].{Id:VersionId,Time:LastModified,IsLatest:IsLatest}' \
  --output table

# 3) Restore version cũ — copy đè bằng version cũ làm version mới nhất
aws s3api copy-object \
  --bucket my-tfstate-bucket \
  --key envs/dev/terraform.tfstate \
  --copy-source "my-tfstate-bucket/envs/dev/terraform.tfstate?versionId=<OLD-VERSION-ID>"

# 4) Plan trước khi apply
terraform init -reconfigure
terraform plan
# Đọc kỹ plan, nếu OK:
terraform apply
```

> 🔒 **Warning về file backup**: `state-backup-*.tfstate` chứa **secret plain text** (DB password, API key trong state). Hãy:
> - Đảm bảo `.gitignore` đã chặn `*.tfstate*` (xem buổi 15).
> - Xoá file backup ngay sau khi xong rollback.
> - KHÔNG share qua chat/email.

#### Hoặc dùng script có sẵn:

```bash
# Script ở examples/rollback-script.sh đã tự động hoá các bước trên
./examples/rollback-script.sh my-tfstate-bucket envs/dev/terraform.tfstate
# In ra danh sách version → chọn 1 VersionId → chạy lại:
./examples/rollback-script.sh my-tfstate-bucket envs/dev/terraform.tfstate <VersionId>
```

**Phù hợp khi**:
- State bị apply nhầm hoặc corrupt.
- Infra thật còn khớp với version cũ của state.

---

### C. `terraform apply -replace="..."` (taint thay thế)

Tình huống: 1 resource bị "lệch" nội tại (ví dụ EC2 user-data chạy lỗi, file system corrupt) — cần tạo lại.

```bash
terraform plan -replace="aws_instance.web"
terraform apply -replace="aws_instance.web"
```

Resource sẽ destroy + create.

**Phù hợp khi**:
- Stateless resource (EC2 instance, Lambda, Launch Template).
- Resource là "cattle, not pets".

**KHÔNG phù hợp khi**:
- Resource có data quan trọng (RDS instance, EBS volume, DynamoDB table) → mất data.

> ⚠️ Trên RDS, lệnh này tạo DB mới rỗng. PHẢI snapshot trước.

---

### D. Surgical state edit — `state rm` + `import`

Tình huống: state lệch (Terraform nghĩ resource bị xoá) nhưng infra thật đúng. Tránh để Terraform destroy/recreate nhầm.

```bash
# 1) Backup state TRƯỚC
terraform state pull > "state-backup-$(date +%s).tfstate"

# 2) Gỡ resource khỏi state — KHÔNG xoá thật
terraform state rm aws_db_instance.this

# 3) Import lại bằng identifier thực tế
terraform import aws_db_instance.this app-prod-db

# 4) Plan để xác nhận no-op
terraform plan
```

**Phù hợp khi**:
- Đã import nhầm 2 lần, hoặc state trỏ sai resource.
- Refactor module: resource cần đổi địa chỉ trong state (cũng có thể dùng `terraform state mv`).

> 📌 **Lưu ý**: từ Terraform 1.7+, có `removed` block + `moved` block declarative — khuyến nghị dùng thay cho `state rm/mv` thủ công khi có thể.

---

### Quy tắc vàng khi rollback

- ✅ **Luôn `terraform plan`** trước khi `apply` rollback.
- ✅ **Backup state** trước thao tác state nguy hiểm:
  ```bash
  terraform state pull > "backup-$(date +%s).tfstate"
  ```
- ✅ **Có data quan trọng (RDS, S3)** → snapshot trước.
- ✅ **Communicate**: báo team biết đang rollback (Slack, status page).
- ❌ **KHÔNG** rollback bằng `terraform destroy && apply lại` ở prod — mất data, mất uptime.
- ❌ **KHÔNG** sửa file state bằng tay (text editor) nếu chưa hiểu rõ.
- ❌ **KHÔNG** chạy 2 process apply song song cùng state — luôn để lock làm việc.

---

## Phần 3 — Phòng ngừa hơn chữa

### 3.1 `prevent_destroy` ở Terraform

```hcl
resource "aws_db_instance" "main" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

`terraform plan` thấy có destroy resource này → **error**, dừng lại. Phải xoá block trước, commit, apply riêng.

> ⚠️ **`prevent_destroy` CHỈ chặn `terraform destroy/apply`. KHÔNG ngăn được người vào Console hay AWS CLI xoá tay**. Vì vậy với resource quan trọng, dùng ĐỒNG THỜI cả `prevent_destroy` (Terraform layer) + `deletion_protection` (AWS API layer).

### 3.2 `deletion_protection` ở AWS

Tầng phòng vệ thứ 2 — chặn ở API level, kể cả ai đó dùng Console hay AWS CLI:

| Resource | Field |
|---|---|
| RDS | `deletion_protection = true` |
| ALB / NLB | `enable_deletion_protection = true` |
| EC2 (instance) | `disable_api_termination = true` |
| DynamoDB (provider 5.x+) | `deletion_protection_enabled = true` |
| EKS Cluster | (set qua Console hoặc IAM SCP) |

> Dùng **đồng thời** `prevent_destroy` (Terraform) + `deletion_protection` (AWS) cho resource quan trọng nhất.

### 3.3 MFA Delete cho S3 bucket production

S3 versioning chỉ là tuyến đầu. MFA Delete buộc phải có MFA token để xoá vĩnh viễn version. **KHÔNG enable được qua Terraform** — chỉ qua AWS CLI từ root account:

```bash
aws s3api put-bucket-versioning \
  --bucket my-prod-bucket \
  --versioning-configuration Status=Enabled,MFADelete=Enabled \
  --mfa "arn:aws:iam::<account>:mfa/<device> <token-code>"
```

### 3.4 Plan artifact + manual approval

- CI lưu file `tfplan` thành artifact (workflow buổi 20 đã làm).
- Người approve đọc plan rồi mới approve apply.
- Tuyệt đối KHÔNG `apply -auto-approve` ở prod mà không có gate.

### 3.5 Toàn cảnh các tầng phòng vệ

```
┌──────────────────────────────────────────┐
│ Tầng 5: PR review + plan artifact (2 mắt) │
├──────────────────────────────────────────┤
│ Tầng 4: GitHub Environment approval gate  │
├──────────────────────────────────────────┤
│ Tầng 3: prevent_destroy (Terraform)       │
├──────────────────────────────────────────┤
│ Tầng 2: deletion_protection (AWS API)     │
├──────────────────────────────────────────┤
│ Tầng 1: Versioning + Backup + Snapshot    │
└──────────────────────────────────────────┘
```

Càng quan trọng càng dùng nhiều tầng. Học sinh: ≥ 3 tầng cho RDS, S3 prod.

---

## 🔐 IAM Least Privilege cho Terraform Runner

> Buổi 16 đã tóm tắt vì sao prod KHÔNG xài `AdministratorAccess`. Đây là phần
> deep-dive: đọc từng `Sid`, hiểu condition, biết áp như thế nào qua OIDC.

### Vì sao KHÔNG `AdministratorAccess` ở prod

1. **Leak key = thảm hoạ**. Access key của runner lọt ra log, repo public, máy
   dev bị nhiễm — kẻ xấu có toàn quyền account: xoá RDS, drop bucket, tạo IAM
   user backdoor, mở Organizations sang tài khoản khác.
2. **Audit log không đọc được**. Action nào cũng `Allow` → khi soi
   CloudTrail/Access Analyzer không phân biệt được "runner thực sự cần làm gì"
   với "ai đó đang abuse". Least privilege ép runner khai báo phạm vi.
3. **Không có blast radius control**. Apply nhầm 1 module sai vùng → có thể
   tạo resource ở `us-east-1` lạ hoắc, sinh chi phí và lỗ hổng. Có policy
   chặt mới khoanh được vùng nổ.

### Tinh thần policy `iam-policy-terraform-runner.json` qua từng `Sid`

| `Sid` | Vai trò |
|---|---|
| `ReadOnlyForPlanning` | `Describe*`/`Get*`/`List*` rộng để `terraform plan` đọc state cloud — read-only nên rộng cũng OK. |
| `ManageNetworking` | Write VPC/Subnet/RouteTable/SG, gắn condition `aws:RequestedRegion`. |
| `ManageCompute` | Write EC2/ASG/Launch Template, cùng condition region. |
| `ManageRDS` | Write RDS (create/modify/delete DB instance, subnet/parameter group), cùng condition region. |
| `ManageS3AppBuckets` | Scope theo prefix `arn:aws:s3:::company-app-*`, runner KHÔNG đụng được bucket khác. |
| `PassRoleScoped` | `iam:PassRole` chỉ cho path role `app-*`/`ec2-*`, và chỉ pass cho EC2/Lambda/RDS service. |
| `DenyDangerousActions` | **Deny tuyệt đối** `iam:CreateUser`, `organizations:*`, `billing:*` — kể cả khi có policy khác Allow vì Deny luôn thắng. |

### Snippet condition `aws:RequestedRegion`

```json
"Condition": {
  "StringEquals": {
    "aws:RequestedRegion": ["ap-southeast-1"]
  }
}
```

Ép Terraform runner chỉ tạo được resource ở region đã khai báo. Kể cả khi
key bị lộ, attacker không thể spawn EC2 mining ở `us-east-1` hay
`eu-west-1` — request bị AWS reject ngay tại API gateway. Đây là blast
radius control rẻ tiền nhất mà hiệu quả.

> 💡 Resource global (IAM, CloudFront, Route53) không có region → condition
> này không áp dụng. Vẫn phải dùng `Sid` `DenyDangerousActions` cho IAM.

### Workflow áp dụng

- **Dev/staging**: cứ `AdministratorAccess` cho đỡ phiền học viên — môi trường
  này được phép xoá đi tạo lại, không có data thật.
- **Prod**:
  1. Tạo IAM Role riêng `terraform-deployer-prod`.
  2. Attach policy template `iam-policy-terraform-runner.json` (đổi
     `PROD-ACCOUNT-ID`, prefix bucket cho khớp).
  3. Role được **assume qua OIDC** từ GitHub Actions — KHÔNG có long-lived
     access key, mỗi run sinh credential tạm 1h. Cách setup OIDC ở
     [Buổi 20 — CI/CD](../buoi-20-cicd-pipeline/README.md).
  4. Khi sinh resource mới (ví dụ ElastiCache lần đầu): bổ sung `Sid` mới
     trong policy, PR review, apply riêng — chấp nhận trade-off đổi sự an
     toàn lấy 5 phút thêm policy.

### Tham chiếu file

Xem template
[`buoi-16-security-bestpractice/iam-policy-terraform-runner.json`](../buoi-16-security-bestpractice/iam-policy-terraform-runner.json)
để copy paste.

---

## 💰 Cost & Tooling

### infracost — ước tính chi phí trước apply

#### Cài đặt

```bash
# macOS
brew install infracost

# Linux/WSL
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Windows (Chocolatey)
choco install infracost
```

#### Đăng ký + lấy API key (free)

```bash
infracost auth login
```

#### Dùng

```bash
# Ước tính cost của 1 stack
cd envs/dev
infracost breakdown --path .

# So sánh trước và sau khi sửa code (so với base branch)
infracost diff --path .

# Xuất JSON để gắn lên CI
infracost breakdown --path . --format json --out-file infracost-base.json
```

#### Tích hợp CI

Có action `infracost/actions/setup` + `infracost/actions/comment` để tự comment cost diff vào PR. Nên thêm vào pipeline buổi 20 cho project có nhiều resource thật (Project 1, không quá cần cho Project 2 gần như free).

### Các tool nên biết tên (đọc, chưa cần dùng)

| Tool | Dùng khi |
|---|---|
| **Terragrunt** | Repo nhiều env/module — DRY backend, multi-account |
| **Atlantis** | Tự host CI Terraform on-prem, comment plan tự động |
| **Terraform Cloud / HCP Terraform** | Managed backend + remote run + RBAC |
| **Spacelift / env0** | Alternative thương mại của Terraform Cloud |
| **OpenTofu** | Fork open-source của Terraform — biết để chọn nếu công ty cấm BSL |

---

## ✅ Đầu ra checklist

### Phần 1 — Drift & Import
- [ ] Tạo 1 S3 bucket bằng Terraform, sửa tag trên Console, `plan` thấy diff.
- [ ] `apply` để bring back, plan trở thành `No changes`.
- [ ] Import 1 bucket có sẵn vào state, `plan` ra `No changes`.

### Phần 2 — Rollback
- [ ] Hiểu khi nào dùng cách A/B/C/D.
- [ ] Chạy thử `examples/rollback-script.sh` (ít nhất bước list version) trên 1 stack học.
- [ ] Backup state thủ công thành công bằng `terraform state pull`.
- [ ] Demo `terraform apply -replace=` trên 1 EC2 hoặc Lambda.

### Phần 3 — Phòng ngừa
- [ ] Có ít nhất 1 resource trong project có `prevent_destroy = true`.
- [ ] RDS prod có `deletion_protection = true`.
- [ ] Bucket S3 chứa state có versioning ON.
- [ ] CI workflow upload plan artifact (đã làm ở buổi 20).

### Cost
- [ ] `infracost breakdown` chạy được trên Project 1 (hoặc Project 2).
- [ ] Đọc + giải thích được output: dòng nào đắt nhất, vì sao.

---

## 🐛 Common errors

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `Instance cannot be destroyed: prevent_destroy` | Đang muốn xoá resource có lock | Xoá block `prevent_destroy`, commit, apply, rồi mới destroy |
| `OperationNotPermittedException: ... DeletionProtection enabled` | RDS/ALB có `deletion_protection` | Set `deletion_protection = false`, apply, rồi mới destroy |
| `terraform import` báo `Resource already managed` | Đã import rồi | `terraform state list` xem đã có chưa |
| Restore version từ S3 nhưng `plan` vẫn không khớp | Cache local `.terraform/` cũ | `terraform init -reconfigure` |
| `Error: state lock` khi rollback | Có process khác đang chạy hoặc lock file kẹt | Xoá `<key>.tflock` thủ công sau khi chắc chắn không có ai đang chạy |
| `infracost` báo `unauthorized` | Chưa login hoặc API key sai | `infracost auth login` lại |

---

## ❓ Câu hỏi tự ôn

1. Drift là gì? 3 nguyên nhân thường gặp?
2. Khác nhau giữa `terraform plan` và `terraform plan -refresh-only`?
3. 4 chiến lược rollback theo mức độ — kể tên và 1 use case mỗi cái.
4. Vì sao KHÔNG dùng `terraform destroy && apply lại` để rollback ở prod?
5. `prevent_destroy` (Terraform) và `deletion_protection` (AWS) khác nhau ở tầng nào? Vì sao nên dùng đồng thời?
6. MFA Delete có thể enable bằng Terraform không? Vì sao?
7. `import` block (TF 1.5+) khác lệnh `terraform import` ở điểm nào?
8. `infracost breakdown` đọc từ đâu? Có cần `terraform apply` trước không?

---

## 📚 Tham khảo

- [Terraform — drift detection](https://developer.hashicorp.com/terraform/cli/commands/refresh)
- [`import` block](https://developer.hashicorp.com/terraform/language/import)
- [Lifecycle meta-argument](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)
- [S3 versioning + MFA Delete](https://docs.aws.amazon.com/AmazonS3/latest/userguide/MultiFactorAuthenticationDelete.html)
- [RDS deletion protection](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_DeleteInstance.html#USER_DeletionProtection)
- [infracost docs](https://www.infracost.io/docs/)
- [Terragrunt](https://terragrunt.gruntwork.io/) · [Atlantis](https://www.runatlantis.io/) · [OpenTofu](https://opentofu.org/)

---

🎉 **Hết playbook**. Quay lại [README chính](../README.md) để xem mục "Sau khi học xong" và tự đánh giá.
