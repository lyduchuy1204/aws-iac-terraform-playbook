# 🎓 Buổi 05 — Data Sources & Dependencies

> Buổi này học cách **đọc** thông tin có sẵn trên AWS bằng `data` block, và hiểu cách Terraform tự suy ra **dependency graph** giữa các resource.

---

## 🎯 Mục tiêu

- Hiểu khác biệt giữa `resource` (Terraform sở hữu) và `data` (Terraform chỉ đọc).
- Dùng được các data source phổ biến: `aws_caller_identity`, `aws_region`, `aws_availability_zones`, `aws_ami`, `aws_vpc`.
- Lấy AMI Amazon Linux 2023 mới nhất qua filter — tránh hardcode AMI ID.
- Phân biệt **implicit** dependency (Terraform tự suy ra) và **explicit** dependency (`depends_on`).
- Vẽ và đọc được Terraform graph.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| Data source | query thông tin có sẵn trên AWS, KHÔNG tạo |
| `aws_caller_identity` | account ID + ARN của caller hiện tại |
| `aws_ami` | query AMI mới nhất theo filter |
| Implicit dependency | tự suy ra qua reference giữa resource |
| Explicit dependency | khai báo `depends_on = [...]` |
| Terraform graph | DAG mô tả thứ tự thực thi resource |

---

## 📚 Lý thuyết ngắn

### Data source là gì?

```hcl
data "aws_caller_identity" "current" {}
```

- Cú pháp giống `resource` nhưng từ khoá là `data`.
- Terraform CHỈ ĐỌC từ AWS, KHÔNG tạo/xoá gì.
- Truy xuất qua `data.<type>.<name>.<attribute>`.
- Refresh mỗi lần `plan/apply` — luôn lấy giá trị mới nhất.

### Khi nào dùng?

| Tình huống | Resource hay Data? |
|---|---|
| Tạo VPC mới | `resource` |
| Lấy ID VPC default có sẵn | `data` |
| Tạo AMI custom | `resource "aws_ami_copy"` |
| Lấy AMI Amazon Linux mới nhất | `data "aws_ami"` |
| Tạo IAM role | `resource` |
| Lấy account ID đang chạy | `data "aws_caller_identity"` |

### Implicit vs Explicit dependency

**Implicit** — Terraform tự nhận diện qua reference:

```hcl
resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id   # ← reference sang aws_vpc.main
                             #    Terraform tự biết SG phụ thuộc VPC
}
```

**Explicit** — khi không có reference trực tiếp nhưng vẫn cần thứ tự:

```hcl
resource "aws_lambda_function" "app" {
  # ...
  depends_on = [aws_iam_role_policy_attachment.lambda_logs]
  # Lambda cần policy attached XONG mới invoke được, nhưng không reference trực tiếp.
}
```

> **Quy tắc**: ưu tiên implicit, chỉ dùng `depends_on` khi thực sự cần (đa số là cho Lambda + IAM, hoặc S3 bucket policy).

### Terraform graph

`terraform graph` xuất ra DAG (Directed Acyclic Graph) ở DOT format. Khi gặp lỗi "cycle detected" ↔ có dependency vòng tròn cần phá.

---

## 🛠️ Các bước thực hành

### Bước 1 — Init & Apply

```bash
cd buoi-05-data-sources
terraform init
terraform plan
terraform apply
```

> 💡 Vì buổi này **chỉ có data source**, không có `resource`, nên `apply` không tạo gì trên AWS. Hoàn toàn miễn phí.

### Bước 2 — Đọc output

Sau apply, console sẽ in ra:

```
account_id                = "123456789012"
amazon_linux_2023_ami_id  = "ami-0abcd1234ef567890"
amazon_linux_2023_ami_name = "al2023-ami-2023.4.20240611.0-kernel-6.1-x86_64"
available_azs             = [
  "ap-southeast-1a",
  "ap-southeast-1b",
  "ap-southeast-1c",
]
caller_arn                = "arn:aws:iam::123456789012:user/terraform-learner"
current_region            = "ap-southeast-1"
default_vpc_cidr          = "172.31.0.0/16"
default_vpc_id            = "vpc-0abc..."
```

### Bước 3 — Truy vấn 1 output cụ thể

```bash
terraform output amazon_linux_2023_ami_id
terraform output -json available_azs
```

### Bước 4 — Vẽ dependency graph

```bash
# Cần Graphviz: brew install graphviz | choco install graphviz | apt install graphviz
terraform graph | dot -Tpng > graph.png
```

Mở `graph.png` xem các data source là các node độc lập (không có cạnh nối), vì chúng không phụ thuộc lẫn nhau.

### Bước 5 — Thử thay đổi region

```bash
terraform apply -var="region=us-east-1"
```

Quan sát: AMI ID, AZ list, account ID không đổi (account toàn cầu). Region và AZ thì đổi.

### Bước 6 — Dọn dẹp

```bash
terraform destroy
```

Lệnh này không xoá gì trên AWS (vì không có resource), chỉ dọn state local.

---

## ✅ Đầu ra (Checklist)

- [ ] `terraform apply` ra đủ 8 output (account_id, caller_arn, current_region, available_azs, ami_id, ami_name, default_vpc_id, default_vpc_cidr).
- [ ] Hiểu khác biệt `data` vs `resource`.
- [ ] Hiểu `most_recent = true` + `owners = ["amazon"]` đảm bảo lấy AMI chính thức mới nhất.
- [ ] Vẽ được graph với `terraform graph | dot -Tpng > graph.png`.
- [ ] Giải thích được khi nào cần `depends_on`.

---

## 🐞 Common Errors

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| `your query returned no results` ở `aws_ami` | Filter quá chặt hoặc sai pattern name | Bỏ bớt filter, kiểm tra `aws ec2 describe-images --owners amazon --filters Name=name,Values='al2023-*'` |
| `multiple AMIs match` | Quên `most_recent = true` | Thêm `most_recent = true` |
| `default VPC not found` | Account đã xoá default VPC | Bỏ data source `aws_vpc.default` hoặc tạo VPC riêng |
| `Error: error configuring Terraform AWS Provider: no valid credential sources` | Chưa setup AWS CLI | `aws configure` (xem buổi 00) |
| `dot: command not found` | Chưa cài Graphviz | `brew install graphviz` (mac), `choco install graphviz` (Win) |

---

## ❓ Câu hỏi tự ôn

1. Phân biệt `resource` và `data` block — cái nào tạo/xoá tài nguyên trên AWS?
2. Vì sao **không nên hardcode** AMI ID trong code?
3. `most_recent = true` trong `data "aws_ami"` có ý nghĩa gì? Nếu bỏ ra thì sao?
4. Implicit dependency vs explicit dependency — cho 1 ví dụ mỗi loại.
5. Khi nào thật sự cần `depends_on`? Lạm dụng `depends_on` có hại gì?
6. `data.aws_caller_identity.current.account_id` — dùng `data` hay `resource`? Vì sao?
7. Output `available_azs` có thay đổi nếu chạy lại apply ở thời điểm khác không? Vì sao có/không?

---

## 📚 Tham khảo

- [Terraform — Data Sources](https://developer.hashicorp.com/terraform/language/data-sources)
- [aws_ami data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)
- [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)
- [Resource Graph](https://developer.hashicorp.com/terraform/internals/graph)

---

➡️ **Buổi tiếp theo**: [Buổi 06 — Remote State (S3 native locking)](../buoi-06-remote-state/README.md)
