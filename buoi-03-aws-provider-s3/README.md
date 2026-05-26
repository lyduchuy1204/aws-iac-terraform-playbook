# 🎓 Buổi 03 — AWS Provider & S3 Bucket đầu tiên

> **Thời lượng**: ~1.5 giờ · **Loại**: Hands-on AWS · **Code thực hành**: ✅

---

## 🎯 Mục tiêu

- Tạo resource AWS thật bằng Terraform: 1 S3 bucket có tag và tên unique.
- Hiểu **version pinning** cho Terraform core và provider.
- Hiểu vai trò của **`.terraform.lock.hcl`** (lock file) và vì sao **phải commit** vào Git.
- Quen với pattern `random_id` để tạo tên unique global (S3 bucket name yêu cầu unique trên toàn thế giới).

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| AWS Provider | Plugin gọi AWS API |
| Pessimistic constraint `~> 5.0` | Cho phép 5.x bất kỳ, KHÔNG cho 6.0 |
| `.terraform.lock.hcl` | Pin chính xác version + hash provider, PHẢI commit |
| `random_id` | Resource sinh giá trị ngẫu nhiên ổn định trong state |
| `default_tags` | Tag áp tự động lên mọi resource hỗ trợ |
| forces replacement | Như B02, ví dụ `bucket` name của S3 |

---

## 📚 Lý thuyết tóm tắt

- **AWS provider** (`hashicorp/aws`) là plugin Terraform gọi API AWS. Cần khai báo `region` và để nó tự đọc credential (AWS CLI profile, env var, IAM Role).
- **Version pinning**:
  - `required_version = ">= 1.11"` — Terraform core.
  - `version = "~> 5.0"` — chấp nhận 5.x (5.0, 5.1, ..., 5.99) nhưng KHÔNG lên 6.x. Đây là **pessimistic constraint operator**.
- **Lock file** (`.terraform.lock.hcl`): sinh ra sau `terraform init`, pin chính xác version + checksum của provider. **Phải commit** để mọi máy/CI dùng đúng 1 phiên bản.
- **S3 bucket name** phải **unique global**. Pattern phổ biến: prefix + suffix random (`random_id` của provider `hashicorp/random`).
- **Tagging** là best practice: mỗi resource gắn ít nhất `Project`, `Environment`, `ManagedBy = "Terraform"`. Sau này cost report theo tag được.

---

## 🛠️ Các bước thực hành chi tiết

### Bước 1 — Verify AWS credential

```bash
aws sts get-caller-identity
```

Phải trả về Account ID và ARN của user `terraform-learner` (đã setup ở buổi 00). Nếu chưa, quay lại buổi 00.

### Bước 2 — Vào folder buổi 03

```bash
cd buoi-03-aws-provider-s3
ls
```

Bạn sẽ thấy: `versions.tf`, `main.tf`, `.gitignore`.

### Bước 3 — Đọc kỹ `versions.tf`

Chú ý:
- `terraform >= 1.11`.
- 2 provider: `aws ~> 5.0` và `random ~> 3.5`.

### Bước 4 — `terraform init`

```bash
terraform init
```

Output mong đợi:

```
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Finding hashicorp/random versions matching "~> 3.5"...
- Installing hashicorp/aws v5.x.x...
- Installing hashicorp/random v3.x.x...
Terraform has been successfully initialized!
```

### Bước 5 — Đọc lock file

```bash
cat .terraform.lock.hcl
```

Bạn sẽ thấy nội dung kiểu:

```hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.xx.x"
  constraints = "~> 5.0"
  hashes = [
    "h1:...",
    ...
  ]
}
```

> File này pin checksum để tránh "supply chain attack" — nếu provider trên registry bị thay nội dung, lock file sẽ phát hiện qua hash mismatch.

### Bước 6 — `terraform plan`

```bash
terraform plan
```

> 📌 **Vì sao S3 lại là 4 resource riêng biệt?**
> Từ AWS provider 4.x, `aws_s3_bucket` chỉ là "khung sườn" của bucket. Mỗi tính năng (versioning, encryption, public access block, lifecycle, logging…) tách thành **resource riêng** để dễ quản lý độc lập. Vì vậy `main.tf` của buổi này có 4 resource:
> 1. `random_id.bucket_suffix` — sinh suffix unique.
> 2. `aws_s3_bucket.demo` — bucket chính.
> 3. `aws_s3_bucket_versioning.demo` — bật versioning.
> 4. `aws_s3_bucket_public_access_block.demo` — chặn public access.

Output (rút gọn):

```
Terraform will perform the following actions:

  # random_id.bucket_suffix will be created
  + resource "random_id" "bucket_suffix" {
      + byte_length = 4
      + ...
    }

  # aws_s3_bucket.demo will be created
  + resource "aws_s3_bucket" "demo" {
      + bucket = (known after apply)
      + tags_all = {
          + "Environment" = "learning"
          + "ManagedBy"   = "Terraform"   # từ default_tags
          + "Name"        = "tf-playbook-demo"
          + "Project"     = "aws-iac-terraform-playbook"  # từ default_tags
        }
      ...
    }

  # aws_s3_bucket_versioning.demo will be created
  + resource "aws_s3_bucket_versioning" "demo" {
      + bucket = (known after apply)
      + versioning_configuration {
          + status = "Enabled"
        }
    }

  # aws_s3_bucket_public_access_block.demo will be created
  + resource "aws_s3_bucket_public_access_block" "demo" {
      + block_public_acls       = true
      + block_public_policy     = true
      + ignore_public_acls      = true
      + restrict_public_buckets = true
      ...
    }

Plan: 4 to add, 0 to change, 0 to destroy.
```

> 💡 **Quan sát kỹ `tags_all`**: bạn sẽ thấy có cả tag từ resource (`Name`, `Environment`) và tag từ `default_tags` của provider (`Project`, `ManagedBy`). Terraform tự **merge** 2 nguồn này lại.

### Bước 7 — `terraform apply`

```bash
terraform apply
```

Gõ `yes`. Sau khi xong, bạn thấy output:

```
bucket_arn  = "arn:aws:s3:::tf-playbook-demo-a1b2c3d4"
bucket_name = "tf-playbook-demo-a1b2c3d4"
```

### Bước 8 — Verify trên Console

Lệnh đa OS dùng JMESPath query của AWS CLI (chạy được cả Windows / macOS / Linux):

```bash
aws s3api list-buckets --query "Buckets[?starts_with(Name, 'tf-playbook-demo')].Name" --output text
```

Hoặc nếu bạn ở **Linux/macOS**:

```bash
aws s3 ls | grep tf-playbook-demo
```

Hoặc **Windows PowerShell**:

```powershell
aws s3 ls | Select-String tf-playbook-demo
```

Hoặc vào AWS Console → **S3** → tìm bucket có tên prefix `tf-playbook-demo-` → kiểm tra tab **Properties** thấy tag.

### Bước 9 — Thử modify tag, plan lại

Mở `main.tf`, thêm tag mới `Owner = "your-name"`.

```bash
terraform plan
```

Output mong đợi:

```
  ~ resource "aws_s3_bucket" "demo" {
        id   = "tf-playbook-demo-a1b2c3d4"
      ~ tags = {
          + "Owner"       = "your-name"
            # (3 unchanged elements hidden)
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

> Tag là attribute **in-place updateable** — không phải replace.

### Bước 9.5 — (Optional) Thử đổi `bucket` name → quan sát replace

Đổi prefix `tf-playbook-demo-` thành `tf-playbook-test-` trong `main.tf`:

```bash
terraform plan
```

Output mong đợi sẽ có dấu `-/+` (destroy + create):

```
-/+ resource "aws_s3_bucket" "demo" {
      ~ bucket   = "tf-playbook-demo-a1b2c3d4" -> "tf-playbook-test-a1b2c3d4" # forces replacement
      ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

> 🔴 **`bucket` name là attribute "forces replacement"** — đổi tên = phá bucket cũ + tạo bucket mới. Nếu bucket có data, **mất hết data**. Đây là lý do production hiếm khi đổi tên bucket.

**Revert** lại để không thực sự apply replacement:

```bash
# Sửa main.tf về tên cũ
terraform plan   # phải hiện No changes
```

### Bước 9.6 — `force_destroy` (nếu bucket có object)

Hiện bucket trống nên `destroy` được. Nếu bucket có object, AWS chặn destroy với lỗi `BucketNotEmpty`. Cách xử lý ở Terraform:

```hcl
resource "aws_s3_bucket" "demo" {
  bucket        = "..."
  force_destroy = true   # ⚠️ Cho phép Terraform xoá bucket cùng tất cả object bên trong
  # ...
}
```

> ⚠️ **CHỈ dùng `force_destroy = true` ở môi trường dev/test**. Ở prod, đây là cú "click chuột huỷ diệt data" — tuyệt đối không.

### Bước 10 — `terraform destroy`

> 💰 S3 bucket trống không tốn tiền lưu trữ, nhưng vẫn nên destroy để giữ account sạch.

```bash
terraform destroy
```

Gõ `yes`. Verify:

```bash
aws s3 ls | grep tf-playbook-demo   # không còn output
```

---

## ✅ Đầu ra checklist

- [ ] `terraform init` tải được provider `aws` và `random`.
- [ ] File `.terraform.lock.hcl` xuất hiện và đã được commit (`git status` thấy nó tracked).
- [ ] `terraform apply` tạo được bucket trên AWS.
- [ ] `aws s3 ls` thấy bucket.
- [ ] Console thấy 3 tag: `Project`, `Environment`, `ManagedBy`.
- [ ] `terraform destroy` xoá sạch bucket.
- [ ] Trả lời được: vì sao phải commit lock file?

---

## 🐛 Common errors

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `BucketAlreadyExists` | Tên S3 unique global, ai đó đã dùng | Random suffix đủ dài (4 byte = 8 ký tự hex), hoặc thay prefix |
| `AccessDenied: not authorized to perform s3:CreateBucket` | IAM user thiếu quyền | Gắn `AdministratorAccess` cho user `terraform-learner` |
| `NoCredentialProviders` / `Unable to locate credentials` | Chưa `aws configure` | Quay lại buổi 00 |
| `InvalidLocationConstraint` | Region trong code khác `us-east-1` không khớp với cấu hình | Dùng `region = "ap-southeast-1"` đồng nhất |
| `Failed to query available provider packages` | Network chặn registry | Set proxy hoặc dùng `TF_PLUGIN_CACHE_DIR` |
| `BucketNotEmpty` khi destroy | Bucket có object | Demo này không upload object nên không gặp; nếu có, phải `aws s3 rm s3://... --recursive` trước |

---

## ❓ Câu hỏi tự ôn

1. Pessimistic constraint `~> 5.0` cho phép version 5.99 không? Có cho phép 6.0 không?
2. Vì sao `.terraform.lock.hcl` phải commit nhưng `.terraform/` thì KHÔNG?
3. Thuộc tính nào của `aws_s3_bucket` sẽ **forces replacement** nếu đổi (gợi ý: `bucket` name)? Vì sao?
4. `random_id` có giữ nguyên giá trị qua các lần `apply` không? Nếu xoá state thì sao?
5. Nếu 1 đồng đội gõ `terraform init` mà chưa commit lock file, họ có thể cài provider phiên bản khác bạn không? Hậu quả là gì?

---

## 📚 Tham khảo

- [AWS Provider Docs — aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Random Provider — random_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id)
- [Lock file documentation](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

➡️ **Buổi tiếp theo**: [Buổi 04 — Variables, Outputs, Locals, tfvars](../buoi-04-variables-outputs/README.md)
