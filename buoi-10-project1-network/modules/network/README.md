# Module `network`

Tạo VPC 2-AZ với public + private subnet, IGW, NAT (cost-saving cho dev).

## Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | string | — | Prefix cho tên resource |
| `vpc_cidr` | string | `10.0.0.0/16` | CIDR VPC |
| `azs` | list(string) | — | 2 AZ |
| `public_subnet_cidrs` | list(string) | `[10.0.1.0/24, 10.0.2.0/24]` | CIDR public subnet |
| `private_subnet_cidrs` | list(string) | `[10.0.11.0/24, 10.0.12.0/24]` | CIDR private subnet |
| `single_nat_gateway` | bool | `true` | Chỉ 1 NAT (cost-saving). Prod: false |
| `tags` | map(string) | `{}` | Tag bổ sung |

## Outputs

| Tên | Mô tả |
|---|---|
| `vpc_id` | ID VPC |
| `vpc_cidr` | CIDR VPC |
| `public_subnet_ids` | List ID public subnet |
| `private_subnet_ids` | List ID private subnet |
| `internet_gateway_id` | ID IGW |
| `nat_gateway_ids` | List ID NAT Gateway |
| `azs` | List AZ đang dùng |

## Ví dụ

```hcl
module "network" {
  source = "../../modules/network"

  name = "iac-playbook-dev"
  azs  = ["ap-southeast-1a", "ap-southeast-1b"]
}
```

## ⚠️ Cost
NAT Gateway ~$32/tháng + traffic. Destroy ngay sau khi học.
