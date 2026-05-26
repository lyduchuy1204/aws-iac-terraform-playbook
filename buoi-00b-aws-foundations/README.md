# 🎓 Buổi 00b — AWS Foundations cơ bản

> **Thời lượng**: ~2 giờ · **Loại**: Khái niệm + Console hands-on · **Code thực hành**: ❌ (KHÔNG dùng Terraform)

> 🎯 **Buổi này KHÔNG dùng Terraform**. Mục đích: hiểu khái niệm AWS trên Console trước, để khi vào Terraform không bị "double confusion" (vừa học khái niệm AWS, vừa học cú pháp Terraform).

---

## 🎯 Mục tiêu

- Hiểu các khái niệm nền tảng: Region, AZ, VPC, Subnet, Route Table, IGW, NAT, IAM, SG, NACL.
- Bấm tay tạo được 1 VPC + 1 EC2 trên Console, kết nối qua Session Manager.
- Phân biệt được EC2 / Lambda / Fargate (3 mức độ "serverless-ness").
- Đọc hiểu sơ đồ kiến trúc 3-tier sẽ dùng ở Project 1.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| VPC | Mạng riêng ảo trong 1 region, có CIDR riêng |
| Subnet | Dải IP nhỏ trong VPC, gắn với 1 AZ |
| IGW (Internet Gateway) | Cổng cho VPC ra internet 2 chiều |
| NAT Gateway | Cho subnet private ra internet 1 chiều (out-only) |
| Route Table | Bảng định tuyến traffic |
| IAM Role | "Vai" mà resource (vd EC2) đóng để có quyền tạm |
| Trust Policy | JSON định nghĩa AI được phép assume role này |
| Security Group | Firewall ở mức instance, stateful |
| NACL | Firewall ở mức subnet, stateless |

---

## 📚 Lý thuyết tóm tắt

- **Region** là một khu vực địa lý (ví dụ `ap-southeast-1` = Singapore). Mỗi region độc lập về dữ liệu và sự cố.
- **AZ (Availability Zone)** là một datacenter (hoặc cụm datacenter) trong region. Mỗi region có 2–6 AZ. Triển khai multi-AZ = HA.
- **VPC** là mạng riêng ảo trong 1 region, có CIDR riêng (ví dụ `10.0.0.0/16`).
- **Subnet** là một dải IP trong VPC, gắn với 1 AZ. Subnet có thể là **public** (có route ra IGW) hoặc **private** (không có).
- **Internet Gateway (IGW)** là cổng cho VPC ra internet 2 chiều.
- **NAT Gateway** cho subnet **private** ra internet 1 chiều (out-only). Tốn ~$32/tháng + traffic.
- **Route Table** quyết định traffic đi đâu. Mỗi subnet associate với 1 route table.
- **Security Group (SG)** = firewall ở mức instance, **stateful** (allow trả lời tự động).
- **NACL** = firewall ở mức subnet, **stateless** (phải mở cả inbound và outbound).
- **IAM**: User (con người), Role (resource đóng vai), Policy (quyền), Trust Policy (ai được assume role).

### Compute Spectrum: EC2 vs Fargate vs Lambda

| | **EC2** | **Fargate** | **Lambda** |
|---|---|---|---|
| Bạn quản lý | OS + runtime + app | Container image + cấu hình task | Code function |
| Tính tiền theo | Giờ instance chạy | Giờ task chạy (theo CPU/RAM cấp) | Số lần invoke + thời gian chạy (ms) |
| Scaling | Auto Scaling Group | ECS service / EKS HPA | Tự động (concurrency) |
| Cold start | Không (instance luôn chạy) | Có (~30s) | Có (~100-500ms) |
| Phù hợp | Workload truyền thống, cần quyền OS | Container hoá, không muốn quản node | Event-driven, request thưa, code nhỏ |

> 💡 **Cùng 1 spectrum**: từ "tự quản lý hết" (EC2) → "AWS quản lý hết, bạn chỉ viết function" (Lambda). Project 1 dùng EC2, Project 2 dùng Lambda — bạn sẽ trải nghiệm cả 2 đầu spectrum.

### Trust Policy là gì?

IAM Role có 2 loại policy:
- **Permissions policy** = "role này được làm gì" (ví dụ `AmazonSSMManagedInstanceCore`).
- **Trust policy** = "AI được phép assume role này".

Ví dụ trust policy cho EC2 role:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

Đọc là: "Cho phép service `ec2.amazonaws.com` assume role này". Không có dòng này, EC2 instance KHÔNG dùng được role.

Buổi 20 sẽ gặp lại Trust Policy phức tạp hơn cho GitHub Actions (OIDC).

---

## 🗺️ Sơ đồ ASCII — VPC điển hình 2 AZ

```
                              ┌────────────────────┐
                              │     INTERNET       │
                              └─────────┬──────────┘
                                        │
                              ┌─────────▼──────────┐
                              │  Internet Gateway  │
                              └─────────┬──────────┘
                                        │
┌───────────────────────────────────────┼──────────────────────────────────────┐
│ VPC  10.0.0.0/16              ap-southeast-1 (Singapore)                     │
│                                                                              │
│   ┌─────────────────────────────┐      ┌─────────────────────────────┐      │
│   │  AZ-1a                      │      │  AZ-1b                      │      │
│   │                             │      │                             │      │
│   │  ┌───────────────────────┐  │      │  ┌───────────────────────┐  │      │
│   │  │ Public Subnet         │  │      │  │ Public Subnet         │  │      │
│   │  │ 10.0.1.0/24           │  │      │  │ 10.0.2.0/24           │  │      │
│   │  │                       │  │      │  │                       │  │      │
│   │  │  [ALB]   [NAT GW] ────┼──┼──┐   │  │  [ALB]                │  │      │
│   │  └──────────┬────────────┘  │  │   │  └───────────────────────┘  │      │
│   │             │ (route to NAT)│  │   │                             │      │
│   │  ┌──────────▼────────────┐  │  │   │  ┌───────────────────────┐  │      │
│   │  │ Private Subnet        │  │  │   │  │ Private Subnet        │  │      │
│   │  │ 10.0.11.0/24          │  │  │   │  │ 10.0.12.0/24          │  │      │
│   │  │                       │  │  │   │  │                       │  │      │
│   │  │  [EC2/RDS]            │  │  │   │  │  [EC2/RDS]            │  │      │
│   │  └───────────────────────┘  │  │   │  └───────────────────────┘  │      │
│   └─────────────────────────────┘  │   └─────────────────────────────┘      │
│                                    │                                         │
│   Route Table (public): 0.0.0.0/0 → IGW                                     │
│   Route Table (private): 0.0.0.0/0 → NAT GW                                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

> Lưu ý: Để tiết kiệm tiền khi học, dùng **1 NAT Gateway duy nhất** cho cả 2 AZ (kém HA hơn nhưng rẻ hơn 2 lần).

---

## 🛠️ Các bước thực hành (Console only)

### Bước 1 — Vẽ VPC bằng giấy trước

Trước khi đụng Console, vẽ tay sơ đồ trên ra giấy. Ghi rõ:
- CIDR của VPC, từng subnet.
- Subnet nào public/private, ở AZ nào.
- Route table nào trỏ vào đâu.

### Bước 2 — Tạo VPC bằng VPC Wizard

1. Console → **VPC** → **Create VPC** → chọn **VPC and more** (đây là wizard).
2. Cấu hình:
   - Name: `learning-vpc`
   - IPv4 CIDR: `10.0.0.0/16`
   - Number of AZ: `2`
   - Public subnets: `2`
   - Private subnets: `2`
   - NAT gateways: `In 1 AZ` (tiết kiệm) — KHÔNG chọn "1 per AZ".
   - VPC endpoints: `None` (chưa cần).
3. **Create VPC**. Đợi 1–2 phút.

> AWS sẽ tự tạo: VPC, 4 subnet, 1 IGW, 1 NAT Gateway, route table public + private đã associate.

### Bước 3 — Tạo Security Group cho EC2

1. **VPC** → **Security Groups** → **Create security group**.
2. Name: `learning-ec2-sg`, VPC: `learning-vpc`.
3. Inbound rules: **không thêm gì** (Session Manager không cần SSH 22).
4. Outbound rules: để mặc định (allow all).
5. **Create**.

### Bước 4 — Tạo IAM Role cho EC2 (Session Manager)

1. **IAM** → **Roles** → **Create role**.
2. Trusted entity: **AWS service** → **EC2**.
3. Permissions: tìm và chọn `AmazonSSMManagedInstanceCore`.
4. Role name: `EC2-SSM-Role`.
5. **Create**.

### Bước 5 — Launch EC2

1. Console → **EC2** → **Launch instance**.
2. Name: `learning-ec2`.
3. AMI: **Amazon Linux 2023** (free tier eligible).
4. Instance type: `t3.micro` (free tier).
5. Key pair: **Proceed without a key pair** (dùng SSM, không cần SSH).
6. Network settings → **Edit**:
   - VPC: `learning-vpc`.
   - Subnet: chọn 1 **public subnet**.
   - Auto-assign public IP: **Enable**.
   - Security group: chọn `learning-ec2-sg`.
7. Advanced details → IAM instance profile: chọn `EC2-SSM-Role`.
8. **Launch instance**. Đợi state = `Running` + Status check 2/2.

### Bước 6 — Kết nối qua Session Manager

1. EC2 console → chọn instance → **Connect** → tab **Session Manager** → **Connect**.
2. Cửa sổ shell mở ra trong browser.
3. Test:

```bash
whoami            # ssm-user
cat /etc/os-release
curl -s ifconfig.me   # public IP của EC2
```

### Bước 7 — Bấm tay xem các route table

1. **VPC** → **Route tables** → chọn từng table:
   - Public RT: có rule `0.0.0.0/0 → igw-xxx`.
   - Private RT: có rule `0.0.0.0/0 → nat-xxx`.
2. Tab **Subnet associations** xem subnet nào gắn với RT nào.

### Bước 8 — XOÁ HẾT (quan trọng)

> 💰 **NAT Gateway tính tiền theo giờ + traffic. KHÔNG xoá = mất tiền mỗi ngày.**

Theo thứ tự (vì có dependency):

1. EC2 → **Terminate instance**.
2. VPC → **Your VPCs** → chọn `learning-vpc` → **Delete VPC** → check tất cả → confirm.
   - Wizard sẽ tự xoá: subnet, RT, IGW, NAT, EIP của NAT.
3. Verify: **Elastic IPs** không còn IP nào (NAT EIP) treo lại — nếu có, **Release**.

---

## 💰 Cost warning

| Resource | Cost (xấp xỉ) | Free tier? |
|---|---|---|
| **NAT Gateway** | **~$32/tháng** + $0.045/GB traffic | ❌ KHÔNG |
| EC2 t3.micro | $0 (free tier 12 tháng đầu) | ✅ 750h/tháng |
| EBS 8GB gp3 | $0 (free tier) | ✅ 30GB |
| Elastic IP (đang gắn vào NAT) | $0 | — |
| Elastic IP (idle, không gắn) | $0.005/giờ ≈ $3.6/tháng | ❌ |

> 🚨 Sau buổi học, kiểm tra tab **Elastic IPs** — bất kỳ EIP nào không gắn vào resource nào đều TỐN TIỀN.

---

## ✅ Đầu ra checklist

- [ ] Giải thích được: Region, AZ, VPC, Subnet (public/private), Route Table, IGW, NAT Gateway.
- [ ] Phân biệt được: IAM User vs Role, Policy vs Trust Policy.
- [ ] Phân biệt được: SG (stateful) vs NACL (stateless).
- [ ] Đã tạo 1 VPC + 1 EC2 + 1 IAM Role qua Console.
- [ ] Kết nối được EC2 qua Session Manager (KHÔNG dùng SSH key).
- [ ] **Đã xoá hết** resource sau khi xong (đặc biệt NAT Gateway).
- [ ] Hiểu khác biệt EC2 (VM full) / Fargate (container managed) / Lambda (function-as-a-service).

---

## 🐛 Common errors

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| Session Manager không kết nối | IAM Role chưa có policy `AmazonSSMManagedInstanceCore` | Attach policy vào role, reboot EC2 |
| Session Manager không kết nối (đã có policy) | Subnet private không có route ra NAT (SSM agent cần internet để gọi `ssm.ap-southeast-1.amazonaws.com`) | Đặt EC2 ở public subnet, hoặc tạo VPC Endpoint cho SSM |
| EC2 trong public subnet không có public IP | Quên bật **Auto-assign public IP** | Edit subnet settings, hoặc gắn EIP |
| Xoá VPC bị lỗi "has dependencies" | Còn EC2/NAT/ENI chưa xoá | Terminate EC2 trước, đợi NAT delete xong, rồi xoá VPC |
| EIP "InUse" nhưng không gắn vào instance nào | Đang gắn vào ENI của NAT đã delete | **Release** thủ công ở tab Elastic IPs |

---

## ❓ Câu hỏi tự ôn

1. Sự khác biệt giữa Region và AZ là gì? Một resource có thể span nhiều AZ không?
2. Public subnet và private subnet khác nhau ở yếu tố KỸ THUẬT nào (không phải tên)?
3. NAT Gateway và Internet Gateway, cái nào allow inbound từ internet?
4. SG là stateful nghĩa là gì? Nếu mở port 80 inbound, có phải mở thêm 80 outbound để response đi ra không?
5. IAM Role khác IAM User ở điểm nào? Vì sao EC2 dùng Role thay vì User+access key?

---

## 📚 Tham khảo

- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) — đọc 30 phút phần overview là đủ.
- [IAM User Guide — Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [Session Manager Setup](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started.html)

➡️ **Buổi tiếp theo**: [Buổi 01 — IaC & Terraform là gì](../buoi-01-iac-intro/README.md)
