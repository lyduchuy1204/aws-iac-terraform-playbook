# 🎓 Buổi 06 — Remote State (S3 native locking)

> ⏱️ Thời lượng: 2h · 🧰 Yêu cầu: đã xong buổi 05, có AWS credential

---

## 🎯 Mục tiêu

Sau buổi này, bạn sẽ:

- Hiểu vì sao **state local** không an toàn khi làm việc team.
- Tạo được S3 bucket dùng làm **remote state backend**.
- Cấu hình backend `s3` với **`use_lockfile = true`** (S3 native locking — chuẩn 2025+).
- Migrate state local → remote bằng `terraform init -migrate-state`.
- Biết cách xử lý khi **lock kẹt** (file `<key>.tflock` trên S3).

---

## 📚 Lý thuyết

### State là gì?
File `terraform.tfstate` là **bản đồ** giữa code HCL và resource thật trên AWS. Mất state = Terraform không biết quản lý gì nữa.

### Vì sao state local nguy hiểm?
- Người A apply, người B không thấy state mới → apply lệch.
- Máy hỏng = mất state = phải `import` từng resource.
- State chứa **secret** (password, key) ở plain text.

### Backend S3 + native locking (cách MỚI)
Từ Terraform **1.10** (GA ổn định ở **1.11**), backend `s3` hỗ trợ **lock trực tiếp trên S3** qua attribute `use_lockfile = true`.

> 📌 **DynamoDB-based locking đã DEPRECATED** và sẽ bị xoá ở minor version tới. Khoá học này KHÔNG dùng DynamoDB.

Cơ chế: khi bạn `apply`, Terraform tạo file `<key>.tflock` cạnh state file trên S3. File này giữ một "conditional write" — bất kỳ ai khác `apply` cùng lúc sẽ bị từ chối.

### Vấn đề "chicken-and-egg"
```
Stack BOOTSTRAP (state local) ──tạo──▶ S3 bucket (versioning + encryption)
                                             ▲
                                             │ backend (use_lockfile=true)
Stack APP (state remote) ────────────────────┘
```
Bucket lưu state phải tồn tại **trước** khi backend trỏ vào nó. Vì vậy ta tách 2 stack:

- `bootstrap/`: tạo bucket, **state local**.
- `app/`: dùng bucket đó làm backend, **state remote**.

---

## ❓ Vì sao bootstrap state phải LOCAL?

Đây là chỗ rối nhất buổi này. Đọc kỹ:

```
┌──── Vấn đề "con gà - quả trứng" ────┐
│                                     │
│ Stack APP muốn lưu state ở S3 ───┐  │
│                                  │  │
│ Nhưng bucket S3 đó CHƯA TỒN TẠI │  │
│   ↓                              │  │
│ Phải có 1 stack tạo bucket trước│  │
│   = stack BOOTSTRAP              │  │
│   ↓                              │  │
│ Bootstrap muốn lưu state ở đâu? │  │
│   ↓                              │  │
│ Nếu lưu ở chính bucket nó tạo   │  │
│   → CHICKEN-AND-EGG infinite ♾️  │  │
│   ↓                              │  │
│ → BOOTSTRAP giữ state LOCAL      │  │
│   (commit state local vào Git    │  │
│    KHÔNG được — đã có .gitignore)│  │
└─────────────────────────────────────┘
```

**Hệ quả thực tế**:
- Bootstrap state lưu ở folder `bootstrap/terraform.tfstate` của máy bạn.
- **CHỈ 1 người trong team chạy bootstrap (1 lần duy nhất)**, sau đó share tên bucket cho cả team.
- Mất bootstrap state = không tự động xoá được bucket bằng Terraform → phải xoá tay trên Console rồi `terraform state rm` (sẽ học buổi 21).

---

## 🧭 Các bước thực hành

> 🎯 **Tổng quan flow**: chạy `bootstrap/` → tạo bucket → ghi tên bucket vào `app/backend.tf` → init `app/` lần 1 (state local) → apply `app/` → uncomment backend block → `init -migrate-state`.

### Bước 1 — Bootstrap bucket lưu state (state local)

```bash
cd bootstrap
terraform init
terraform apply
```

Ghi nhớ output `state_bucket_name` (ví dụ: `tfstate-123456789012-apse1`).

> 💡 Bucket này có versioning + encryption + block public access. **KHÔNG xoá** cho đến cuối buổi.

### Bước 2 — Vào folder `app/`, đảm bảo backend block CÒN ĐANG COMMENT

```bash
cd ../app
```

Mở `app/backend.tf`. Bạn sẽ thấy block `backend "s3"` đang **comment sẵn** (mỗi dòng có dấu `#` đứng đầu). **GIỮ NGUYÊN** chưa uncomment vội.

> 📌 **Vì sao chưa uncomment ngay?**
> Để demo flow chuẩn: lần đầu `init` state local → apply tạo resource → sau đó migrate state local sang S3. Nếu uncomment ngay từ đầu, Terraform sẽ tìm bucket → mà bucket chưa có key state → vẫn được, nhưng học viên sẽ không thấy "cảm giác migrate".

### Bước 3 — Apply app lần đầu (state local)

```bash
terraform init        # backend chưa kích hoạt → state lưu local
terraform apply       # tạo 1 demo bucket
ls terraform.tfstate  # ✅ thấy state local
```

### Bước 4 — Uncomment backend block + thay tên bucket

Mở `app/backend.tf`:

1. **Bỏ dấu `#` đầu mỗi dòng** của block `terraform { backend "s3" { ... } }` (từ dòng `terraform {` đến `}` đóng ngoài cùng).
2. **Thay `<YOUR_BUCKET_NAME>`** bằng tên bucket từ output Bước 1.

Sau khi sửa, file trông như:

```hcl
terraform {
  backend "s3" {
    bucket       = "tfstate-123456789012-apse1"   # ← thay đúng tên của bạn
    key          = "envs/demo/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

### Bước 5 — Migrate state local → remote

```bash
terraform init -migrate-state
```

Terraform hỏi:
```
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating ...
  Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes
```

Gõ `yes`. State đã được upload lên S3, file local `terraform.tfstate` chỉ còn rỗng (giữ làm lịch sử).

### Bước 6 — Verify state đang ở S3

```bash
# Lệnh đa OS dùng JMESPath
aws s3api list-objects-v2 --bucket <state_bucket_name> --query "Contents[].Key" --output table
```

Bạn sẽ thấy `envs/demo/terraform.tfstate`.

### Bước 7 — Test lock với `null_resource` + sleep

Vì demo bucket tạo rất nhanh (vài giây), khó kịp mở terminal 2. Cách giả lập "apply chậm" để test lock: thêm tạm vào `app/main.tf`:

```hcl
# THÊM TẠM để test lock — XOÁ sau khi xong
resource "null_resource" "slow" {
  provisioner "local-exec" {
    command = "powershell -Command Start-Sleep -Seconds 30"   # Windows
    # Linux/macOS: command = "sleep 30"
  }
}
```

Sau đó:

```bash
# Terminal 1
terraform apply
# (đang chạy, chưa xong)

# Terminal 2 — mở ngay khi T1 còn chạy
terraform apply
```

Terminal 2 sẽ báo:
```
Error: Error acquiring the state lock
Lock Info:
  ID:        ...
  Path:      <bucket>/envs/demo/terraform.tfstate.tflock
  ...
```

Lên S3 console kiểm tra: thấy file `envs/demo/terraform.tfstate.tflock` xuất hiện. **Khi terminal 1 xong, file `.tflock` tự xoá.**

> Sau khi test xong, **xoá `null_resource "slow"`** rồi `terraform apply` lại.

### Bước 8 — Dọn dẹp

```bash
cd app && terraform destroy
cd ../bootstrap && terraform destroy   # XOÁ bucket state cuối cùng
```

> ⚠️ Bucket state có versioning. `destroy` sẽ fail nếu còn version. Chọn 1 trong 2 cách:

**Cách A — AWS Console (dễ nhất)**: vào S3 → bucket → tab **Empty** → gõ `permanently delete` → confirm. Sau đó `terraform destroy` thành công.

**Cách B — CLI (Linux/macOS)**:
```bash
aws s3api delete-objects --bucket <name> \
  --delete "$(aws s3api list-object-versions --bucket <name> --output=json \
    --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
```

**Cách B — CLI (Windows PowerShell)**:
```powershell
$versions = aws s3api list-object-versions --bucket <name> --output json | ConvertFrom-Json
$versions.Versions | ForEach-Object {
  aws s3api delete-object --bucket <name> --key $_.Key --version-id $_.VersionId
}
```

---

## ✅ Đầu ra checklist

- [ ] `bootstrap/` apply thành công, có S3 bucket versioning + encryption + block public.
- [ ] `app/` ban đầu state local, sau migrate sang S3.
- [ ] File `terraform.tfstate` xuất hiện trên S3 đúng key (`envs/demo/terraform.tfstate`).
- [ ] Mở 2 terminal cùng apply → người sau bị **lock** (thấy file `.tflock` trên S3).
- [ ] Lock tự nhả sau khi terminal 1 hoàn tất.
- [ ] Destroy cả 2 stack thành công.

---

## 🧯 Common errors

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `use_lockfile is unknown` | Terraform < 1.10 | Upgrade lên `>= 1.11` |
| `BucketAlreadyExists` | Tên bucket trùng (S3 unique toàn cầu) | Đổi suffix `random_id` |
| `Error acquiring the state lock` (kẹt sau crash) | Lock file còn lại trên S3 | Kiểm tra KHÔNG có process nào đang chạy → xoá `<key>.tflock` thủ công bằng AWS Console hoặc `aws s3 rm` |
| `BucketNotEmpty` khi destroy bootstrap | Còn version cũ của state | Xoá hết version (xem Bước 5) |
| Backend config thay đổi mà không init | Terraform không tự reload backend | Chạy `terraform init -reconfigure` hoặc `-migrate-state` |

---

## 🤔 Câu hỏi tự ôn

1. Vì sao `bootstrap/` phải giữ state local mà không tự lưu vào bucket nó tạo ra?
2. File `<key>.tflock` trên S3 chứa gì? Khi nào nó tự xoá?
3. Có thể dùng 1 bucket cho nhiều project không? (Trả lời: được, miễn `key` khác nhau).
4. Vì sao bật **versioning** trên bucket state? (Gợi ý: rollback state khi apply lỗi).
5. Sự khác nhau giữa `terraform init -migrate-state` và `-reconfigure`?
6. Nếu team đang dùng DynamoDB lock, có cần migrate ngay không?

---

## 📂 Cấu trúc folder

```
buoi-06-remote-state/
├── README.md
├── .gitignore
├── bootstrap/       ← tạo bucket, state local
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
└── app/             ← dùng bucket làm backend, state remote
    ├── main.tf
    ├── backend.tf   ← backend block đang COMMENT, sẽ uncomment ở Bước 4
    ├── variables.tf
    ├── outputs.tf
    └── versions.tf
```

➡️ **Buổi tiếp theo**: [Buổi 07 — Modules cơ bản + Registry](../buoi-07-modules/README.md)
