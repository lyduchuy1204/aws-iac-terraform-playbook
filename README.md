# 📘 AWS IaC Terraform Playbook

> Sổ tay học **Terraform trên AWS** từ cơ bản đến nâng cao cho **DevOps mới**. Mỗi **buổi học = 1 folder** trong repo. Đi tuần tự, hoàn thành checklist mỗi buổi rồi mới sang buổi kế tiếp.

---

## 📑 Table of Contents

| # | Buổi học | Folder | Mục tiêu chính | Thời lượng |
|---|---|---|---|---|
| 0 | [Chuẩn bị môi trường](#-buổi-00--chuẩn-bị-môi-trường) | `buoi-00-setup` | Cài AWS CLI, Terraform, VS Code | 1h |
| 0b | [AWS Foundations cơ bản](#-buổi-00b--aws-foundations-cơ-bản) | `buoi-00b-aws-foundations` | Hiểu VPC/Subnet/IAM/EC2/SG trên Console | 2h |
| 1 | [IaC & Terraform là gì](#-buổi-01--iac--terraform-là-gì) | `buoi-01-iac-intro` | Hiểu IaC, vòng đời Terraform | 1h |
| 2 | [HCL Syntax cơ bản](#-buổi-02--hcl-syntax-cơ-bản) | `buoi-02-hcl-basics` | Viết được file `.tf` đầu tiên | 1.5h |
| 3 | [AWS Provider — S3 đầu tiên](#-buổi-03--aws-provider--s3-bucket-đầu-tiên) | `buoi-03-aws-provider-s3` | Tạo S3 + version pinning + lock file | 1.5h |
| 4 | [Variables, Outputs, Locals](#-buổi-04--variables-outputs-locals-tfvars) | `buoi-04-variables-outputs` | Tách config khỏi code | 2h |
| 5 | [Data Sources & Dependencies](#-buổi-05--data-sources--dependencies) | `buoi-05-data-sources` | Query AWS, hiểu graph phụ thuộc | 1.5h |
| 6 | [Remote State (S3 native locking)](#-buổi-06--remote-state-s3-native-locking) | `buoi-06-remote-state` | Lưu state an toàn, có lock | 2h |
| 7 | [Modules cơ bản + Registry](#-buổi-07--modules-cơ-bản--registry) | `buoi-07-modules` | Tự viết & dùng module có sẵn | 2h |
| 8 | [Multi-environment dev/prod](#-buổi-08--multi-environment-devprod) | `buoi-08-multi-env` | Tách dev/prod chuẩn production | 2h |
| 9 | [count, for_each, dynamic](#-buổi-09--count-for_each-dynamic) | `buoi-09-loops-dynamic` | Sinh nhiều resource từ data | 2h |
| 10 | **Project 1** — VPC Network | `buoi-10-project1-network` | Module VPC + Subnet + NAT | 3h |
| 11 | **Project 1** — Compute (EC2 + ASG) | `buoi-11-project1-compute` | Launch Template + ASG + SG | 2.5h |
| 12 | **Project 1** — Database (RDS + Secrets) | `buoi-12-project1-database` | RDS MySQL + Secrets Manager | 2.5h |
| 13 | **Project 1** — ALB & Hoàn thiện | `buoi-13-project1-alb-finish` | ALB + truy cập web qua DNS | 2h |
| 14 | [Observability — Logs, Metrics, Alarms](#-buổi-14--observability--logs-metrics-alarms) | `buoi-14-observability` | CloudWatch Alarm + SNS | 2h |
| 15 | [Git Workflow cho DevOps](#-buổi-15--git-workflow-cho-devops) | `buoi-15-git-workflow` | Branch, PR, review, .gitignore | 1.5h |
| 16 | [Security & Best Practices](#-buổi-16--security--best-practices) | `buoi-16-security-bestpractice` | tflint, tfsec, pre-commit | 2h |
| 17 | [Terraform Testing](#-buổi-17--terraform-testing) | `buoi-17-testing` | `terraform test` native | 2h |
| 18 | **Project 2** — Lambda + DynamoDB | `buoi-18-project2-lambda-ddb` | Lambda CRUD DynamoDB | 3h |
| 19 | **Project 2** — API Gateway | `buoi-19-project2-apigateway` | REST API public | 2h |
| 20 | **Project 2** — CI/CD GitHub Actions | `buoi-20-project2-cicd` | Pipeline plan/apply + OIDC | 3h |
| 21 | [Vận hành, Rollback & Mở rộng](#-buổi-21--vận-hành-rollback--mở-rộng) | `buoi-21-operations-rollback` | Drift, import, rollback, infracost | 3h |

> **Tổng**: ~46h, học giãn 3 buổi/tuần là gọn ~7–8 tuần.

---

## 🗂️ Cấu trúc folder repo

```
aws-iac-terraform-playbook/
├── README.md                              ← bạn đang đọc
├── buoi-00-setup/
├── buoi-00b-aws-foundations/
├── buoi-01-iac-intro/
├── buoi-02-hcl-basics/
├── ...
├── buoi-10-project1-network/
│   ├── README.md
│   ├── modules/network/
│   └── envs/dev/
├── buoi-20-project2-cicd/
│   ├── README.md
│   ├── .github/workflows/
│   └── ...
└── buoi-21-operations-rollback/
```

> **Quy ước**: Mỗi folder buổi học có `README.md` riêng + code mẫu. Folder gốc này chỉ là index tổng.

---

## ✅ Cách dùng repo này

1. **Tuần tự**: Đi từ `buoi-00` → `buoi-21`, không nhảy buổi.
2. **Mỗi buổi**: Đọc mục tiêu → làm theo các bước → hoàn thành checklist → commit code.
3. **Sau mỗi buổi có resource AWS**: Chạy `terraform destroy` để tránh tốn tiền.
4. **Khi bí**: Đọc lại "Common Errors" cuối mỗi buổi.
5. **Box `💰 Cost warning`**: nếu có ở buổi nào, đọc kỹ trước khi `apply`.

---

## 🎓 Buổi 00 — Chuẩn bị môi trường

**Mục tiêu**: Máy tính sẵn sàng học, AWS CLI nói chuyện được với account của bạn.

**Đầu ra**:
- [ ] `terraform -version` ≥ 1.11 (cần cho S3 native locking ở buổi 06)
- [ ] `aws sts get-caller-identity` trả về Account ID của bạn
- [ ] Tạo IAM user `terraform-learner` (KHÔNG dùng root)
- [ ] Bật **AWS Budget Alert** $5

**Các bước**:
1. Cài AWS CLI v2, Terraform, Git, VS Code (extension `HashiCorp Terraform`).
2. AWS Console → IAM → tạo user `terraform-learner`, gắn `AdministratorAccess`, tạo Access Key.
3. `aws configure` → nhập key, region `ap-southeast-1`.
4. Bật Budget: Billing → Budgets → Create → $5 monthly alert vào email.

**Common errors**:
- `Unable to locate credentials` → chưa chạy `aws configure` hoặc sai profile.
- Terraform báo region invalid → check `~/.aws/config`.

---

## 🎓 Buổi 00b — AWS Foundations cơ bản

> 🎯 **Buổi này KHÔNG dùng Terraform**. Mục đích: hiểu khái niệm AWS trên Console trước, để khi vào Terraform không bị "double confusion".

**Mục tiêu**: Hiểu các block xây hạ tầng AWS cơ bản. Bấm tay được trên Console, biết tên gọi và vai trò từng thứ.

**Đầu ra**:
- [ ] Giải thích được: Region, AZ, VPC, Subnet (public/private), Route Table, IGW, NAT Gateway.
- [ ] Phân biệt được: IAM User, IAM Role, IAM Policy, Trust Policy.
- [ ] Hiểu Security Group (stateful) vs NACL (stateless).
- [ ] Tự tay tạo 1 EC2 t3.micro trên Console, SSH/Session Manager vào được.
- [ ] Biết phân biệt EC2, Lambda, Fargate (serverless levels).

**Các bước**:
1. Vẽ sơ đồ VPC bằng giấy: 1 VPC, 2 AZ, mỗi AZ có 1 public + 1 private subnet, IGW, NAT.
2. Trên Console, tạo VPC theo sơ đồ trên (dùng VPC Wizard cho nhanh).
3. Tạo 1 EC2 trong public subnet, gắn SG mở port 22.
4. Tạo IAM Role `EC2-SSM` cho Session Manager, gắn vào EC2, kết nối qua Session Manager (KHÔNG cần SSH key).
5. **Xoá hết** sau khi xong (NAT Gateway tốn tiền).

**💰 Cost warning**:
> NAT Gateway = ~$32/tháng + traffic. EC2 t3.micro Free Tier 12 tháng. **Phải xoá NAT khi không dùng.**

**Common errors**:
- Không SSH được EC2 → quên gắn key pair, hoặc SG không mở 22, hoặc Subnet không có route ra IGW.
- Session Manager không kết nối → IAM Role chưa có policy `AmazonSSMManagedInstanceCore`.

**Tài liệu nền**: AWS VPC User Guide, IAM User Guide (đọc 30 phút phần overview là đủ).

---

## 🎓 Buổi 01 — IaC & Terraform là gì

**Mục tiêu**: Trả lời được "tại sao cần IaC", "Terraform làm gì khi gõ apply".

**Đầu ra**:
- [ ] Vẽ được sơ đồ flow `init → plan → apply → destroy`.
- [ ] Phân biệt Terraform vs CloudFormation vs CDK.
- [ ] Hiểu state là gì, vì sao cần.

**Các bước**:
1. Đọc lý thuyết (file `README.md` trong folder buổi 01 sẽ có).
2. Xem 1 video ngắn HashiCorp giới thiệu Terraform.
3. Trả lời 5 câu hỏi tự ôn ở cuối README buổi 01.

**Không có code thực hành ở buổi này** — chỉ lý thuyết để vững nền.

---

## 🎓 Buổi 02 — HCL Syntax cơ bản

**Mục tiêu**: Viết và chạy được file `.tf` đầu tiên (chưa cần AWS).

**Đầu ra**:
- [ ] Hiểu `provider`, `resource`, `variable`, `output`.
- [ ] Phân biệt string / number / list / map / object.
- [ ] Chạy được `terraform init`, `plan`, `apply` ở local.

**Các bước**:
1. Tạo `main.tf` dùng provider `local` để tạo file text.
   ```hcl
   resource "local_file" "hello" {
     filename = "${path.module}/hello.txt"
     content  = "Hello Terraform!"
   }
   ```
2. `terraform init` → `terraform plan` → `terraform apply`.
3. Sửa nội dung, apply lại — xem Terraform detect change thế nào.
4. `terraform destroy` để xoá.

**Checkpoint**: Bạn giải thích được file `terraform.tfstate` chứa gì.

---

## 🎓 Buổi 03 — AWS Provider & S3 Bucket đầu tiên

**Mục tiêu**: Tạo resource AWS thật bằng Terraform. Hiểu version pinning và lock file.

**Đầu ra**:
- [ ] Cấu hình `provider "aws"` với region.
- [ ] Pin version: `terraform >= 1.11`, `aws ~> 5.0`.
- [ ] Hiểu vai trò của `.terraform.lock.hcl` và **commit nó vào Git**.
- [ ] Tạo 1 S3 bucket có tag, name unique (dùng `random_id`).

**Các bước**:
1. Khai báo provider + version constraints:
   ```hcl
   terraform {
     required_version = ">= 1.11"
     required_providers {
       aws    = { source = "hashicorp/aws", version = "~> 5.0" }
       random = { source = "hashicorp/random", version = "~> 3.5" }
     }
   }
   provider "aws" { region = "ap-southeast-1" }
   ```
2. Tạo bucket với `random_id` suffix.
3. `terraform apply`, lên Console kiểm tra.
4. Mở `.terraform.lock.hcl`, đọc nội dung, hiểu hash là gì.
5. `terraform destroy`.

**Checkpoint**: Vì sao phải pin version + commit lock file? (Trả lời: reproducibility — mọi người trên team dùng đúng 1 phiên bản provider).

**Common errors**:
- `BucketAlreadyExists` → tên S3 phải unique toàn cầu.
- `AccessDenied` → IAM user thiếu quyền S3.

---

## 🎓 Buổi 04 — Variables, Outputs, Locals, tfvars

**Mục tiêu**: Tách giá trị cứng ra khỏi code, viết Terraform "professional".

**Đầu ra**:
- [ ] Refactor buổi 03 dùng `variable`, `locals`, `output`.
- [ ] Có file `terraform.tfvars` riêng.
- [ ] Validation rule cho variable.

**Các bước**:
1. Tách `bucket_name`, `region`, `tags` thành `variables.tf`.
2. Tạo `terraform.tfvars` truyền giá trị.
3. Dùng `locals` để compose tag mặc định (ví dụ thêm `ManagedBy = "Terraform"`).
4. `output` ARN bucket sau khi apply.
5. Thử `terraform apply -var="region=us-east-1"` để override.

**Checkpoint**: Hiểu thứ tự ưu tiên: CLI flag > tfvars > env > default.

---

## 🎓 Buổi 05 — Data Sources & Dependencies

**Mục tiêu**: Query thông tin AWS có sẵn, hiểu Terraform graph.

**Đầu ra**:
- [ ] Dùng `data "aws_caller_identity"`, `data "aws_region"`.
- [ ] Lấy AMI Amazon Linux mới nhất qua `data "aws_ami"`.
- [ ] Phân biệt implicit vs explicit dependency (`depends_on`).

**Các bước**:
1. Viết data source lấy account ID hiện tại, in qua output.
2. Viết data source lấy AMI Amazon Linux 2023 mới nhất.
3. Vẽ graph: `terraform graph | dot -Tpng > graph.png`.

---

## 🎓 Buổi 06 — Remote State (S3 native locking)

**Mục tiêu**: Lưu state lên S3 có lock — chuẩn production.

> 📌 **Cập nhật quan trọng (2025+)**: Từ Terraform **1.10** (GA ở **1.11**), backend `s3` hỗ trợ **native locking** qua `use_lockfile = true`. **DynamoDB-based locking đã deprecated** và sẽ bị xoá ở minor version tới. Khoá học này dạy theo cách mới (S3 native), bỏ DynamoDB.

**Đầu ra**:
- [ ] S3 bucket bật **versioning** + **encryption** + **block public access** cho state.
- [ ] Backend dùng `use_lockfile = true` (KHÔNG cần DynamoDB).
- [ ] Migrate state local → remote.
- [ ] 2 người chạy cùng lúc → người sau bị lock (xuất hiện file `.tflock`).

**Các bước**:
1. Tạo "bootstrap" stack: 1 S3 bucket có versioning + encryption (state local).
2. Thêm `backend "s3"` vào config app:
   ```hcl
   terraform {
     backend "s3" {
       bucket       = "my-tfstate-<acct-id>"
       key          = "envs/dev/terraform.tfstate"
       region       = "ap-southeast-1"
       encrypt      = true
       use_lockfile = true   # ← S3 native lock, thay cho dynamodb_table
     }
   }
   ```
3. `terraform init -migrate-state`.
4. Test lock: mở 2 terminal cùng `apply`, người sau gặp lỗi lock → kiểm tra file `<key>.tflock` xuất hiện trên S3.

> **Sơ đồ chicken-and-egg**:
> ```
> Stack BOOTSTRAP (state local) ──tạo──▶ S3 bucket (versioning + encryption)
>                                              ▲
>                                              │ backend (use_lockfile=true)
> Stack APP (state remote) ────────────────────┘
> ```

**Quan trọng**:
- Bootstrap stack giữ state local, KHÔNG tự lưu chính nó vào S3 nó tạo ra. Nếu muốn migrate bootstrap, phải tạo bucket khác.
- Nếu repo cũ đang dùng DynamoDB lock, có lộ trình migrate riêng (giữ cả 2 trong period chuyển tiếp, sau đó bỏ DynamoDB).

**Common errors**:
- `use_lockfile is unknown` → Terraform < 1.10, upgrade lên >= 1.11.
- Lock không nhả sau khi crash → xoá file `.tflock` thủ công trên S3 (cẩn thận khi nào KHÔNG có process nào đang chạy).

---

## 🎓 Buổi 07 — Modules cơ bản + Registry

**Mục tiêu**: Đóng gói code thành module. Biết khi nào tự viết, khi nào dùng module có sẵn.

**Đầu ra**:
- [ ] Cấu trúc module chuẩn: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`.
- [ ] Viết module `s3-bucket` với input `name`, `versioning`, `tags`.
- [ ] Dùng module `terraform-aws-modules/vpc/aws` từ Registry, so sánh trải nghiệm.
- [ ] Hiểu cách pin version module (`version = "5.5.1"`).

**Các bước**:
1. Tự viết `modules/s3-bucket/`, gọi 2 lần với input khác nhau.
2. Trong project khác, dùng module VPC từ Registry:
   ```hcl
   module "vpc" {
     source  = "terraform-aws-modules/vpc/aws"
     version = "5.5.1"
     name    = "demo-vpc"
     cidr    = "10.0.0.0/16"
     azs     = ["ap-southeast-1a", "ap-southeast-1b"]
     # ...
   }
   ```
3. So sánh: tự viết tốn thời gian, registry nhanh nhưng phải đọc kỹ docs.

**Quy tắc rút ra**:
- **Tự viết**: khi logic công ty đặc thù, hoặc cần kiểm soát mọi thứ.
- **Registry**: khi giải quyết vấn đề phổ biến (VPC, EKS, RDS) — không "reinvent the wheel".

---

## 🎓 Buổi 08 — Multi-environment (dev/prod)

**Mục tiêu**: Tách dev/prod để không apply nhầm.

**Đầu ra**:
- [ ] Cấu trúc `envs/dev/`, `envs/prod/` dùng chung `modules/`.
- [ ] Mỗi env có backend S3 key riêng (`dev/terraform.tfstate`).
- [ ] dev bucket name khác prod bucket name.

**Các bước**:
1. Refactor folder theo pattern "folder-per-env" (KHÔNG dùng workspace cho prod).
2. Mỗi env có `backend.tf`, `terraform.tfvars` riêng.
3. `terraform -chdir=envs/dev apply`.

---

## 🎓 Buổi 09 — count, for_each, dynamic

**Mục tiêu**: Sinh nhiều resource từ data, tránh copy-paste.

**Đầu ra**:
- [ ] Dùng `for_each` tạo nhiều IAM user từ 1 set.
- [ ] Dùng `dynamic "ingress"` cho Security Group rules.
- [ ] Hiểu khi nào `count`, khi nào `for_each`.

**Các bước**:
1. Tạo 3 IAM user từ `for_each = toset(["alice","bob","carol"])`.
2. Viết SG có rules đọc từ variable list, dùng `dynamic`.
3. So sánh: thêm 1 user ở giữa → `count` shift index, `for_each` thì không.

---

## 🏗️ Project 1 — Hạ tầng AWS 3-tier (Buổi 10–13)

> **Kiến trúc**:
> ```
> Internet → ALB → EC2 (ASG) → RDS MySQL
>                         ↓
>                  CloudWatch Logs
> ```
>
> **💰 Cost warning toàn project**: NAT (~$32/tháng) + ALB (~$16/tháng) + RDS t3.micro (~$13/tháng). **Destroy ngay sau mỗi buổi học.**

### 🎓 Buổi 10 — Project 1: Network Module

**Mục tiêu**: Module VPC hoàn chỉnh.

**Đầu ra**:
- [ ] VPC `10.0.0.0/16`, 2 public + 2 private subnet, 2 AZ.
- [ ] Internet Gateway + 1 NAT Gateway (cho dev tiết kiệm — KHÔNG mỗi AZ một cái).
- [ ] Route table public/private đúng.
- [ ] Module có README ghi rõ input/output.

**💰 Cost warning**: NAT Gateway tính tiền ngay khi tạo. Tắt cuối buổi.

### 🎓 Buổi 11 — Project 1: Compute (EC2 + ASG)

**Mục tiêu**: EC2 Auto Scaling chạy được, có thể scale.

**Đầu ra**:
- [ ] Launch Template với user-data cài nginx.
- [ ] ASG min=1 max=3 desired=2.
- [ ] Security Group cho EC2 (inbound từ ALB SG sẽ làm ở buổi 13).
- [ ] EC2 dùng IAM Role có Session Manager (KHÔNG dùng SSH key).

### 🎓 Buổi 12 — Project 1: Database (RDS + Secrets Manager)

**Mục tiêu**: RDS chạy private, password an toàn.

**Đầu ra**:
- [ ] RDS MySQL `db.t3.micro` Single-AZ ở private subnet (Multi-AZ chỉ cho prod).
- [ ] Subnet group + parameter group.
- [ ] DB password tự sinh bằng `random_password`, lưu vào AWS Secrets Manager.
- [ ] Resource KHÔNG có password ở plain text trong state đầu ra ngoài.
- [ ] EC2 đọc được secret qua IAM Role.

**Checkpoint**: Mở `terraform.tfstate` (qua S3), search "password" — KHÔNG được thấy plain text.

### 🎓 Buổi 13 — Project 1: ALB & Hoàn thiện

**Mục tiêu**: Truy cập web qua ALB DNS, kết nối EC2 → RDS thành công.

**Đầu ra**:
- [ ] ALB + Target Group + Listener port 80.
- [ ] EC2 register vào TG qua ASG.
- [ ] SG: ALB→EC2 port 80, EC2→RDS port 3306.
- [ ] `curl http://<alb-dns>` trả về trang nginx.
- [ ] EC2 query DB thành công (script test trong user-data).
- [ ] `terraform destroy` sạch sẽ.

**Checkpoint Project 1**: Demo trang web qua ALB DNS, push lên GitHub.

---

## 🎓 Buổi 14 — Observability (Logs, Metrics, Alarms)

**Mục tiêu**: Hạ tầng có "mắt" để biết khi sự cố xảy ra.

**Đầu ra**:
- [ ] CloudWatch Log Group cho EC2 (CloudWatch Agent qua user-data) và RDS.
- [ ] Retention 7 ngày (tiết kiệm tiền).
- [ ] CloudWatch Alarm: CPU > 80% trong 5 phút.
- [ ] SNS Topic + email subscription nhận alert.
- [ ] Test: stress EC2 (`stress-ng --cpu 2 --timeout 300s` hoặc `dd if=/dev/zero of=/dev/null`) → nhận email cảnh báo.

**Tại sao quan trọng**: DevOps không phải chỉ "deploy được" — phải "biết khi nào hỏng".

---

## 🎓 Buổi 15 — Git Workflow cho DevOps

**Mục tiêu**: Làm việc với Terraform trong team đúng cách.

**Đầu ra**:
- [ ] `.gitignore` chuẩn cho Terraform (`.terraform/`, `*.tfstate*`, `*.tfvars` chứa secret, `crash.log`).
- [ ] Tạo branch `feat/add-bucket`, tạo PR, self-review, merge.
- [ ] Hiểu trunk-based vs GitFlow, biết team Terraform nên dùng cái nào (gợi ý: trunk-based + short-lived branches).
- [ ] Viết PR template có sẵn câu hỏi: "đã chạy `terraform plan` chưa?", "có resource nào destroy/replace không?".
- [ ] Bảo vệ branch `main` (require PR + 1 review).

**Các bước**:
1. Tạo `.gitignore` cho repo Terraform.
2. Tạo file `.github/pull_request_template.md`.
3. Settings → Branches → bảo vệ `main`.
4. Practice: tạo branch, sửa, push, mở PR.

**Quan trọng**:
- TUYỆT ĐỐI KHÔNG commit `terraform.tfstate` (chứa secret).
- TUYỆT ĐỐI KHÔNG commit `*.tfvars` chứa password/key.

---

## 🎓 Buổi 16 — Security & Best Practices

**Mục tiêu**: Code Terraform sạch, an toàn, có CI check trước khi merge.

**Đầu ra**:
- [ ] `tflint`, `tfsec`, `checkov` chạy được trên Project 1.
- [ ] Pre-commit hook tự `terraform fmt` + scan.
- [ ] Sửa hết warning của `tfsec` ở mức HIGH/CRITICAL.
- [ ] Tagging strategy thống nhất (Owner, Env, Project, ManagedBy).
- [ ] IAM least privilege cho Terraform runner (KHÔNG dùng `AdministratorAccess` ở prod).

**Các bước**:
1. `pip install pre-commit`, tạo `.pre-commit-config.yaml`.
2. Chạy `tfsec .`, đọc từng cảnh báo.
3. Fix: bật bucket encryption, restrict SG `0.0.0.0/0`, RDS encrypt at rest, log group retention...

---

## 🎓 Buổi 17 — Terraform Testing

**Mục tiêu**: Test module trước khi tin nó.

**Đầu ra**:
- [ ] Viết file `*.tftest.hcl` test module `s3-bucket`.
- [ ] Test có **plan-only** (không tạo resource) và **apply test** (tạo rồi destroy).
- [ ] Hiểu khi nào dùng `terraform test` native, khi nào cần Terratest (Go).

**Các bước**:
1. Trong module `s3-bucket/tests/`, tạo `defaults.tftest.hcl`.
2. Viết test: gọi module với input mẫu, assert output `bucket_arn` đúng format.
3. Chạy `terraform test`.
4. Test failure case: input không hợp lệ → variable validation chặn.

**Ví dụ tối thiểu**:
```hcl
run "default_bucket" {
  command = plan
  variables {
    name = "test-bucket-123"
  }
  assert {
    condition     = aws_s3_bucket.this.bucket == "test-bucket-123"
    error_message = "Bucket name không khớp"
  }
}
```

---

## 🚀 Project 2 — Serverless API + CI/CD (Buổi 18–20)

> **Kiến trúc**:
> ```
> Client → API Gateway → Lambda (Node.js 22) → DynamoDB
>                            ↓
>                       CloudWatch Logs
>
> GitHub Push → Actions → Plan/Apply (OIDC, no access key)
> ```
>
> **💰 Cost warning**: Project này gần như miễn phí ở mức học (Lambda free tier 1M requests/tháng, DynamoDB on-demand cost rất thấp, API Gateway free 1M requests đầu).

### 🎓 Buổi 18 — Project 2: Lambda + DynamoDB

**Mục tiêu**: Lambda CRUD được DynamoDB.

**Đầu ra**:
- [ ] DynamoDB table `items` (PK = `id`), PAY_PER_REQUEST.
- [ ] Lambda **Node.js 22** (LTS hiện tại — Node 18/20 đã EOL trong 2026), code `src/handler.js` xử lý GET/POST.
- [ ] IAM Role least privilege (chỉ `dynamodb:GetItem/PutItem` table đó).
- [ ] CloudWatch Log Group retention 7 ngày.
- [ ] Test bằng `aws lambda invoke`.

### 🎓 Buổi 19 — Project 2: API Gateway

**Mục tiêu**: Expose Lambda thành REST API public.

**Đầu ra**:
- [ ] API Gateway REST API, resource `/items`, method GET + POST.
- [ ] Integration Lambda Proxy.
- [ ] Stage `dev` deployed.
- [ ] `curl https://<id>.execute-api.<region>.amazonaws.com/dev/items` thành công.

### 🎓 Buổi 20 — Project 2: GitHub Actions CI/CD

**Mục tiêu**: Push code → tự động plan/apply, KHÔNG dùng access key.

**Đầu ra**:
- [ ] OIDC provider GitHub trong AWS IAM.
- [ ] IAM Role `github-actions-deployer` với trust GitHub repo cụ thể (sub claim).
- [ ] `.github/workflows/terraform-plan.yml` chạy trên PR, comment plan vào PR.
- [ ] `.github/workflows/terraform-apply.yml` chạy trên push `main`, deploy dev.
- [ ] Tag `v*` → workflow apply prod (manual approval qua GitHub Environments).

**Checkpoint Project 2**: Mở 1 PR đổi message Lambda → CI plan → merge → CI apply → curl thấy message mới.

---

## 🎓 Buổi 21 — Vận hành, Rollback & Mở rộng

**Mục tiêu**: Sống chung với Terraform trong team thật, biết cứu hoả khi sự cố.

### 21.1 Drift detection & Import

**Đầu ra**:
- [ ] Sửa tag bucket trên Console → `terraform plan` thấy diff.
- [ ] Import 1 resource có sẵn vào state (`terraform import`).

### 21.2 🔥 Rollback Strategies (phần quan trọng nhất)

> Khi `apply` lỗi giữa chừng hoặc apply nhầm, làm gì?

**4 cách rollback theo mức độ nghiêm trọng:**

#### A. Rollback bằng Git (an toàn nhất, ưu tiên)
```bash
git revert <commit-bad>          # revert commit xấu, tạo commit ngược
git push                          # CI/CD tự apply lại version cũ
```
- Phù hợp khi: thay đổi không mất data (config, naming, scaling number).
- Không phù hợp khi: đã `destroy` resource có data (DB, S3 có object).

#### B. State Versioning (S3 versioning của file state)
```bash
# Liệt kê version cũ
aws s3api list-object-versions --bucket <state-bucket> --prefix <key>
# Restore version cũ
aws s3api copy-object --bucket <state-bucket> \
  --copy-source "<state-bucket>/<key>?versionId=<old-version>" \
  --key <key>
terraform plan   # check
terraform apply  # đẩy infra về khớp state cũ
```
- Phù hợp khi: state bị corrupt hoặc apply nhầm, infra thật chưa thay đổi nhiều.

#### C. `terraform taint` / `-replace`
```bash
terraform apply -replace="aws_instance.web"
```
- Phù hợp khi: 1 resource bị "lệch" cần tạo lại.
- Resource sẽ destroy + create. **Mất data nếu là RDS/EBS**.

#### D. Surgical state edit (`state rm` / `import`)
```bash
terraform state rm aws_db_instance.this    # gỡ khỏi state, KHÔNG xoá thật
terraform import aws_db_instance.this <db-identifier>  # import lại
```
- Phù hợp khi: state lệch nhưng infra thật đúng. Tránh destroy nhầm.

#### Quy tắc vàng khi rollback:
- ✅ **Luôn `terraform plan`** trước khi `apply` rollback.
- ✅ **Backup state** trước thao tác state nguy hiểm: `terraform state pull > backup-$(date +%s).tfstate`.
- ✅ **Có data quan trọng** (RDS, S3) → snapshot trước.
- ❌ **KHÔNG** rollback bằng `terraform destroy && apply lại` ở prod.
- ❌ **KHÔNG** sửa file state thủ công nếu chưa hiểu rõ.

#### Phòng ngừa hơn chữa:
- Bật `prevent_destroy = true` cho RDS, S3 quan trọng:
  ```hcl
  resource "aws_db_instance" "main" {
    # ...
    lifecycle {
      prevent_destroy = true
    }
  }
  ```
- CI luôn `plan` ra artifact, người approve đọc plan trước khi `apply`.
- Dùng `deletion_protection = true` cho RDS, ALB, NAT.
- S3 bucket production có MFA Delete + versioning.

### 21.3 Cost & Tooling

**Đầu ra**:
- [ ] Cài `infracost`, ước tính chi phí Project 1.
- [ ] Tìm hiểu Terragrunt / Terraform Cloud / Atlantis (chỉ đọc, chưa cần dùng).

---

## 🧭 Sau khi học xong

Bạn nên tự tin:
1. Setup Terraform mới cho 1 dự án từ đầu (backend, module, multi-env).
2. Review PR Terraform của đồng nghiệp, chỉ ra security issue.
3. Trả lời được câu hỏi phỏng vấn DevOps về IaC, Terraform, rollback strategy.
4. Cứu hoả khi `apply` lỗi ở prod mà không làm tệ thêm.

> 🌟 **Học chậm mà chắc**: chấp nhận xoá đi viết lại — đó là cách hiểu sâu nhất.

---

## 📚 Tham khảo
- [Terraform Docs](https://developer.hashicorp.com/terraform/docs)
- [AWS Provider Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [terraform-aws-modules](https://github.com/terraform-aws-modules)
- [tfsec](https://github.com/aquasecurity/tfsec) · [tflint](https://github.com/terraform-linters/tflint) · [checkov](https://www.checkov.io/) · [infracost](https://www.infracost.io/)
- [Terraform Test docs](https://developer.hashicorp.com/terraform/language/tests)

---

## 📝 License
MIT — dùng tự do cho việc học cá nhân và nội bộ team.
