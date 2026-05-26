# 🎓 Buổi 07 — Modules cơ bản + Registry

> ⏱️ Thời lượng: 2h · 🧰 Yêu cầu: đã xong buổi 06

---

## 🎯 Mục tiêu

- Hiểu **module** là gì, lợi ích của việc đóng gói code.
- Tự viết module `s3-bucket` chuẩn cấu trúc.
- Gọi module nhiều lần với input khác nhau (DRY — Don't Repeat Yourself).
- Biết khi nào nên **tự viết** vs **dùng Registry**.
- Biết cách **pin version** cho module (rất quan trọng!).

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| Module | nhóm resource đóng gói tái dùng được |
| Root module | module bạn `terraform apply` trực tiếp |
| Child module | module được gọi từ root (qua `module "..."` block) |
| Module address | `module.<name>.aws_<type>.<resource_name>` (vd `module.logs.aws_s3_bucket.this`) |
| `source` | đường dẫn module (local `./modules/x` hoặc Registry `terraform-aws-modules/vpc/aws`) |
| Provider inheritance | child module dùng provider từ root, KHÔNG cần khai báo lại |
| Pessimistic version `~> 5.5` | nghĩa là `>= 5.5, < 6.0` |

---

## 📚 Lý thuyết

### Module = "function" của Terraform
Đóng gói 1 nhóm resource thường dùng chung thành 1 unit có **input** (variables) và **output** (outputs). Project gọi module nhiều lần với input khác nhau thay vì copy-paste code.

### Cấu trúc module chuẩn
```
modules/<name>/
├── main.tf        ← resource chính
├── variables.tf   ← input
├── outputs.tf     ← output
├── versions.tf    ← required_providers
└── README.md      ← cách dùng + ví dụ
```

### Khi nào tự viết, khi nào dùng Registry?

| Tự viết khi... | Dùng Registry khi... |
|---|---|
| Logic công ty đặc thù | Vấn đề phổ biến (VPC, EKS, RDS, ALB) |
| Cần kiểm soát mọi chi tiết | Tiết kiệm thời gian |
| Muốn học | Module đã được battle-tested bởi cộng đồng |
| Resource đơn giản (1-3 resource) | Có hàng chục resource liên quan |

> 💡 **Quy tắc**: Đừng "reinvent the wheel" cho VPC, EKS — `terraform-aws-modules` đã làm rất tốt.

### Sơ đồ module call → resource thật

```
Root module (project)              Child module                  AWS API
┌───────────────────────┐          ┌──────────────────────┐
│ module "logs" {       │          │ modules/s3-bucket/   │
│   source = "./..."    │ ────────►│ resource "aws_s3_    │
│   name   = "my-logs"  │          │   bucket" "this" {}  │ ─────► AWS S3
│ }                     │          │                      │
│                       │          │                      │
│ module "assets" {     │ ────────►│ (cùng module, gọi    │
│   source = "./..."    │          │  lần 2)              │ ─────► AWS S3
│   name   = "my-assets"│          │                      │
│ }                     │          │                      │
└───────────────────────┘          └──────────────────────┘
```

Cùng 1 module, gọi 2 lần với input khác nhau → Terraform tạo 2 resource độc lập, có module address khác nhau.

### Module address — gọi resource thuộc module thế nào

Trong root, để tham chiếu resource bên trong module, dùng:

```
module.<module_name>.<resource_type>.<resource_name>
```

Ví dụ:
- `module.logs.aws_s3_bucket.this` → bucket trong module "logs".
- `module.assets.aws_s3_bucket.this` → bucket trong module "assets".

CLI:
```bash
terraform state show 'module.logs.aws_s3_bucket.this'
terraform state list | grep module.logs
```

### Provider inheritance — child module dùng provider từ đâu?

Khi root module có:
```hcl
provider "aws" {
  region = "ap-southeast-1"
}

module "logs" {
  source = "./modules/s3-bucket"
  # KHÔNG có providers = {}
}
```

→ Module `logs` **kế thừa** provider AWS region `ap-southeast-1` từ root.

Vì vậy, file `versions.tf` trong module CHỈ khai báo `required_providers`:
```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
# KHÔNG có provider "aws" {} trong module
```

> 💡 Nếu cần module dùng region/account khác, mới phải override:
> ```hcl
> provider "aws" {
>   alias  = "us"
>   region = "us-east-1"
> }
>
> module "global_cdn" {
>   source    = "./modules/cdn"
>   providers = { aws = aws.us }
> }
> ```

### Pessimistic version constraint — bảng tra cứu

| Cú pháp | Ý nghĩa | Phù hợp khi |
|---|---|---|
| `version = "5.5.1"` | ĐÚNG 5.5.1, không gì khác | Module production cần ổn định tuyệt đối |
| `version = "~> 5.5.1"` | `>= 5.5.1, < 5.6` (chấp nhận patch) | Khuyến nghị mặc định |
| `version = "~> 5.5"` | `>= 5.5, < 6.0` (chấp nhận minor + patch) | Module phổ thông |
| `version = ">= 5.0"` | `>= 5.0` (chấp nhận mọi cái mới) | KHÔNG khuyến nghị, có thể break khi major up |
| (bỏ trống) | Dùng version mới nhất bất kỳ | NEVER trong production |

### Pin version — bắt buộc!
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"   # ← KHÔNG bỏ trống! Module update có thể break code.
  # ...
}
```

---

## 🧭 Các bước thực hành

### Bước 1 — Đọc module `s3-bucket`
Mở `modules/s3-bucket/`, đọc từng file. Chú ý:
- `variables.tf` có `validation` rule cho tên bucket.
- `outputs.tf` chỉ expose những gì cần thiết.
- `versions.tf` khai báo provider, KHÔNG có `provider {}` block (provider được "thừa kế" từ root).

### Bước 2 — Apply root config
```bash
terraform init
terraform plan
terraform apply
```

Kết quả: 2 bucket được tạo:
- `logs-<suffix>`: bật versioning (cho audit log).
- `assets-<suffix>`: KHÔNG versioning (chỉ chứa static asset).

### Bước 3 — Tự thêm bucket thứ 3
Trong `main.tf`, thêm 1 module call mới với tên bucket khác, versioning = false. Apply lại.

### Bước 4 — (Tuỳ chọn) Dùng module Registry
Bỏ comment block `module "vpc"` ở cuối `main.tf` để xem cách gọi module có sẵn từ Registry. **Cẩn thận**: VPC tốn tiền NAT — chỉ đọc code, không apply nếu chưa chuẩn bị tiền.

### Bước 5 — Destroy
```bash
terraform destroy
```

---

## ✅ Đầu ra checklist

- [ ] `modules/s3-bucket/` có đủ 5 file: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`.
- [ ] Root `main.tf` gọi module 2 lần (`logs` versioning, `assets` không).
- [ ] `terraform apply` thành công, 2 bucket xuất hiện trên Console.
- [ ] Output `bucket_arns` in ra ARN của cả 2 bucket.
- [ ] Hiểu cách module nhận input và trả output.
- [ ] Biết cách pin version khi dùng module Registry.

---

## 🧯 Common errors

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `Module not installed` | Quên `terraform init` sau khi thêm module | `terraform init` lại |
| `Invalid value for variable "name"` | Vi phạm validation rule (ví dụ tên có chữ HOA) | Sửa cho đúng pattern |
| `Module source must be a valid module address` | Sai cú pháp `source` (thiếu `./` hay sai path) | Path local phải bắt đầu `./` hoặc `../` |
| Module Registry bị break sau update | Quên `version` constraint | Pin version: `version = "5.5.1"` |

---

## 🤔 Câu hỏi tự ôn

1. Sự khác nhau giữa "root module" và "child module"?
2. Vì sao module thường KHÔNG nên có `provider {}` block bên trong?
3. Khi gọi cùng 1 module 2 lần, Terraform phân biệt resource bằng gì?
4. Pin version module dùng `version = "5.5.1"` (cố định) vs `version = "~> 5.5"` (allow patch) — chọn cái nào và khi nào?
5. Module Registry có miễn phí không? Có tin được 100% không?

---

## 📂 Cấu trúc folder

```
buoi-07-modules/
├── README.md
├── .gitignore
├── main.tf            ← gọi module 2 lần
├── variables.tf
├── outputs.tf
├── versions.tf
└── modules/
    └── s3-bucket/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        └── README.md
```

---

➡️ **Buổi tiếp theo**: [Buổi 08 — Multi-environment](../buoi-08-multi-env/README.md)
