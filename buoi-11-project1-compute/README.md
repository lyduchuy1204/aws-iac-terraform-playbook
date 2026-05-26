# 🎓 Buổi 11 — Project 1: Compute (EC2 + ASG + Launch Template)

> ⏱️ Thời lượng: 2.5h · 🧰 Yêu cầu: đã xong buổi 10 (network)

---

## 🧭 Vị trí trong Project 1: **[2/4] — Compute**

```
[1/4] Network ─────► [2/4] Compute ─────► [3/4] Database ─────► [4/4] ALB & Finish
                       ▲ bạn ở đây
```

### 📥 Input từ buổi 10 (paste vào `terraform.tfvars`)

```hcl
# Lấy từ output của buổi 10:  cd ../buoi-10-project1-network/envs/dev && terraform output
vpc_id              = "vpc-0abc..."
private_subnet_ids  = ["subnet-0abc...", "subnet-0def..."]
vpc_cidr            = "10.0.0.0/16"
```

### 📤 Output cho buổi sau

| Output | Buổi 12 (Database) | Buổi 13 (ALB) |
|---|---|---|
| `ec2_security_group_id` | ✅ cho RDS SG inbound 3306 | ✅ EC2 SG nhận traffic từ ALB |
| `iam_role_name` | ✅ attach policy đọc Secrets Manager | — |
| `asg_name` | — | ✅ attach ASG vào Target Group |

### ⚠️ Nếu DỪNG học giữa chừng (sau B11)

Phải `destroy` đúng thứ tự ngược: **B11 destroy trước, B10 destroy sau**.
```bash
cd buoi-11-project1-compute/envs/dev   && terraform destroy
cd ../../buoi-10-project1-network/envs/dev && terraform destroy
```

---

## 🎯 Mục tiêu

- Tạo **Launch Template** với user-data cài nginx (Amazon Linux 2023).
- Tạo **Auto Scaling Group** min=1, max=3, desired=2.
- IAM Role có **SSM Session Manager** (KHÔNG cần SSH key).
- Security Group EC2 (placeholder, sẽ liên kết với ALB SG ở buổi 13).
- Lấy AMI Amazon Linux 2023 mới nhất qua `data "aws_ami"`.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| Launch Template | blueprint EC2 instance, có version |
| ASG (Auto Scaling Group) | nhóm EC2 tự scale theo metric |
| user-data | script chạy lần đầu khi EC2 boot |
| Instance Profile | cách AWS gắn IAM Role vào EC2 |
| SSM Session Manager | kết nối shell EC2 không cần SSH key |

---

## 💰 Cost warning

> 2 EC2 t3.micro (Free Tier 12 tháng đầu, 750h/tháng/instance). Sau Free Tier ~$15/tháng.
> NAT Gateway từ buổi 10 vẫn đang chạy.

---

## 📚 Lý thuyết

### Launch Template vs Launch Configuration
- **Launch Configuration** (cũ): không version, đổi là tạo cái mới rồi point ASG sang.
- **Launch Template** (mới): có **version**, ASG dùng `$Latest` hoặc số cụ thể. **Dùng Launch Template.**

### user-data
Script chạy LẦN ĐẦU khi instance boot. Cần encode base64 khi đưa vào Launch Template.

```hcl
user_data = base64encode(file("${path.module}/user_data.sh"))
```

### IAM Instance Profile
EC2 không "đeo" IAM Role trực tiếp — phải qua **Instance Profile** (1 wrapper).

### SSM Session Manager
Quên SSH key đi. Gắn policy `AmazonSSMManagedInstanceCore` cho IAM Role → vào EC2 qua AWS Console hoặc:
```bash
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx
```

---

## 🧭 Các bước thực hành

### Bước 1 — Apply network trước (nếu chưa)
Buổi 10 phải đã `apply` thành công. Lấy `vpc_id`, `private_subnet_ids` từ output.

### Bước 2 — Cấu hình env dev
Mở `envs/dev/terraform.tfvars.example`, điền:
- `vpc_id` từ output buổi 10.
- `private_subnet_ids` từ output buổi 10.

```bash
cp envs/dev/terraform.tfvars.example envs/dev/terraform.tfvars
# chỉnh giá trị trong terraform.tfvars
```

### Bước 3 — Apply
```bash
cd envs/dev
terraform init
terraform plan
terraform apply
```

Kết quả: 2 EC2 instance chạy nginx trong private subnet, có IAM Role SSM.

### Bước 4 — Test SSM
Vào AWS Console → EC2 → chọn 1 instance → Connect → Session Manager → Connect.

Trong session:
```bash
sudo systemctl status nginx
curl localhost
```

### Bước 5 — Destroy
```bash
terraform destroy
```

> Sau buổi này, NẾU không học buổi 12 ngay, hãy destroy cả buổi 10 (NAT đắt).

---

## ✅ Đầu ra checklist

- [ ] Module `modules/compute/` có đủ file.
- [ ] `data "aws_ami"` lấy Amazon Linux 2023 mới nhất.
- [ ] Launch Template có user-data cài nginx, encode base64.
- [ ] ASG min=1, max=3, desired=2, đặt trong **private subnet**.
- [ ] Security Group EC2 (ingress port 80 sẽ link với ALB SG ở buổi 13 — hiện để placeholder mở từ VPC CIDR).
- [ ] IAM Role có policy `AmazonSSMManagedInstanceCore`.
- [ ] Instance Profile gắn vào Launch Template.
- [ ] Vào EC2 qua Session Manager thành công, `curl localhost` ra trang nginx.

---

## 🧯 Common errors

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| ASG không launch instance | Subnet sai, Launch Template lỗi user-data | Check CloudWatch Logs hoặc `aws autoscaling describe-scaling-activities` |
| Session Manager không connect | IAM Role thiếu `AmazonSSMManagedInstanceCore`, hoặc instance không có route ra Internet (private subnet cần NAT) | Verify policy + route table |
| nginx không chạy | user-data lỗi, hoặc AMI không phải AL2023 | SSM vào, đọc `/var/log/cloud-init-output.log` |
| AMI not found | Filter `data "aws_ami"` không match | Check filter `name`, `owner` |

---

## 🤔 Câu hỏi tự ôn

1. Vì sao Launch Template tốt hơn Launch Configuration?
2. user-data chạy lúc nào? Khi instance reboot có chạy lại không?
3. Tại sao đặt EC2 ở **private** subnet thay vì public?
4. SSM Session Manager cần điều kiện gì để work? (Hint: SSM agent + IAM + outbound HTTPS).
5. ASG `min=1, desired=2`: nếu xoá 1 instance thủ công, ASG có tự thay thế không?

---

## 📂 Cấu trúc folder

```
buoi-11-project1-compute/
├── README.md
├── .gitignore
├── modules/
│   └── compute/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── user_data.sh
│       └── README.md
└── envs/
    └── dev/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        ├── backend.tf
        └── terraform.tfvars.example
```
