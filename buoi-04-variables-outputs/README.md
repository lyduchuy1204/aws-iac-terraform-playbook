# 🎓 Buổi 04 — Variables, Outputs, Locals, tfvars

> **Thời lượng**: ~2 giờ · **Loại**: Hands-on AWS · **Code thực hành**: ✅

---

## 🎯 Mục tiêu

- Refactor code buổi 03 để **tách giá trị cứng** ra khỏi `main.tf`.
- Khai báo `variable` có `type` và `validation`.
- Dùng `locals` để compose tag mặc định và giá trị tính toán.
- Dùng `output` để in giá trị ra sau apply (sẽ dùng cho buổi 05+).
- Truyền giá trị qua `terraform.tfvars` và `-var` flag.
- Hiểu **thứ tự ưu tiên** khi nhiều nguồn cùng set 1 variable.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| Variable | Input từ ngoài |
| Output | Giá trị in ra sau apply |
| Locals | Biến tạm trong module |
| `terraform.tfvars` | File mặc định Terraform tự đọc |
| `*.auto.tfvars` | File Terraform cũng tự đọc |
| Validation rule | `validation { condition, error_message }` trong variable |
| `sensitive = true` | Ẩn giá trị khỏi output console (vẫn lưu plain text trong state) |

---

## 📚 Lý thuyết tóm tắt

- **`variable`**: input của module/root module. Có `type`, `default`, `description`, `validation`, `sensitive`.
- **`locals`**: biến tạm trong scope module. Tính 1 lần, dùng nhiều nơi. KHÔNG nhận input từ ngoài.
- **`output`**: giá trị trả ra sau apply, hoặc expose ra cho module cha.
- **`terraform.tfvars`**: file mặc định Terraform tự đọc. Đặt giá trị thật cho variable.
- **`*.auto.tfvars`**: cũng được tự đọc, theo thứ tự alphabet.
- **Thứ tự ưu tiên** (cao → thấp):
  1. `-var` / `-var-file` trên CLI
  2. `*.auto.tfvars` (alphabet)
  3. `terraform.tfvars`
  4. Env: `TF_VAR_<name>`
  5. Default trong khai báo `variable`

> ⚠️ **KHÔNG commit `terraform.tfvars`** vào Git — chỉ commit `terraform.tfvars.example`.

### `sensitive = true` — ẩn giá trị output, không phải mã hoá

Ví dụ:
```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

output "db_password" {
  value     = var.db_password
  sensitive = true
}
```

**Hành vi**:
- ✅ `terraform plan/apply` console KHÔNG in giá trị (in `<sensitive>`).
- ✅ Trace log không lộ giá trị (trừ khi bạn set `TF_LOG=trace`).
- ❌ **State file VẪN lưu plain text**. Bất kỳ ai đọc `.tfstate` đều thấy.
- ❌ KHÔNG mã hoá giá trị trên S3 (chỉ encryption-at-rest của S3).

**Hệ quả**: `sensitive = true` chỉ ngăn lộ qua **terminal/log**, KHÔNG đủ để bảo vệ secret. Secret thật phải:
- Lưu ở Secrets Manager / SSM Parameter Store (buổi 12).
- Backend state phải bật encryption + block public access (buổi 06).
- Restrict IAM ai đọc được state bucket.

---

## 🛠️ Các bước thực hành chi tiết

### Bước 1 — Vào folder và xem cấu trúc

```bash
cd buoi-04-variables-outputs
ls
```

Bạn thấy: `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `terraform.tfvars.example`, `.gitignore`.

### Bước 2 — Tạo `terraform.tfvars` từ example

```bash
# Windows PowerShell
Copy-Item terraform.tfvars.example terraform.tfvars

# macOS/Linux
cp terraform.tfvars.example terraform.tfvars
```

Mở `terraform.tfvars`, sửa giá trị `bucket_name_prefix` thành prefix của bạn (ví dụ `lyduc-demo`).

### Bước 3 — `terraform init` + `plan`

```bash
terraform init
terraform plan
```

Quan sát output: prefix bucket lấy từ `terraform.tfvars`, tag merge giữa `default_tags` (provider) và `local.common_tags` + tag riêng của resource.

### Bước 4 — Test validation

Mở `terraform.tfvars`, đổi `environment = "production"` thành `environment = "PROD"` (chữ hoa). Plan lại:

```bash
terraform plan
```

Bạn sẽ thấy lỗi:

```
Error: Invalid value for variable

  on terraform.tfvars line 2:
   2: environment = "PROD"

Environment phải là một trong: dev, staging, prod, learning.
```

> ✅ Validation hoạt động. Đổi lại `environment = "learning"` để tiếp tục.

### Bước 5 — Test override bằng `-var`

```bash
terraform plan -var="environment=dev"
```

Bucket vẫn đúng prefix (từ tfvars), nhưng tag `Environment` = `dev` (override).

### Bước 6 — Test override bằng env var

```bash
# Linux/macOS
export TF_VAR_environment=staging
terraform plan

# Windows PowerShell
$env:TF_VAR_environment = "staging"
terraform plan
```

Tag `Environment` = `staging`. Sau đó unset:

```bash
unset TF_VAR_environment           # Linux/macOS
Remove-Item Env:TF_VAR_environment  # PowerShell
```

### Bước 7 — Apply

```bash
terraform apply
```

Sau khi xong, output mong đợi:

```
bucket_arn         = "arn:aws:s3:::lyduc-demo-a1b2c3d4"
bucket_name        = "lyduc-demo-a1b2c3d4"
bucket_region      = "ap-southeast-1"
common_tags_applied = {
  "Environment" = "learning"
  "ManagedBy"   = "Terraform"
  "Owner"       = "lyduc"
  "Project"     = "aws-iac-terraform-playbook"
}
```

### Bước 8 — Verify trên Console

```bash
aws s3api get-bucket-tagging --bucket <bucket_name>
```

### Bước 9 — `terraform destroy`

```bash
terraform destroy
```

---

## ✅ Đầu ra checklist

- [ ] `variables.tf` có ít nhất 1 variable với `validation` block.
- [ ] `terraform.tfvars` được tạo từ `.example` và **KHÔNG commit** vào Git (verify: `git status --ignored`).
- [ ] `locals` compose tag chung cho mọi resource.
- [ ] `outputs.tf` in ra ARN, name, region và tag áp dụng.
- [ ] Test được override bằng `-var` và `TF_VAR_*`.
- [ ] Bucket tạo thành công, tag đúng giá trị từ tfvars.
- [ ] `terraform destroy` xoá sạch.

---

## 🐛 Common errors

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `Error: Invalid value for variable` | Validation fail | Sửa giá trị tfvars cho khớp `validation.condition` |
| `Error: Reference to undeclared input variable` | Dùng `var.foo` mà chưa khai báo trong `variables.tf` | Thêm khai báo |
| Variable không nhận giá trị từ tfvars | File tên sai (phải là `terraform.tfvars` hoặc `*.auto.tfvars`) | Rename hoặc dùng `-var-file` |
| Tag bị override không đúng ý | `default_tags` của provider merge với `tags` của resource — resource tag thắng | Đọc kỹ thứ tự merge |
| `terraform.tfvars` lỡ commit | Lock đặt sau, file đã trong history | `git rm --cached terraform.tfvars`, rotate secret nếu có |

---

## ❓ Câu hỏi tự ôn

1. Thứ tự ưu tiên giữa: `terraform.tfvars`, `-var` CLI, `TF_VAR_*` env, default — cái nào thắng?
2. Khác biệt giữa `variable` và `locals`? Khi nào dùng cái nào?
3. Variable có `sensitive = true` thì khác gì variable thường? Nó có lưu vào state plain text không?
4. Vì sao `terraform.tfvars` KHÔNG được commit nhưng `terraform.tfvars.example` thì NÊN commit?
5. `default_tags` ở provider và `tags` ở resource — nếu trùng key, cái nào thắng?

---

## 📚 Tham khảo

- [Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [Local Values](https://developer.hashicorp.com/terraform/language/values/locals)
- [Output Values](https://developer.hashicorp.com/terraform/language/values/outputs)
- [Variable Validation](https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules)

➡️ **Buổi tiếp theo**: [Buổi 05 — Data Sources & Dependencies](../buoi-05-data-sources/README.md)
