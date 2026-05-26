# 🎓 Buổi 17 — Terraform Testing (`terraform test` native)

> Module bạn viết tưởng đúng — cho đến khi nó hỏng ở prod. Buổi này dạy `terraform test` native (built-in từ Terraform **1.6**, GA stable từ **1.6+**) để test module trước khi tin nó.

---

## 🎯 Mục tiêu

- Hiểu cấu trúc file `*.tftest.hcl` (`run`, `command`, `variables`, `assert`).
- Viết được 3 loại test cơ bản:
  1. **Plan-only** — kiểm tra config đúng, không tạo resource thật.
  2. **Apply test** — tạo thật → assert → tự destroy.
  3. **Validation test** — input không hợp lệ phải bị chặn ở variable level.
- Biết khi nào dùng `terraform test` native, khi nào cần Terratest (Go).

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| `terraform test` | Built-in test framework từ Terraform 1.6 |
| `*.tftest.hcl` | File test, đặt trong `tests/` |
| `run` block | 1 test case |
| `command = plan\|apply` | Chạy plan-only (rẻ) hoặc apply thật |
| `assert` | Assertion với condition + error_message |
| `expect_failures = [var.X]` | Test variable validation phải chặn input xấu |
| Terratest | Thư viện Go cho integration test phức tạp |

---

## 📚 Lý thuyết

### `terraform test` là gì?

Từ **Terraform 1.6**, lệnh `terraform test` đã GA. Test framework built-in, không cần Go, không cần thư viện ngoài.

### Cấu trúc file test

```hcl
# Tên file: <something>.tftest.hcl, đặt trong tests/

# (Tuỳ chọn) provider chung cho mọi run
provider "aws" {
  region = "ap-southeast-1"
}

# Mỗi block "run" = 1 test case
run "<tên_run>" {
  command = plan      # plan | apply

  # Override biến của module được test
  variables {
    name = "..."
  }

  # Assertion — pass nếu condition = true
  assert {
    condition     = aws_s3_bucket.this.bucket == "..."
    error_message = "..."
  }

  # (Tuỳ chọn) khẳng định lỗi đến từ validation của 1 biến cụ thể
  expect_failures = [
    var.name,
  ]
}
```

### Cách chạy

```bash
cd modules/s3-bucket
terraform init
terraform test
# Hoặc chạy 1 file cụ thể:
terraform test -filter=tests/defaults.tftest.hcl
# Verbose:
terraform test -verbose
```

### Quy trình thực thi của `terraform test`

1. Đọc các file `*.tftest.hcl` (mặc định trong `tests/` hoặc thư mục hiện tại).
2. Mỗi `run`:
   - Chạy `terraform plan` (hoặc `apply`) với `variables` override.
   - Đánh giá `assert` block.
   - Nếu là `command = apply`: **tự động `destroy` sau khi run kết thúc**.
3. Báo cáo PASS/FAIL.

---

## 🛠️ Các bước thực hành

### Bước 1 — Đọc module mẫu
Module này dựa trên Buổi 07, đã có sẵn ở `modules/s3-bucket/` với phần variable validation bổ sung. Bạn KHÔNG cần copy thủ công — chỉ vào folder và chạy test.

- `main.tf` — bucket + versioning + encryption + public access block.
- `variables.tf` — `name` (có validation), `versioning_enabled`, `tags`.
- `outputs.tf` — `bucket_name`, `bucket_arn`, `bucket_id`.

### Bước 2 — 3 file test trong `modules/s3-bucket/tests/`

#### a) `defaults.tftest.hcl` — plan-only
- Truyền `name`, kiểm tra `aws_s3_bucket.this.bucket` plan ra đúng tên đó.
- Kiểm tra default `versioning_enabled = true` → resource versioning có status `Enabled`.
- Kiểm tra public access block bật đủ 4 flag, encryption AES256.

#### b) `apply.tftest.hcl` — apply thật, có `setup` module
- Có 1 helper module trong `tests/setup/` sinh `random_id` để tạo bucket name unique.
- Run chính: apply module với name = `buoi17-test-<random>`, assert ARN match regex `arn:aws:s3:::buoi17-test-[a-z0-9]+`.
- Sau test, framework tự destroy bucket.

> ⚠️ **Cần AWS credentials thật** (env `AWS_PROFILE` hoặc `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`).

#### c) `validation.tftest.hcl` — variable validation
- Truyền các tên không hợp lệ: HOA, quá ngắn, bắt đầu bằng `-`, có `_`.
- Dùng `expect_failures = [var.name]` để khẳng định: lỗi đến **từ validation của biến `name`**, không phải lỗi runtime hay assertion.

### Bước 3 — Chạy

> ⚠️ **Cảnh báo cleanup khi test crash**:
> - `apply.tftest.hcl` tạo bucket S3 thật (free tier nhưng vẫn để dấu vết).
> - Bình thường framework tự destroy sau khi run xong.
> - **Nếu Ctrl+C giữa chừng** hoặc test crash → bucket có thể bị "mồ côi".
> - Phải xoá tay: `aws s3 rb s3://buoi17-test-XXXX --force` hoặc Console → Empty bucket → Delete.

```bash
cd buoi-17-testing/modules/s3-bucket
terraform init
terraform test
```

Kết quả mong đợi (output rút gọn):
```
tests/defaults.tftest.hcl... in progress
  run "plan_with_defaults"... pass
  run "plan_versioning_disabled"... pass
tests/defaults.tftest.hcl... tearing down
tests/defaults.tftest.hcl... pass

tests/validation.tftest.hcl... in progress
  run "reject_uppercase_name"... pass
  ... (5 run)

tests/apply.tftest.hcl... in progress
  run "setup_random_suffix"... pass
  run "apply_creates_real_bucket"... pass
tests/apply.tftest.hcl... tearing down
tests/apply.tftest.hcl... pass

Success! 8 passed, 0 failed.
```

---

## 🔁 So sánh: `terraform test` vs Terratest

| Tiêu chí | `terraform test` (native) | Terratest (Go) |
|---|---|---|
| Ngôn ngữ | HCL | Go |
| Cần build/dep ngoài | Không | Cần Go toolchain + `go.mod` |
| Phù hợp với | **Unit test module**, validate input/output, plan-only | **Integration test**: gọi HTTP endpoint, check log, đợi async, test khả năng kết nối service |
| Custom assertion | Hạn chế (chỉ HCL expression) | Tự do (Go: HTTP client, AWS SDK, retry) |
| Run thời gian | Nhanh (plan) hoặc trung bình (apply) | Lâu hơn (cần compile, setup Go) |
| Setup CI | Cần Terraform >= 1.6 | Cần Go runtime |
| Học phí | Thấp (đã quen HCL) | Cao (phải biết Go) |

### Khi nào dùng cái nào?

**Dùng `terraform test` native khi:**
- Test logic module: input → resource attributes / output đúng?
- Test variable validation chặn input xấu.
- Test default values, conditional logic (`count`/`for_each`).
- Cần test nhanh, không cần dev knowledge Go.

**Dùng Terratest khi:**
- Cần kiểm tra runtime: API gateway có trả 200 không? RDS có connect được không?
- Cần test end-to-end nhiều module ghép nhau.
- Cần retry logic phức tạp (đợi ASG scale, đợi ALB healthy).
- Cần assert chi tiết JSON response, log content.

> Quy tắc: **Bắt đầu với native `terraform test`. Chuyển sang Terratest khi bài toán vượt quá khả năng HCL.**

---

## ✅ Đầu ra (Checklist)

- [ ] Folder `modules/s3-bucket/` có đủ `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`.
- [ ] Folder `tests/` có 3 file `*.tftest.hcl` + `tests/setup/` helper.
- [ ] `terraform test` PASS toàn bộ, không tạo resource sót lại.
- [ ] Hiểu `command = plan` vs `command = apply`.
- [ ] Hiểu `expect_failures = [var.<name>]` dùng để test variable validation.
- [ ] Có thể giải thích khi nào nên dùng Terratest thay native test.

---

## 🐞 Common Errors

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| `Unsupported block type: run` | Terraform < 1.6 | Upgrade Terraform >= 1.6 (khuyên >= 1.11) |
| `Error: No valid credential sources` ở `apply.tftest.hcl` | Chưa có AWS credentials | `aws configure` hoặc set env `AWS_PROFILE` |
| Bucket bị "BucketAlreadyExists" | Trùng tên bucket toàn cầu | Dùng `setup` module với `random_id` (đã làm) |
| Test apply không tự destroy | Crash giữa chừng | Vào Console xoá bằng tay, hoặc `terraform destroy` thủ công ở module |
| `expect_failures` không catch được | Validation block sai cú pháp, hoặc lỗi không từ biến đó | Đọc kỹ output, chỉnh `condition` của `validation` block |
| `assert` so sánh `null` lỗi | Output chưa known ở plan stage | Đổi sang `command = apply` hoặc bỏ assert đó ở plan |

---

## ❓ Câu hỏi tự ôn

1. Vì sao một số assert chỉ chạy được khi `command = apply`, không chạy được ở `plan`?
2. `expect_failures` khác `assert { condition = false }` ở chỗ nào?
3. Khi `run` ở `command = apply`, `terraform test` có tự destroy không? Ai chịu trách nhiệm dọn nếu test crash?
4. Vì sao `apply.tftest.hcl` cần một `setup` module sinh random suffix?
5. Khi cần test "API Gateway trả về 200 sau apply" — dùng native test hay Terratest? Vì sao?
6. Trong CI, nên chạy test nào trên PR (rẻ, nhanh) và test nào ở pipeline nightly (đắt, lâu)?
7. Module dùng `for_each` — viết test thế nào để cover cả "input rỗng" và "input có 3 phần tử"?

---

## 📚 Tham khảo

- [Terraform — Tests](https://developer.hashicorp.com/terraform/language/tests)
- [Terraform 1.6 release notes](https://github.com/hashicorp/terraform/releases/tag/v1.6.0)
- [Terratest](https://terratest.gruntwork.io/)
- [Tutorial: Write Terraform tests](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test)
