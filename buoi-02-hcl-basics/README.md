# 🎓 Buổi 02 — HCL Syntax cơ bản

> **Thời lượng**: ~1.5 giờ · **Loại**: Hands-on local (chưa cần AWS) · **Code thực hành**: ✅

---

## 🎯 Mục tiêu

- Viết và chạy được file `.tf` đầu tiên với provider `local` (chưa đụng AWS).
- Hiểu các block cốt lõi: `terraform`, `provider`, `resource`, `variable`, `output`, `locals`.
- Phân biệt kiểu dữ liệu HCL: `string` / `number` / `bool` / `list` / `map` / `object` / `set`.
- Quan sát hành vi `init` / `plan` / `apply` / `destroy` trên 1 resource đơn giản.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| HCL | HashiCorp Configuration Language |
| Block | Cấu trúc `type "label" { ... }` trong HCL |
| Resource | Cái Terraform tạo/quản lý |
| Data source | Cái Terraform chỉ đọc, không tạo |
| Variable / Output / Local | Input / output / biến tạm trong module |
| `path.module` | Đường dẫn folder chứa module hiện tại |
| forces replacement | Attribute mà khi đổi sẽ destroy + create lại resource |

---

## 📚 Lý thuyết tóm tắt

HCL (HashiCorp Configuration Language) gồm các **block** dạng:

```hcl
block_type "label_1" "label_2" {
  attribute_1 = value
  nested_block {
    ...
  }
}
```

Các block thường gặp:

- **`terraform { ... }`**: cấu hình bản thân Terraform (version, provider, backend).
- **`provider "aws" { ... }`**: cấu hình một plugin (region, credential).
- **`resource "TYPE" "NAME" { ... }`**: khai báo 1 resource (cái Terraform tạo ra).
- **`data "TYPE" "NAME" { ... }`**: query resource đã có (read-only).
- **`variable "NAME" { ... }`**: input có thể truyền từ ngoài.
- **`output "NAME" { ... }`**: giá trị in ra sau apply.
- **`locals { ... }`**: biến tạm trong module.

**Kiểu dữ liệu** (sẽ học sâu ở buổi 04):

| Kiểu | Ví dụ |
|---|---|
| string | `"hello"` |
| number | `42`, `3.14` |
| bool | `true`, `false` |
| list/tuple | `["a", "b", "c"]` |
| map/object | `{ name = "alice", age = 30 }` |
| set | `toset(["a", "b"])` (không trùng, không thứ tự) |

### "Forces replacement" — khi nào Terraform destroy + create lại

Khi sửa attribute của resource, có 2 hành vi:

| Hành vi | Ý nghĩa | Có mất data? |
|---|---|---|
| **In-place update** | Terraform gọi API update tại chỗ | ❌ Không |
| **Forces replacement** | Terraform destroy resource cũ + tạo cái mới | ⚠️ Có thể (tuỳ resource) |

Tài liệu provider mỗi attribute đều ghi rõ: "Forces new resource if changed" hoặc không. Ví dụ:
- `aws_s3_bucket.bucket` (tên bucket) → forces replacement.
- `aws_s3_bucket.tags` → in-place.
- `aws_db_instance.engine_version` → có thể replace, có thể in-place tuỳ minor/major.

Trong `plan` output, Terraform báo bằng dấu:
- `~` resource: in-place update (an toàn).
- `-/+` resource: replace (chú ý, có thể mất data).
- `+/-` resource (lifecycle `create_before_destroy`): tạo trước, destroy sau (giảm downtime).

**Quy tắc**: thấy `-/+` ở `plan` → DỪNG, đọc kỹ, hỏi team trước khi `apply` ở prod.

---

## 🛠️ Các bước thực hành chi tiết

### Bước 1 — Vào folder buổi 02

```bash
cd buoi-02-hcl-basics
ls
```

Bạn sẽ thấy các file đã có sẵn: `versions.tf`, `main.tf`, `.gitignore`.

### Bước 2 — Đọc kỹ code

Mở `versions.tf` và `main.tf` xem cấu trúc:
- `versions.tf` pin Terraform >= 1.11 và provider `local ~> 2.5`.
- `main.tf` dùng `local_file` để tạo file `hello.txt` ở cùng folder.

### Bước 3 — `terraform init`

```bash
terraform init
```

Output mong đợi:

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/local versions matching "~> 2.5"...
- Installing hashicorp/local v2.5.x...
- Installed hashicorp/local v2.5.x (signed by HashiCorp)
Terraform has been successfully initialized!
```

> Sau lệnh này, folder `.terraform/` và file `.terraform.lock.hcl` được tạo.

### Bước 4 — `terraform plan`

```bash
terraform plan
```

Output mong đợi (rút gọn):

```
Terraform will perform the following actions:

  # local_file.hello will be created
  + resource "local_file" "hello" {
      + content              = "Hello Terraform! Đây là file đầu tiên do Terraform tạo.\n"
      + filename             = "./hello.txt"
      + ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

### Bước 5 — `terraform apply`

```bash
terraform apply
```

Gõ `yes` để confirm. Sau khi xong, kiểm tra:

```bash
cat hello.txt
ls terraform.tfstate
```

> File `hello.txt` đã được tạo. File `terraform.tfstate` xuất hiện — đây là **state**.

### Bước 6 — Quan sát state

```bash
terraform show
```

Hoặc xem raw:

```bash
cat terraform.tfstate
```

Bạn sẽ thấy resource đã được track, kèm `id`, `content_md5`, `permissions`, v.v.

### Bước 7 — Sửa code, apply lại

Mở `main.tf`, đổi nội dung `content` thành `"Hello Terraform! (lần 2)\n"`. Save file.

```bash
terraform plan
```

Output mong đợi:

```
  # local_file.hello must be replaced
-/+ resource "local_file" "hello" {
      ~ content              = "Hello Terraform! ..." -> "Hello Terraform! (lần 2)\n" # forces replacement
      ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

> Chú ý: `local_file` có `content` là attribute **forces replacement** — Terraform sẽ destroy + create lại.

```bash
terraform apply
cat hello.txt
```

### Bước 8 — `terraform destroy`

```bash
terraform destroy
```

Gõ `yes`. Sau khi xong:

```bash
ls hello.txt        # No such file
cat terraform.tfstate   # state vẫn còn nhưng "resources": []
```

### Bước 9 — Dọn dẹp (optional)

**Linux/macOS**:

```bash
rm -rf .terraform
rm -f terraform.tfstate terraform.tfstate.backup
```

**Windows PowerShell**:

```powershell
Remove-Item -Recurse -Force .terraform
Remove-Item -Force terraform.tfstate, terraform.tfstate.backup -ErrorAction SilentlyContinue
```

---

## ✅ Đầu ra checklist

- [ ] `terraform init` chạy thành công, có folder `.terraform/`.
- [ ] `terraform plan` cho thấy "1 to add" trước lần apply đầu.
- [ ] `terraform apply` tạo được file `hello.txt`.
- [ ] Sửa content → `plan` báo "must be replaced", apply lại file thay đổi.
- [ ] `terraform destroy` xoá được file.
- [ ] Mở được `terraform.tfstate` và chỉ ra trường `resources[0].instances[0].attributes`.

---

## 🐛 Common errors

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `Error: Unsupported Terraform Core version` | Terraform < 1.11 | Upgrade Terraform: `choco upgrade terraform` / `brew upgrade terraform` |
| `Error: Could not load plugin` | Network chặn registry.terraform.io | Set proxy, hoặc `TF_PLUGIN_CACHE_DIR` |
| `Error: Provider produced inconsistent result` | Edit file `hello.txt` thủ công sau apply | `terraform apply -refresh-only` để sync state |
| `terraform.tfstate.lock.info` còn sót lại | Crash giữa lúc apply | `terraform force-unlock <LOCK_ID>` |

---

## ❓ Câu hỏi tự ôn

1. Sau `terraform init`, folder `.terraform/` chứa gì? Có nên commit vào Git không?
2. Khác biệt giữa `terraform.tfstate` và `terraform.tfstate.backup` là gì?
3. Vì sao đổi `content` của `local_file` lại làm Terraform destroy + create thay vì update tại chỗ?
4. Block `terraform { required_version = ">= 1.11" }` khác `required_providers` như thế nào?
5. Nếu xoá file `hello.txt` thủ công (không qua Terraform), `terraform plan` lần tới sẽ báo gì?

---

## 📚 Tham khảo

- [HCL Language — Resources](https://developer.hashicorp.com/terraform/language/resources/syntax)
- [Provider hashicorp/local](https://registry.terraform.io/providers/hashicorp/local/latest/docs)

➡️ **Buổi tiếp theo**: [Buổi 03 — AWS Provider & S3 Bucket đầu tiên](../buoi-03-aws-provider-s3/README.md)
