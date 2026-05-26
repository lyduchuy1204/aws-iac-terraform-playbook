# 🎓 Buổi 09 — count, for_each, dynamic

> ⏱️ Thời lượng: 2h · 🧰 Yêu cầu: đã xong buổi 08

---

## 🎯 Mục tiêu

- Sinh nhiều resource từ data structure mà KHÔNG copy-paste.
- Phân biệt `count` vs `for_each` — biết khi nào dùng cái nào.
- Dùng `dynamic` block để generate nested config (ingress rules, statements...).
- Hiểu vì sao `for_each` an toàn hơn `count` khi danh sách thay đổi.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| `count` | tạo N copy bằng số nguyên |
| `for_each` | tạo nhiều copy từ map/set, có key xác định |
| `dynamic` block | sinh nested block từ list/map |
| `each.key` / `each.value` | trong `for_each`, lấy key/giá trị |
| `each.key` shift index | vấn đề của `count` khi xoá phần tử giữa list |

---

## 📚 Lý thuyết

### `count` vs `for_each`

| | `count` | `for_each` |
|---|---|---|
| Kiểu input | Số nguyên | `set(string)` hoặc `map(any)` |
| Truy cập | `aws_instance.web[0]` | `aws_instance.web["alice"]` |
| Thêm phần tử ở giữa | ❌ Shift index → Terraform replace tất | ✅ Chỉ tạo thêm phần tử mới |
| Khi nào dùng | "Tôi cần N cái giống nhau" | "Tôi có N cái KHÁC NHAU theo tên" |

> 💡 **Quy tắc**: Mặc định dùng `for_each`. Chỉ dùng `count` cho cờ on/off đơn giản (`count = var.enabled ? 1 : 0`).

### Tại sao `count` shift index nguy hiểm?
```hcl
# Lần 1: users = ["alice", "bob", "carol"]
# users[0] = alice, users[1] = bob, users[2] = carol

# Lần 2: thêm "andy" ở đầu → users = ["andy", "alice", "bob", "carol"]
# users[0] = andy   ← Terraform thấy users[0] đổi từ alice → andy
# users[1] = alice  ← từ bob → alice
# Kết quả: REPLACE TẤT CẢ user! Mất access key, etc.
```

Với `for_each = toset([...])`, Terraform key bằng tên ("alice", "bob") nên thêm "andy" chỉ tạo thêm 1 user mới.

### `dynamic` block
Khi cần generate **nhiều block lồng** (ingress, statement) từ list/map, dùng `dynamic`:

```hcl
dynamic "ingress" {
  for_each = var.allowed_ports
  content {
    from_port = ingress.value
    to_port   = ingress.value
    # ...
  }
}
```

---

## 🧭 Các bước thực hành

### Bước 1 — Apply
```bash
terraform init
terraform plan
terraform apply
```

Kết quả:
- 3 IAM user: `alice`, `bob`, `carol`.
- 1 Security Group với nhiều ingress rule (sinh từ list).

### Bước 2 — Test thêm user
Sửa `variables.tf`, thêm `"andy"` vào đầu list `iam_user_names`. `terraform plan` xem: **chỉ 1 resource được tạo thêm** (do `for_each`), không ai bị replace.

### Bước 3 — Test sửa list port
Thêm/bớt port trong `allowed_ports`. Plan xem `dynamic` regenerate thế nào.

### Bước 4 — Destroy
```bash
terraform destroy
```

---

## ✅ Đầu ra checklist

- [ ] 3 IAM user được tạo bằng `for_each = toset(...)`.
- [ ] 1 Security Group với rules sinh từ `dynamic "ingress"`.
- [ ] List port mở đọc từ `var.allowed_ports`.
- [ ] Khi thêm 1 user vào giữa list, plan KHÔNG replace user cũ.
- [ ] Hiểu được output `iam_user_arns` là 1 map.

---

## 🧯 Common errors

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `for_each` báo "value depends on resource attributes" | Dùng output resource khác làm key | Dùng giá trị tĩnh hoặc thêm `depends_on` |
| `each.key` không tìm thấy | Quên `toset(...)` quanh list | `for_each = toset(["alice","bob"])` |
| `dynamic` block không generate ra rule nào | `for_each` rỗng | Check input có ít nhất 1 phần tử |
| `count.index` âm | Dùng `count = length([])` | Bảo vệ: `count = length(var.x) > 0 ? length(var.x) : 0` |

---

## 🤔 Câu hỏi tự ôn

1. Khi nào nên dùng `count` thay vì `for_each`?
2. `for_each = var.users` (list) sẽ lỗi. Vì sao? Cách sửa?
3. `dynamic "tags"` có hoạt động không? Vì sao? (Hint: tags là argument, không phải block).
4. Nếu muốn map mỗi user → email khác nhau, dùng `for_each` với type gì?
5. Resource `aws_security_group_rule` riêng vs `dynamic "ingress"` trong `aws_security_group` — khác nhau thế nào?

---

## 📂 Cấu trúc folder

```
buoi-09-loops-dynamic/
├── README.md
├── .gitignore
├── main.tf
├── variables.tf
├── outputs.tf
└── versions.tf
```
