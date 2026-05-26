# Module `compute`

Launch Template + ASG + IAM Role (SSM) + SG cho web tier.

## Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `name` | string | — | Prefix tên resource |
| `vpc_id` | string | — | VPC ID từ module network |
| `private_subnet_ids` | list(string) | — | Private subnet để đặt ASG |
| `vpc_cidr` | string | `10.0.0.0/16` | CIDR VPC (placeholder cho SG inbound) |
| `instance_type` | string | `t3.micro` | EC2 type |
| `asg_min_size` | number | `1` | |
| `asg_max_size` | number | `3` | |
| `asg_desired_capacity` | number | `2` | |
| `tags` | map(string) | `{}` | |

## Outputs

| Tên | Mô tả |
|---|---|
| `asg_name` / `asg_arn` | Để buổi 13 attach Target Group |
| `ec2_security_group_id` | Để buổi 13 cho ALB SG → EC2 SG |
| `iam_role_name` / `iam_role_arn` | Để buổi 12 attach policy Secrets Manager |
| `ami_id` | AMI Amazon Linux 2023 đã chọn |

## Ghi chú
- IMDSv2 bắt buộc (`http_tokens = "required"`).
- user-data cài nginx và in instance-id ra trang web.
