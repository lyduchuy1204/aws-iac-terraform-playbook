# Module `s3-bucket`

Module đơn giản tạo S3 bucket có:
- Versioning (tuỳ chọn).
- Mã hoá at-rest mặc định (AES256).
- Block public access (luôn bật).

## Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | string | — | Tên bucket (unique toàn cầu) |
| `versioning_enabled` | bool | `false` | Bật S3 versioning |
| `force_destroy` | bool | `false` | Cho phép destroy khi còn object (CHỈ dev) |
| `tags` | map(string) | `{}` | Tag bổ sung |

## Outputs

| Tên | Mô tả |
|---|---|
| `bucket_id` | ID (= tên) bucket |
| `bucket_arn` | ARN bucket |
| `bucket_domain_name` | Domain name |

## Ví dụ dùng

```hcl
module "logs_bucket" {
  source             = "./modules/s3-bucket"
  name               = "my-app-logs-abc123"
  versioning_enabled = true
  tags = {
    Purpose = "logs"
  }
}
```
