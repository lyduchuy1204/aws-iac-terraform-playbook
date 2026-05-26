# Module `database`

RDS MySQL 8.0 + Secrets Manager + DB Subnet Group + Parameter Group + Security Group.

## Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | string | — | Prefix |
| `vpc_id` | string | — | |
| `private_subnet_ids` | list(string) | — | ≥ 2 subnet ở 2 AZ |
| `ec2_security_group_id` | string | — | Source SG được phép port 3306 |
| `db_name` | string | `appdb` | Database name |
| `db_username` | string | `admin` | Master user |
| `instance_class` | string | `db.t3.micro` | |
| `allocated_storage` | number | `20` | GB |
| `multi_az` | bool | `false` | Prod = true |
| `deletion_protection` | bool | `false` | Prod = true |

## Outputs

| Tên | Mô tả |
|---|---|
| `db_endpoint` | host:port |
| `db_host`, `db_port`, `db_name`, `db_username` | |
| `db_password` | Sensitive |
| `secret_arn` | ARN secret credentials |
| `db_security_group_id` | |

## Bảo mật
- `storage_encrypted = true` (BẮT BUỘC).
- Password sinh tự động bằng `random_password`, lưu trong Secrets Manager.
- Output password đánh dấu `sensitive = true`.
- `lifecycle { ignore_changes = [password] }` để Terraform không tự đổi password.

## Prod checklist
- [ ] `multi_az = true`
- [ ] `deletion_protection = true`
- [ ] `prevent_destroy = true` trong lifecycle
- [ ] `skip_final_snapshot = false`
- [ ] `recovery_window_in_days = 7` (Secret)
