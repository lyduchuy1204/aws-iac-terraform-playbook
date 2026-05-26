# 🎓 Buổi 10 — Project 1: VPC Network Module

> ⏱️ Thời lượng: 3h · 🧰 Yêu cầu: đã xong buổi 09

---

## 🧭 Vị trí trong Project 1: **[1/4] — Network**

```
[1/4] Network ─────► [2/4] Compute ─────► [3/4] Database ─────► [4/4] ALB & Finish
  ▲ bạn ở đây
```

**Kiến trúc đích cuối Project 1**:
```
Internet ──► ALB (B13) ──► EC2 ASG (B11) ──► RDS MySQL (B12)
                              ▲
                              │ tất cả chạy trên VPC + subnet do buổi 10 tạo
```

> 📌 **Cách 4 buổi truyền dữ liệu cho nhau** (xem chi tiết bên dưới):
> Mỗi buổi `terraform apply` tạo resource → output ID. Buổi tiếp theo cần ID đó để tạo resource gắn vào.
> Có 2 cách lấy: (A) **paste tay** vào `terraform.tfvars` của buổi sau (đơn giản, dễ hiểu — playbook khuyên dùng), hoặc (B) `terraform_remote_state` (tự động, học buổi 19/20).

### 🔗 Pipeline output → input giữa 4 buổi

| Buổi | Output chính | Buổi sau cần input |
|---|---|---|
| **B10 (bạn ở đây)** | `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `vpc_cidr` | B11, B12, B13 đều cần |
| B11 (Compute) | `ec2_security_group_id`, `iam_role_name`, `asg_name` | B12 (SG cho RDS), B13 (attach ASG vào ALB TG) |
| B12 (Database) | `secret_arn` | B11 patch lại để đọc secret (đã làm sẵn trong code mẫu) |
| B13 (ALB) | `alb_dns_name`, `alb_security_group_id` | Người dùng cuối curl |

> 💡 Kết thúc B10, **lưu lại 4 output** (`terraform output`) để paste vào tfvars của B11/B12/B13.

---

## 🎯 Mục tiêu

Đây là **buổi mở đầu Project 1**. Bạn sẽ xây nền móng mạng:

- Module `network/` tự viết: VPC + Subnet + IGW + NAT.
- Hiểu kiến trúc 2-AZ public/private chuẩn.
- Tiết kiệm chi phí dev: chỉ **1 NAT Gateway** thay vì 1 cái mỗi AZ.
- Output đầy đủ để các module sau (compute, database, alb) consume được.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| VPC | mạng ảo riêng trong 1 region |
| CIDR | dải IP (vd `10.0.0.0/16`) |
| Public subnet | route 0.0.0.0/0 → IGW |
| Private subnet | route 0.0.0.0/0 → NAT |
| IGW | Internet Gateway, 2 chiều |
| NAT Gateway | 1 chiều (out only), trả phí |

---

## 💰 Cost warning

> **NAT Gateway tính tiền NGAY khi tạo: ~$0.045/giờ + traffic = ~$32/tháng.**
> Cộng thêm Data Processing $0.045/GB. Nhớ `terraform destroy` ngay sau khi học xong.

> Production có thể cần **NAT mỗi AZ** để HA (~$96/tháng cho 3 AZ). Module này dùng **single NAT** cho dev — đánh đổi: AZ-b mất NAT thì instance trong AZ-b mất Internet outbound.

---

## 📚 Lý thuyết

### Kiến trúc đích
```
              Internet
                 │
            ┌────┴─────┐
            │   IGW    │
            └────┬─────┘
                 │
   ┌─────────────┴──────────────┐
   │  VPC 10.0.0.0/16           │
   │                            │
   │  AZ-a              AZ-b    │
   │ ┌──────────┐    ┌──────────┐
   │ │public-a  │    │public-b  │← ALB sẽ ở đây (buổi 13)
   │ │10.0.1/24 │    │10.0.2/24 │
   │ └────┬─────┘    └──────────┘
   │      │ NAT (chỉ 1 cái cho dev)
   │      ▼
   │ ┌──────────┐    ┌──────────┐
   │ │private-a │    │private-b │← EC2/RDS ở đây
   │ │10.0.11/24│    │10.0.12/24│
   │ └──────────┘    └──────────┘
   └────────────────────────────┘
```

### Public vs Private subnet
- **Public**: route `0.0.0.0/0` → IGW. EC2 ở đây có public IP.
- **Private**: route `0.0.0.0/0` → NAT. EC2 outbound được nhưng KHÔNG ai từ Internet vào được.

### Vì sao cần NAT?
EC2 trong private subnet vẫn cần **gọi ra Internet** (apt update, pull docker image, gọi API). NAT Gateway dịch IP riêng → IP công cộng giúp việc đó.

---

## 🧭 Các bước thực hành

### Bước 1 — Đọc module
Mở `modules/network/`:
- `main.tf`: VPC, 4 subnet (2 public + 2 private), IGW, NAT, route tables.
- `variables.tf`: input có default sẵn cho dev.
- `outputs.tf`: expose `vpc_id`, `public_subnet_ids`, `private_subnet_ids` — module sau sẽ dùng.

### Bước 2 — Apply env dev
```bash
cd envs/dev
terraform init
terraform plan
terraform apply
```

### Bước 3 — Verify trên Console
- VPC tab → thấy `iac-playbook-dev-vpc`.
- Subnets → 4 cái, đúng AZ-a / AZ-b.
- Route Tables → public table có route ra IGW, private table có route qua NAT.

### Bước 4 — Destroy
```bash
terraform destroy
```
Đặc biệt **chờ NAT destroy xong** mới yên tâm: `aws ec2 describe-nat-gateways --filter "Name=state,Values=pending,available"` không còn cái nào.

---

## ✅ Đầu ra checklist

- [ ] Module `modules/network/` có `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`.
- [ ] VPC `10.0.0.0/16` được tạo.
- [ ] 2 public subnet (`10.0.1.0/24`, `10.0.2.0/24`) ở AZ-a, AZ-b.
- [ ] 2 private subnet (`10.0.11.0/24`, `10.0.12.0/24`).
- [ ] 1 Internet Gateway gắn vào VPC.
- [ ] **1 NAT Gateway** (single, cost-saving) ở public subnet AZ-a.
- [ ] Route table public → IGW, private → NAT.
- [ ] Output `vpc_id`, `public_subnet_ids`, `private_subnet_ids` đúng.
- [ ] Destroy sạch: `aws ec2 describe-vpcs` không còn VPC này.

---

## 🧯 Common errors

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `InvalidParameterValue: NAT Gateway requires Elastic IP` | EIP chưa allocate | Module đã tự tạo `aws_eip` — kiểm tra resource đó |
| Private subnet không Internet được | Route table sai, hoặc NAT chưa available | `aws ec2 describe-nat-gateways` xem state |
| Destroy treo ở NAT | NAT phải destroy trước khi xoá EIP/IGW | Terraform xử lý thứ tự, chỉ chờ thôi (~1-2 phút) |
| `CIDR block conflicts` | Tạo 2 lần với cùng CIDR | Đổi CIDR hoặc destroy lần cũ |

---

## 🤔 Câu hỏi tự ôn

1. Vì sao public subnet phải bật `map_public_ip_on_launch = true`?
2. Có thể có VPC mà KHÔNG có IGW không? (Trả lời: được, "isolated VPC").
3. Single NAT ở AZ-a, nếu AZ-a chết thì subnet AZ-b ra sao?
4. EIP có tốn tiền khi KHÔNG gắn vào resource? (Trả lời: có, $0.005/giờ — đắt hơn khi gắn!).
5. CIDR `/16` cho VPC, `/24` cho subnet → mỗi subnet có bao nhiêu IP dùng được?

---

## 📂 Cấu trúc folder

```
buoi-10-project1-network/
├── README.md
├── .gitignore
├── modules/
│   └── network/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
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
