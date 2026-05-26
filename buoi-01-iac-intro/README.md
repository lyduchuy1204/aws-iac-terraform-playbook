# 🎓 Buổi 01 — IaC & Terraform là gì

> **Thời lượng**: ~1 giờ · **Loại**: Lý thuyết · **Code thực hành**: ❌ (chưa có)

---

## 🎯 Mục tiêu

- Trả lời được câu hỏi: "tại sao cần IaC?"
- Mô tả được vòng đời Terraform: `init → plan → apply → destroy`.
- Phân biệt Terraform vs CloudFormation vs CDK vs Pulumi.
- Hiểu **state** là gì, vì sao Terraform cần và nó nguy hiểm thế nào.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| IaC | Infrastructure as Code, mô tả hạ tầng bằng code |
| Provider | Plugin Terraform gọi API của 1 platform (aws, azurerm…) |
| Declarative | Mô tả "muốn gì", không phải "làm như nào" |
| State | File Terraform ghi nhận resource đang quản lý |
| Drift | Chênh lệch giữa state và reality |
| Lock | Cơ chế chặn 2 process cùng sửa state |
| Plan | Dry-run xem trước thay đổi |
| Apply | Thực thi thay đổi |

---

## 📚 Lý thuyết tóm tắt

**Infrastructure as Code (IaC)** là dùng file code (text) để mô tả hạ tầng (server, network, DB...) thay vì bấm tay trên Console. Lợi ích chính: **versionable** (Git track lịch sử), **repeatable** (apply lại ra cùng kết quả), **reviewable** (PR review), **automatable** (CI/CD).

**Terraform** là công cụ IaC của HashiCorp, dùng ngôn ngữ HCL (HashiCorp Configuration Language). Nó **declarative** (mô tả "muốn gì", không phải "làm như nào") và **provider-based** (gọi API của AWS, Azure, GCP, Cloudflare... qua các plugin gọi là provider).

Khi bạn `terraform apply`, Terraform so sánh:
- **Code** (`.tf` files) — bạn muốn gì.
- **State** (`terraform.tfstate`) — Terraform nghĩ thế giới hiện đang thế nào.
- **Reality** (refresh từ AWS API) — thế giới đang thực sự thế nào.

Rồi nó tính ra **diff** và thực hiện các API call cần thiết để đưa reality về khớp code.

---

## 🔄 Vòng đời Terraform

```
┌──────────────┐
│  Viết .tf    │  Bạn mô tả hạ tầng mong muốn
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ terraform    │  Tải provider (aws, random...) về .terraform/
│   init       │  Khởi tạo backend (nơi lưu state)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ terraform    │  So sánh: code vs state vs reality
│   plan       │  In ra plan: + create / ~ update / - destroy
└──────┬───────┘
       │  (review plan)
       ▼
┌──────────────┐
│ terraform    │  Thực thi plan: gọi API tạo/sửa/xoá resource
│   apply      │  Cập nhật state file
└──────┬───────┘
       │  (resource đang chạy)
       ▼
┌──────────────┐
│ terraform    │  Xoá tất cả resource Terraform quản lý
│   destroy    │  Dọn state về rỗng
└──────────────┘
```

> **Quy tắc vàng**: KHÔNG BAO GIỜ `apply` mà chưa đọc kỹ output của `plan`.

---

## 🆚 Terraform vs CloudFormation vs CDK vs Pulumi

| Tiêu chí | Terraform | CloudFormation | CDK | Pulumi |
|---|---|---|---|---|
| **Vendor** | HashiCorp | AWS | AWS | Pulumi |
| **Multi-cloud** | ✅ (1700+ providers) | ❌ AWS only | ❌ AWS only (CDK), ✅ với CDKTF | ✅ |
| **Ngôn ngữ** | HCL (DSL) | YAML/JSON | TypeScript/Python/Java/.NET | TypeScript/Python/Go/.NET |
| **Declarative?** | ✅ | ✅ | ⚠️ Imperative compile ra CFN declarative | ⚠️ Imperative (state-based) |
| **State** | File `.tfstate` (cần backend) | Quản lý bởi AWS (stack) | Quản lý bởi AWS (stack) | File state (cần backend) |
| **Đường cong học** | Trung bình (HCL nhỏ gọn) | Dễ với syntax YAML, khó với template phức tạp | Cao (cần biết lập trình) | Trung bình (nếu đã biết TS/Python) |
| **Drift detection** | `terraform plan` | CloudFormation drift detection | (qua CFN) | `pulumi refresh` |
| **Best for** | Multi-cloud, team có DevOps thuần | Team chỉ AWS, không muốn cài thêm tool | Team developer thích viết code thay vì DSL | Team developer muốn IaC bằng ngôn ngữ chính |

**Khi nào chọn Terraform?**
- Multi-cloud hoặc đa provider (AWS + Cloudflare + GitHub + Datadog...).
- Cộng đồng module lớn (Terraform Registry).
- Team DevOps thuần, không nhất thiết phải biết TypeScript/Python.

**Khi nào chọn CloudFormation?**
- 100% AWS, muốn tích hợp sâu (StackSets, Service Catalog).
- Không muốn cài thêm tool ngoài AWS Console/CLI.

**Khi nào chọn CDK / Pulumi?**
- Team developer muốn dùng ngôn ngữ thật để tạo abstraction (loops, conditions phức tạp).
- Đã có codebase TypeScript/Python lớn, muốn IaC chung ngôn ngữ.

---

## 💾 State là gì? Vì sao cần?

**State** là file Terraform ghi nhận "tôi đã tạo những resource gì, ID là gì, attributes là gì". Mặc định lưu local ở `terraform.tfstate`.

**Vì sao cần?**
1. **Mapping**: HCL chỉ có tên (`aws_s3_bucket.this`). State map nó → real AWS ID (`my-bucket-abc123`).
2. **Performance**: Không phải mỗi `plan` đi list hết tất cả resource trên AWS — chỉ refresh những cái trong state.
3. **Dependency**: State lưu metadata để Terraform biết thứ tự destroy ngược lại với create.
4. **Diff**: Terraform so sánh state vs code để biết phải làm gì.

**Vì sao state nguy hiểm?**
- Chứa **secret** ở plain text (DB password, RDS endpoint, ARN secret...).
- Mất state = Terraform "quên" mình đang quản lý resource → lần `apply` tới sẽ tạo TRÙNG hoặc KHÔNG xoá được resource cũ.
- 2 người chạy `apply` cùng lúc trên cùng state = corrupt state. **Cần lock**.

**Giải pháp** (sẽ học chi tiết ở buổi 06):
- Lưu state trên S3 (remote backend) thay vì local.
- Bật S3 versioning (rollback được).
- Bật S3 native locking (`use_lockfile = true` từ Terraform 1.10+).
- KHÔNG bao giờ commit `terraform.tfstate` vào Git.

---

## 🛠️ Hoạt động trong buổi này (không có code)

1. **Đọc lại lý thuyết** ở trên 2 lần. Vẽ ra giấy sơ đồ `init → plan → apply → destroy`.
2. **Xem video** giới thiệu Terraform của HashiCorp (15 phút):
   - https://developer.hashicorp.com/terraform/intro
3. **Đọc** trang [What is Terraform](https://developer.hashicorp.com/terraform/intro) trên docs chính thức.
4. **Trả lời 5 câu hỏi tự ôn ở dưới** (viết ra giấy hoặc Notion, không tra Google ở lần đầu).

---

## ✅ Đầu ra checklist

- [ ] Vẽ được sơ đồ `init → plan → apply → destroy` mà không nhìn tài liệu.
- [ ] Liệt kê được 3 lý do dùng IaC thay vì click Console.
- [ ] Phân biệt được Terraform vs CloudFormation vs CDK (ít nhất 2 điểm khác biệt mỗi cặp).
- [ ] Giải thích được state là gì và 2 lý do nó nguy hiểm.
- [ ] Trả lời được 5 câu hỏi tự ôn.

---

## ❓ Câu hỏi tự ôn

1. **Declarative vs Imperative**: Terraform là cái nào? Nêu 1 ví dụ cụ thể về cách Terraform xử lý "tôi muốn 3 EC2" khác với cách script Bash.
2. **Vì sao cần state file?** Nếu Terraform query AWS mỗi lần `plan` để biết hiện trạng thì có cần state không? Giải thích.
3. **Lock state**: Vì sao 2 người `apply` cùng lúc trên cùng 1 state lại nguy hiểm? Hậu quả cụ thể là gì?
4. **Multi-cloud**: Một công ty dùng AWS + Cloudflare + GitHub Enterprise. Họ chọn Terraform thay vì CloudFormation vì lý do gì?
5. **Plan trước Apply**: Terraform plan có "tạo" resource thật không? Vì sao team luôn yêu cầu `plan` ra artifact và review trong PR trước khi `apply`?

> 💡 Sau khi tự trả lời, đối chiếu với phần "Lý thuyết tóm tắt" và "State là gì" ở trên.

---

## 📚 Tham khảo

- [What is Terraform — HashiCorp](https://developer.hashicorp.com/terraform/intro)
- [Terraform vs CloudFormation — HashiCorp blog](https://www.hashicorp.com/resources/what-is-infrastructure-as-code)
- [State documentation](https://developer.hashicorp.com/terraform/language/state)

➡️ **Buổi tiếp theo**: [Buổi 02 — HCL Syntax cơ bản](../buoi-02-hcl-basics/README.md)
