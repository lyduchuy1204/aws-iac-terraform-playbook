# 🎓 Buổi 13 — Project 1: ALB & Hoàn thiện

> ⏱️ Thời lượng: 2h · 🧰 Yêu cầu: đã xong buổi 12

---

## 🧭 Vị trí trong Project 1: **[4/4] — ALB & Finish**

```
[1/4] Network ─────► [2/4] Compute ─────► [3/4] Database ─────► [4/4] ALB & Finish
                                                                  ▲ bạn ở đây 🏁
```

### 📥 Input từ B10 + B11 (paste vào `terraform.tfvars`)

```hcl
# Từ B10:
vpc_id                = "vpc-0abc..."
public_subnet_ids     = ["subnet-0pub1...", "subnet-0pub2..."]   # ALB ở public subnet
# Từ B11:
ec2_security_group_id = "sg-0ec2..."
asg_name              = "buoi-11-asg"
```

### 📤 Output cuối Project 1

| Output | Dùng để |
|---|---|
| `alb_dns_name` | `curl http://<alb_dns>` thấy nginx + EC2 instance ID |
| `test_command` | Lệnh curl đầy đủ — copy paste chạy luôn |

### 🏁 Sau khi hoàn thành B13 → Demo & Destroy theo thứ tự ngược

```bash
# Demo: curl thấy trang web qua ALB
curl http://$(terraform output -raw alb_dns_name)

# Destroy theo thứ tự NGƯỢC (rất quan trọng — không thể đảo)
cd buoi-13-project1-alb-finish/envs/dev   && terraform destroy   # ALB trước
cd ../../buoi-12-project1-database/envs/dev   && terraform destroy   # rồi DB
cd ../../buoi-11-project1-compute/envs/dev   && terraform destroy   # rồi EC2/ASG
cd ../../buoi-10-project1-network/envs/dev   && terraform destroy   # cuối cùng VPC/NAT
```

> ⚠️ **Vì sao thứ tự ngược?** Resource buổi sau phụ thuộc resource buổi trước (ALB nằm trên VPC, EC2 dùng SG VPC). Destroy ngược = giải dependency từ ngoài vào trong.

---

## 🎯 Mục tiêu

Đây là **buổi cuối Project 1**. Ráp tất cả module lại:

- ALB internet-facing ở public subnet.
- Target Group port 80 + health check `/`.
- Listener port 80 forward Target Group.
- Security Group ALB: inbound 80 từ `0.0.0.0/0`.
- ASG buổi 11 attach vào Target Group.
- EC2 SG được sửa để chỉ accept từ ALB SG (KHÔNG còn từ VPC CIDR).
- Curl ALB DNS → trang nginx hiện instance ID.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| ALB | Application Load Balancer, layer 7 (HTTP/HTTPS) |
| Target Group | nhóm endpoint (EC2/IP/Lambda) ALB forward tới |
| Listener | lắng nghe port (80/443) trên ALB |
| Health check | ALB tự ping `/` để check target khoẻ không |
| ASG attachment | gắn ASG vào Target Group, EC2 mới sinh tự register |

---

## 💰 Cost warning toàn Project 1

> Cộng dồn các buổi 10-13:
> - **NAT Gateway**: ~$32/tháng
> - **ALB**: ~$16/tháng + $0.008/LCU-hour
> - **RDS db.t3.micro**: ~$13/tháng (Free Tier năm đầu = 0)
> - **EC2 t3.micro x2**: ~$15/tháng (Free Tier 750h/instance/tháng)
>
> **Tổng nếu hết Free Tier: ~$76/tháng**. Sau khi học xong demo → `terraform destroy` 4 stack theo thứ tự ngược: alb → database → compute → network.

---

## 📚 Lý thuyết

### 4 thành phần ALB
1. **Load Balancer** — frontend public.
2. **Target Group** — pool backend (EC2/Lambda/IP).
3. **Listener** — rule "port 80 → forward TG này".
4. **(Optional) Listener Rule** — routing nâng cao theo path/host.

### Flow request
```
Client → ALB (public) → TG (health check OK) → EC2 (private) → nginx
                       ┌─────────────┐
                       │ ASG attach │ register-deregister tự động
                       └─────────────┘
```

### SG nối tiếp (chained)
```
ALB SG     ←  inbound 80 từ 0.0.0.0/0
   ↓ outbound 80 → EC2 SG
EC2 SG     ←  inbound 80 từ ALB SG  (KHÔNG dùng cidr_blocks nữa)
   ↓ outbound 3306 → DB SG
DB SG      ←  inbound 3306 từ EC2 SG
```

---

## 🧭 Các bước thực hành

### Bước 1 — Các stack trước phải đang chạy
- Buổi 10 (network) ✅
- Buổi 11 (compute) ✅
- Buổi 12 (database) ✅

Nếu chưa, apply lại theo thứ tự.

### Bước 2 — Cấu hình env dev
Lấy đầy đủ output từ 3 buổi trước, điền `terraform.tfvars`:
- `vpc_id`, `public_subnet_ids` (buổi 10)
- `asg_name`, `ec2_security_group_id` (buổi 11)

### Bước 3 — Apply
```bash
cd envs/dev
terraform init
terraform plan
terraform apply
```

### Bước 4 — Test

**Linux/macOS / Git Bash**:
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://$ALB_DNS
# Lặp lại vài lần — sẽ thấy instance ID khác nhau (ALB round-robin)
for i in {1..5}; do curl -s http://$ALB_DNS | grep -i "Hello"; done
```

**Windows PowerShell**:
```powershell
$ALB_DNS = terraform output -raw alb_dns_name
curl.exe http://$ALB_DNS    # dùng curl.exe để tránh alias Invoke-WebRequest
# Lặp 5 lần
1..5 | ForEach-Object { curl.exe -s http://$ALB_DNS | Select-String "Hello" }
```

> 💡 Có thể test EC2 → RDS từ Session Manager (đã setup ở B11): `mysql -h <db_endpoint> -u admin -p` (password lấy từ Secrets Manager) — chốt mạch B11 + B12 + B13.

### Bước 5 — Verify health check
AWS Console → EC2 → Target Groups → chọn TG → Targets tab → trạng thái phải là **healthy**.

### Bước 6 — Destroy theo thứ tự NGƯỢC
```bash
# Buổi 13 (alb)
terraform destroy

# Buổi 12 (database)
cd ../../buoi-12-project1-database/envs/dev && terraform destroy

# Buổi 11 (compute)
cd ../../buoi-11-project1-compute/envs/dev && terraform destroy

# Buổi 10 (network) — XÓA CUỐI CÙNG vì các thứ trên đều ref VPC
cd ../../buoi-10-project1-network/envs/dev && terraform destroy
```

> Mỗi `destroy` mất 1-5 phút. RDS lâu nhất, NAT cũng lâu.

---

## ✅ Đầu ra checklist

- [ ] Module `modules/alb/` có đủ file.
- [ ] ALB internet-facing ở 2 public subnet.
- [ ] Target Group port 80, health check path `/`, healthy threshold 2.
- [ ] Listener port 80 forward TG.
- [ ] ALB SG: inbound 80 từ `0.0.0.0/0`, outbound to EC2 SG.
- [ ] `aws_security_group_rule` thêm: EC2 SG inbound 80 từ ALB SG.
- [ ] `aws_autoscaling_attachment` gắn ASG buổi 11 vào TG.
- [ ] Output `alb_dns_name`.
- [ ] `curl http://<alb-dns>` trả 200 + nội dung "Hello from i-xxxx".
- [ ] Health check passing trên Console.
- [ ] Destroy sạch sẽ 4 stack theo thứ tự ngược.

---

## 🧯 Common errors

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| Health check unhealthy | nginx chưa chạy, hoặc EC2 SG block ALB SG | SSM vào EC2: `systemctl status nginx`. Check SG rule. |
| `curl` connection refused | ALB chưa active (~2-3 phút sau apply) | Chờ thêm |
| `curl` timeout | ALB SG không mở 0.0.0.0/0 | Verify SG inbound |
| ASG không register vào TG | Quên `aws_autoscaling_attachment` | Check resource trong main.tf |
| Destroy ALB treo | ENI của ALB đang được dùng | Chờ vài phút, hoặc `aws ec2 describe-network-interfaces` xem ai giữ |

---

## 🤔 Câu hỏi tự ôn

1. ALB internet-facing vs internal — khác nhau?
2. ALB hoạt động ở layer mấy của OSI? (Hint: Layer 7).
3. Health check failed → ALB làm gì với instance?
4. Có nên gắn EIP cho ALB không? (Trả lời: KHÔNG — ALB DNS auto, dùng Route53 alias).
5. ALB charge tiền theo cái gì? (Hint: hour + LCU).
6. Tại sao ASG đặt ở private subnet mà ALB ở public?

---

## 📂 Cấu trúc folder

```
buoi-13-project1-alb-finish/
├── README.md
├── .gitignore
├── modules/
│   └── alb/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── README.md
└── envs/
    └── dev/
        ├── main.tf            ← gọi cả 4 module: network/compute/database/alb (qua input)
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        ├── backend.tf
        └── terraform.tfvars.example
```
