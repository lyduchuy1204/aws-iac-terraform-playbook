# 🎓 Buổi 12 — Project 1: Database (RDS MySQL + Secrets Manager)

> ⏱️ Thời lượng: 2.5h · 🧰 Yêu cầu: đã xong buổi 11

---

## 🧭 Vị trí trong Project 1: **[3/4] — Database**

```
[1/4] Network ─────► [2/4] Compute ─────► [3/4] Database ─────► [4/4] ALB & Finish
                                            ▲ bạn ở đây
```

### 📥 Input từ buổi 10 + 11 (paste vào `terraform.tfvars`)

```hcl
# Từ B10:
vpc_id                  = "vpc-0abc..."
private_subnet_ids      = ["subnet-0abc...", "subnet-0def..."]   # ⚠️ phải ≥ 2 subnet ở 2 AZ KHÁC NHAU (DB Subnet Group yêu cầu)
# Từ B11:
ec2_security_group_id   = "sg-0abc..."   # cho RDS SG inbound 3306 từ EC2
iam_role_name           = "buoi-11-ec2-role"   # để attach inline policy đọc Secrets Manager
```

> ⚠️ **DB Subnet Group cần ≥ 2 subnet ở 2 AZ khác nhau**. Nếu B10 chỉ tạo subnet 1 AZ, RDS apply sẽ fail.

### 📤 Output cho buổi sau

| Output | Buổi 13 (ALB) | Người dùng |
|---|---|---|
| `db_endpoint` | — | EC2 user-data dùng để connect (đã làm sẵn) |
| `secret_arn` | — | Tham chiếu khi cần rotate password |

### ⚠️ Nếu DỪNG học giữa chừng (sau B12)

`destroy` đúng thứ tự ngược: **B12 → B11 → B10**.
```bash
cd buoi-12-project1-database/envs/dev   && terraform destroy
cd ../../buoi-11-project1-compute/envs/dev   && terraform destroy
cd ../../buoi-10-project1-network/envs/dev   && terraform destroy
```

---

## 🎯 Mục tiêu

- RDS MySQL 8.0 chạy ở **private subnet**, encrypt at rest.
- Password sinh tự động bằng `random_password` — KHÔNG hardcode.
- Lưu user/password vào **AWS Secrets Manager** dưới dạng JSON.
- DB Subnet Group + Parameter Group.
- Security Group: chỉ cho phép EC2 SG truy cập port 3306.
- State KHÔNG có plain text password (đã `sensitive = true`).

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| RDS | managed database service của AWS |
| DB Subnet Group | group ≥ 2 subnet ở 2 AZ khác nhau cho RDS |
| Parameter Group | cấu hình MySQL/Postgres |
| `random_password` | resource sinh password an toàn |
| Secrets Manager | dịch vụ lưu secret có rotation tự động |
| Encryption at rest | data lưu trên đĩa được mã hoá |

---

## 💰 Cost warning

> RDS `db.t3.micro` Single-AZ ~$13/tháng. Free Tier 750h cho năm đầu.
> Storage 20GB gp2/gp3 ~$2/tháng.
> NAT từ buổi 10 + EC2 từ buổi 11 vẫn chạy.

---

## 📚 Lý thuyết

### Vì sao Secrets Manager, không phải SSM Parameter Store?
| | Secrets Manager | SSM Parameter Store |
|---|---|---|
| Tự rotate password | ✅ Built-in (RDS, Redshift...) | ❌ Phải tự code Lambda |
| Cost | $0.40/secret/tháng + $0.05/10k API call | Free tier hào phóng |
| Phù hợp | Password DB, API key | Config app thường |

Cho RDS password → **Secrets Manager**.

### Đừng đưa password vào output
```hcl
output "db_password" {
  value     = random_password.db.result
  sensitive = true   # ← bắt buộc, nếu không in ra console khi apply
}
```
State vẫn lưu password ở plain text (đó là bản chất state). Vì vậy **state phải encrypt** (đã làm ở buổi 06) và **không được commit**.

### Cấu trúc secret JSON
```json
{
  "username": "admin",
  "password": "xxxxxxxxxxxx",
  "host": "mydb.xxxxx.ap-southeast-1.rds.amazonaws.com",
  "port": 3306,
  "dbname": "appdb"
}
```
EC2 đọc bằng:
```bash
aws secretsmanager get-secret-value --secret-id <arn> --query SecretString --output text | jq
```

### `prevent_destroy` cho prod
```hcl
lifecycle {
  prevent_destroy = false   # dev: cho destroy
  # prevent_destroy = true  # prod: BẮT BUỘC bật
}
```

---

## 🧭 Các bước thực hành

### Bước 1 — Cấu hình env dev
Lấy `vpc_id`, `private_subnet_ids` từ buổi 10. Lấy `ec2_security_group_id` từ buổi 11. Điền vào `terraform.tfvars`.

### Bước 2 — Apply
```bash
cd envs/dev
terraform init
terraform plan
terraform apply
```

Apply mất ~5-10 phút (RDS lâu).

### Bước 3 — Verify state KHÔNG plain text password
```bash
terraform state pull > /tmp/state.json
grep -i "password" /tmp/state.json
# Password vẫn có trong state nhưng trong field "sensitive_attributes" hoặc encrypted nếu bucket encrypt.
# Quan trọng: KHÔNG được thấy password ở STDOUT khi `terraform apply`.
rm /tmp/state.json
```

### Bước 4 — Verify Secrets Manager
```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw secret_arn) \
  --query SecretString --output text
```

Kết quả là JSON `{username, password, host, port, dbname}`.

### Bước 5 — (Tuỳ chọn) Test từ EC2
SSM vào EC2 buổi 11, cài MySQL client:
```bash
sudo dnf install -y mariadb105
mysql -h <db_host> -u admin -p
```
Password lấy từ Secrets Manager.

### Bước 6 — Destroy
```bash
terraform destroy
```
RDS có thể yêu cầu bỏ `skip_final_snapshot = true` (đã set). Secret có deletion delay 7-30 ngày, để `recovery_window_in_days = 0` cho dev (đã set) → xoá ngay.

---

## ✅ Đầu ra checklist

- [ ] Module `modules/database/` có đủ file.
- [ ] `random_password` length 24, không ký tự đặc biệt RDS không nhận.
- [ ] `aws_secretsmanager_secret` + `aws_secretsmanager_secret_version` lưu JSON đầy đủ.
- [ ] `aws_db_instance` MySQL 8.0, t3.micro, Single-AZ, ở private subnet.
- [ ] `storage_encrypted = true` (encrypt at rest).
- [ ] DB Subnet Group dùng đúng 2 private subnet.
- [ ] DB Parameter Group MySQL 8.0.
- [ ] Security Group inbound 3306 chỉ từ EC2 SG.
- [ ] `terraform apply` STDOUT KHÔNG in password ra.
- [ ] Output `secret_arn` xuất hiện, `db_password` là sensitive.
- [ ] `prevent_destroy = false` cho dev, có comment "= true cho prod".

---

## 🧯 Common errors

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `InvalidParameterValue: master password contains invalid character` | Password có `/`, `@`, `"`, space | `override_special` trong `random_password` loại các ký tự này |
| RDS không lên trong 5 phút | Bình thường, RDS lâu | Chờ ~10 phút |
| `DBSubnetGroupRequiresMoreSubnets` | Subnet group < 2 AZ | Phải đủ 2 subnet ở 2 AZ khác nhau |
| `Cannot delete: Final snapshot...` | Quên `skip_final_snapshot = true` | Đã set trong module |
| EC2 không connect được DB | Port 3306 chưa mở từ EC2 SG | Check `aws_security_group_rule` ingress |

---

## 🤔 Câu hỏi tự ôn

1. Vì sao password phải sinh trong Terraform mà không nhập tay qua tfvars?
2. State có plain text password — vậy bảo mật như thế nào?
3. Single-AZ vs Multi-AZ: chọn cái nào cho dev, cho prod?
4. Tại sao DB phải ở **private** subnet?
5. Secret rotation hoạt động ra sao? (Đọc thêm Secrets Manager docs).
6. `recovery_window_in_days = 0` nghĩa là gì? Có nguy hiểm không?

---

## 📂 Cấu trúc folder

```
buoi-12-project1-database/
├── README.md
├── .gitignore
├── modules/
│   └── database/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── README.md
└── envs/
    └── dev/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        ├── backend.tf
        └── terraform.tfvars.example
```
