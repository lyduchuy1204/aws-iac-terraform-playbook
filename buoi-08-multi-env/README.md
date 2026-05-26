# 🎓 Buổi 08 — Multi-environment (dev/prod)

> ⏱️ Thời lượng: 2h · 🧰 Yêu cầu: đã xong buổi 06 (remote state) + 07 (modules)

---

## 🎯 Mục tiêu

- Tổ chức folder để **dev** và **prod** không apply nhầm nhau.
- Mỗi env có **backend state riêng** (key khác nhau trên cùng bucket).
- Chia sẻ **cùng 1 module** giữa các env, chỉ thay đổi input.
- Hiểu vì sao KHÔNG nên dùng `terraform workspace` cho prod.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| Multi-env | nhiều môi trường (dev/staging/prod) cho cùng 1 hệ thống |
| Folder-per-env | pattern `envs/dev/`, `envs/prod/` dùng chung `modules/` |
| Workspace | cơ chế Terraform tách state, KHÔNG nên dùng cho prod |
| Backend key | path lưu state trên S3, mỗi env có key riêng |
| Promote | chuyển code từ env thấp lên env cao (dev → staging → prod) |

---

## 📚 Lý thuyết

### 2 pattern phổ biến

| | Folder-per-env (khuyến nghị) | Workspace |
|---|---|---|
| Cấu trúc | `envs/dev/`, `envs/prod/` | 1 folder, nhiều workspace |
| State | File state riêng từng env | 1 backend, key có suffix workspace |
| Provider/backend khác nhau? | ✅ Được | ❌ Không (cùng 1 backend config) |
| Đọc code dễ? | ✅ Rõ ràng | ❌ Phải nhớ đang ở workspace nào |
| Risk apply nhầm | Thấp | Cao (gõ nhầm `workspace select`) |

> 📌 **HashiCorp khuyến nghị folder-per-env cho production**. Workspace chỉ phù hợp cho feature branch tạm thời.

### Sơ đồ: 2 env trên CÙNG bucket state, KEY khác nhau

```
┌────────────────────────────────────────────────────────┐
│  S3 bucket: tfstate-123456789012-apse1                 │
│                                                        │
│  ├── envs/dev/terraform.tfstate                        │
│  │     ◄────── envs/dev/  apply ghi vào đây            │
│  │                                                     │
│  └── envs/prod/terraform.tfstate                       │
│        ◄────── envs/prod/  apply ghi vào đây           │
└────────────────────────────────────────────────────────┘
                  ▲                        ▲
                  │                        │
       ┌──────────┴────────┐      ┌────────┴──────────┐
       │  envs/dev/        │      │  envs/prod/        │
       │  ├── main.tf       │      │  ├── main.tf       │
       │  ├── backend.tf    │      │  ├── backend.tf    │
       │  │   key=envs/dev/ │      │  │   key=envs/prod/│
       │  └── tfvars        │      │  └── tfvars        │
       └────────────────────┘      └────────────────────┘
                  │                        │
                  ▼                        ▼
       ┌──────────────────────────────────────┐
       │  modules/  (DÙNG CHUNG cho cả 2 env) │
       └──────────────────────────────────────┘
```

Lợi ích pattern này:
- Module = code DRY, 1 chỗ sửa, 2 nơi hưởng.
- State tách biệt → apply nhầm dev không ảnh hưởng prod.
- Backend key khác nhau → lock độc lập, 2 dev có thể work song song 2 env.

### Cấu trúc khuyến nghị
```
buoi-08-multi-env/
├── modules/                    ← code dùng chung
│   └── s3-bucket/
└── envs/
    ├── dev/                    ← env riêng, backend riêng
    │   ├── main.tf
    │   ├── backend.tf          ← key = envs/dev/terraform.tfstate
    │   ├── terraform.tfvars.example
    │   └── versions.tf
    └── prod/                   ← env riêng, backend riêng
        ├── main.tf
        ├── backend.tf          ← key = envs/prod/terraform.tfstate
        ├── terraform.tfvars.example
        └── versions.tf
```

### Nguyên tắc tách dev/prod
- **Khác account** càng tốt (cô lập blast radius).
- Nếu cùng account: phải khác **region** hoặc khác **resource name prefix**.
- Backend state: **KEY KHÁC NHAU** (hoặc bucket khác).
- IAM role chạy Terraform cho prod phải **least privilege**, không full admin.

---

## 🧭 Các bước thực hành

### Bước 1 — Chuẩn bị backend
Đã có bucket state từ buổi 06. Mở `envs/dev/backend.tf` và `envs/prod/backend.tf`, thay `<YOUR_BUCKET_NAME>` bằng tên bucket thật.

### Bước 2 — Apply env dev
```bash
cd envs/dev
cp terraform.tfvars.example terraform.tfvars   # rồi chỉnh lại
terraform init
terraform plan
terraform apply
```

State sẽ được lưu tại `s3://<bucket>/envs/dev/terraform.tfstate`.

### Bước 3 — Apply env prod (giả lập)
```bash
cd ../prod
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply   # dev xong hãy thử prod, hoặc skip để tiết kiệm
```

State tại `s3://<bucket>/envs/prod/terraform.tfstate`.

### Bước 4 — Thử apply nhầm
Vào `envs/dev/`, thử đổi 1 variable. Plan ra. Để ý: KHÔNG có resource prod nào trong plan → an toàn.

### Bước 5 — Destroy
```bash
cd envs/dev && terraform destroy
cd ../prod && terraform destroy
```

---

## ✅ Đầu ra checklist

- [ ] Folder `modules/s3-bucket/` chứa code dùng chung (giống buổi 07).
- [ ] `envs/dev/` và `envs/prod/` có cấu trúc giống nhau, chỉ khác giá trị tfvars.
- [ ] Mỗi env có `backend.tf` với **key khác nhau**.
- [ ] `terraform plan` ở dev KHÔNG đụng resource prod.
- [ ] dev bucket name khác prod bucket name.
- [ ] (Tuỳ chọn) prod có tag `Env = prod`, dev có `Env = dev`.

---

## 🧯 Common errors

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| Apply nhầm env | Quên `cd envs/<env>` | Luôn check `pwd` trước apply, hoặc dùng `terraform -chdir=envs/dev plan` |
| State trống bất ngờ | Backend key sai → đè state | Backup state trước khi đổi backend! |
| Resource conflict tên | Cả 2 env dùng cùng tên bucket | Prefix theo env: `app-dev-bucket`, `app-prod-bucket` |
| `terraform.tfvars` bị commit | Không có `.gitignore` chuẩn | `.gitignore` đã có sẵn trong buổi này |

---

## 🚀 Promote dev → prod (best practice)

Khi feature đã chạy ổn ở dev, đẩy lên prod theo 3 bước:

### Bước 1 — Diff `terraform.tfvars` giữa 2 env
```bash
diff envs/dev/terraform.tfvars envs/prod/terraform.tfvars
```
Phải có khác biệt rõ ràng: bucket name khác, region có thể khác, instance size lớn hơn ở prod...

### Bước 2 — Pin version module trước khi apply prod
Nếu module dùng từ Registry, ép version cố định:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"   # KHÔNG dùng ~> ở prod
}
```

### Bước 3 — Plan, review, approve, apply
```bash
cd envs/prod
terraform plan -out=prod.tfplan
terraform show -no-color prod.tfplan > prod-plan.txt   # đính kèm PR
# → Reviewer đọc prod-plan.txt → approve PR
terraform apply prod.tfplan
```

> ⚠️ **NEVER**:
> - Apply prod trước khi dev chạy ổn ≥ 24h.
> - Skip review plan, `apply -auto-approve` ở prod.
> - Promote khi có resource bị `replace` mà chưa hỏi data owner.

---

## 🤔 Câu hỏi tự ôn

1. Vì sao folder-per-env an toàn hơn workspace cho production?
2. Nếu dev và prod cùng account, làm sao tránh tạo nhầm tài nguyên prod?
3. State của 2 env có nên ở 2 bucket riêng không? (Hint: lý tưởng là ở 2 account riêng).
4. Khi promote code dev → prod, làm sao đảm bảo "cùng version module"?
5. Có nên copy `terraform.tfvars` từ dev sang prod không? (Trả lời: KHÔNG — mỗi env có config riêng).

---

## 📂 Cấu trúc folder

```
buoi-08-multi-env/
├── README.md
├── .gitignore
├── modules/
│   └── s3-bucket/   ← copy nguyên si từ buổi 07
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── README.md
└── envs/
    ├── dev/
    │   ├── main.tf
    │   ├── backend.tf
    │   ├── terraform.tfvars.example
    │   └── versions.tf
    └── prod/
        ├── main.tf
        ├── backend.tf
        ├── terraform.tfvars.example
        └── versions.tf
```

---

➡️ **Buổi tiếp theo**: [Buổi 09 — count, for_each, dynamic](../buoi-09-loops-dynamic/README.md)
