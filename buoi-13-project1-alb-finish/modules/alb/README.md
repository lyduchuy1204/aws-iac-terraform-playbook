# Module `alb`

ALB internet-facing + Target Group + Listener + Security Group.

## Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | string | — | Prefix |
| `vpc_id` | string | — | |
| `public_subnet_ids` | list(string) | — | ≥ 2 public subnet |
| `target_port` | number | `80` | Port EC2 lắng nghe |
| `health_check_path` | string | `/` | |
| `tags` | map(string) | `{}` | |

## Outputs

| Tên | Mô tả |
|---|---|
| `alb_dns_name` | DNS công khai |
| `alb_zone_id` | Cho Route53 alias |
| `target_group_arn` | Để gắn vào ASG |
| `alb_security_group_id` | Để EC2 SG allow inbound |

## Sau apply
```bash
curl http://$(terraform output -raw alb_dns_name)
```
