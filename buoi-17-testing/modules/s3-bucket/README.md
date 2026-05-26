# Module: `s3-bucket`

Module S3 tối giản, dùng để minh hoạ `terraform test`.

## Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | string | (bắt buộc) | Tên bucket — phải unique toàn cầu, 3–63 ký tự lowercase/số/dấu gạch ngang |
| `versioning_enabled` | bool | `true` | Bật S3 versioning |
| `tags` | map(string) | `{}` | Tag áp lên bucket |

## Outputs

| Tên | Mô tả |
|---|---|
| `bucket_name` | Tên bucket đã tạo |
| `bucket_arn` | ARN dạng `arn:aws:s3:::<name>` |
| `bucket_id` | ID bucket (== name với S3) |

## Mặc định module luôn bật

- AES256 server-side encryption
- Public access block (cả 4 setting)

## Tests

Xem folder `tests/`:
- `defaults.tftest.hcl` — plan-only, kiểm tra bucket name khớp input.
- `apply.tftest.hcl` — apply thật + assert ARN, sau đó destroy.
- `validation.tftest.hcl` — kiểm tra variable validation chặn input không hợp lệ.

Chạy:
```bash
terraform test
```
