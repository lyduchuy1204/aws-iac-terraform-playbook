# 🎓 Buổi 18 — Project 2: Lambda + DynamoDB

> **Thời lượng**: ~3 giờ · **Loại**: Project 2 (phần 1/3) · **Code thực hành**: ✅

---

## 🎯 Mục tiêu

Xây phần backend serverless đầu tiên cho Project 2:

- DynamoDB table `items` lưu dữ liệu, billing on-demand (PAY_PER_REQUEST).
- Lambda **Node.js 22** (runtime LTS hiện tại, vì Node 18 EOL 31/03/2026, Node 20 sắp tới) đọc/ghi DynamoDB qua AWS SDK v3.
- IAM Role least privilege, chỉ cho Lambda đụng đúng table này.
- CloudWatch Log Group có retention rõ ràng (7 ngày) — không để log "ngấm tiền".
- Bộ module `lambda` + `dynamodb` tái dùng được cho buổi 19 (gắn API Gateway).

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| Lambda | Function-as-a-service của AWS, chạy code không cần server |
| Runtime | Phiên bản ngôn ngữ Lambda chạy (vd `nodejs22.x`) |
| Handler | Format `<file>.<exported_function>` (vd `handler.handler`) |
| DynamoDB | NoSQL key-value/document database managed |
| PAY_PER_REQUEST | Billing on-demand, không phải provisioned capacity |
| AWS SDK v3 | Bộ thư viện gọi AWS API mới (modular, tree-shakable) |
| `archive_file` | Data source zip thư mục thành file zip cho Lambda |

---

## 📚 Lý thuyết tóm tắt

### Vì sao chọn Lambda + DynamoDB cho Project 2

- **Free tier rộng**: Lambda free 1M request/tháng, DynamoDB on-demand mức học gần như $0, KHÔNG có cost giờ chạy như EC2/RDS.
- **Cấu trúc đơn giản**: 1 Lambda + 1 table đủ minh hoạ CRUD, sau đó gắn API Gateway ở buổi 19.
- **Phù hợp dạy IAM least privilege**: Lambda execution role là ví dụ điển hình.

### Node.js 22 trên Lambda

| Runtime | Trạng thái | Ghi chú |
|---|---|---|
| `nodejs18.x` | ❌ End of support 31/03/2026 | KHÔNG dùng cho code mới |
| `nodejs20.x` | ⚠️ Sắp deprecate | Dùng tạm được, nhưng nên migrate |
| `nodejs22.x` | ✅ LTS hiện tại | **Khuyến nghị** |

> 📌 Playbook này luôn dùng `nodejs22.x`. Khi Node 24 lên LTS, đổi thành `nodejs24.x`.

### AWS SDK v3 vs v2

- **v2** (`aws-sdk`) đã end of maintenance từ 09/2024.
- **v3** (`@aws-sdk/client-*`) modular, tree-shakable, **đã có sẵn trên Lambda runtime Node 18+** nhưng vẫn nên `npm install` để pin version trong package.

Buổi này dùng:
- `@aws-sdk/client-dynamodb` — low-level client.
- `@aws-sdk/lib-dynamodb` — DocumentClient wrapper, marshalling/unmarshalling tự động.

### IAM least privilege cho Lambda

Trust policy: chỉ `lambda.amazonaws.com` được assume.

Permissions policy:
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` — phạm vi log group cụ thể.
- `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:Scan` — phạm vi ARN table cụ thể (KHÔNG `*`).

### Đóng gói code Lambda với `archive_file`

- `data "archive_file"` của provider `hashicorp/archive` zip thư mục `src/` thành `lambda.zip` ngay khi `terraform plan/apply`.
- `source_code_hash` truyền `archive_file.this.output_base64sha256` để Terraform phát hiện code thay đổi và update Lambda.
- Nếu có `node_modules` (do `npm install`), tốt nhất chạy `npm ci --omit=dev` trước rồi để `archive_file` zip cả `src/` + `node_modules`.

---

## 🗂️ Cấu trúc folder

```
buoi-18-project2-lambda-ddb/
├── README.md                         ← bạn đang đọc
├── src/
│   ├── handler.js                    ← Node.js 22, CRUD DynamoDB
│   └── package.json                  ← khai báo dependency SDK v3
├── modules/
│   ├── lambda/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── dynamodb/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
└── envs/
    └── dev/
        ├── main.tf                   ← gọi 2 module trên
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        ├── backend.tf                ← S3 native locking (buổi 06)
        └── terraform.tfvars.example  ← KHÔNG commit tfvars thật
```

---

## 🛠️ Các bước thực hành

### Bước 1 — Cài dependency cho Lambda code

```bash
cd buoi-18-project2-lambda-ddb/src
npm install
```

> Dependency đã khai báo sẵn trong `package.json`: `@aws-sdk/client-dynamodb`, `@aws-sdk/lib-dynamodb`. Khi chạy `npm install`, `node_modules` sinh ra trong `src/`, sẽ được `archive_file` zip kèm.

### Bước 2 — Xem cấu trúc 2 module

- `modules/dynamodb/` tạo `aws_dynamodb_table` với `billing_mode = "PAY_PER_REQUEST"`, `hash_key = "id"`. Output `table_arn`, `table_name` để Lambda module dùng.
- `modules/lambda/`:
  - `data "archive_file"` zip `../../src` thành `lambda.zip`.
  - `aws_lambda_function` với `runtime = "nodejs22.x"`, `handler = "handler.handler"`, env var `TABLE_NAME`.
  - `aws_cloudwatch_log_group` retention 7 ngày, name `/aws/lambda/<function_name>`.
  - `aws_iam_role` + `aws_iam_role_policy` least privilege gắn vào Lambda.

### Bước 3 — Khởi tạo & apply env dev

```bash
cd envs/dev
cp terraform.tfvars.example terraform.tfvars   # sửa nếu cần
terraform init
terraform plan
terraform apply
```

### Bước 4 — Test Lambda

#### Test PUT item:

```bash
aws lambda invoke \
  --function-name $(terraform output -raw lambda_function_name) \
  --cli-binary-format raw-in-base64-out \
  --payload '{"httpMethod":"POST","body":"{\"id\":\"1\",\"name\":\"Coffee\",\"price\":35000}"}' \
  response.json
cat response.json
```

#### Test GET list:

```bash
aws lambda invoke \
  --function-name $(terraform output -raw lambda_function_name) \
  --cli-binary-format raw-in-base64-out \
  --payload '{"httpMethod":"GET"}' \
  response.json
cat response.json
```

#### Xem log:

```bash
aws logs tail /aws/lambda/$(terraform output -raw lambda_function_name) --follow
```

### Bước 5 — Destroy sau buổi học

```bash
terraform destroy
```

---

## ✅ Đầu ra checklist

- [ ] `terraform apply` thành công, không có warning về deprecated arg.
- [ ] DynamoDB table `items` xuất hiện trên Console, billing = On-demand.
- [ ] Lambda function `runtime = nodejs22.x`, env var `TABLE_NAME` đúng.
- [ ] IAM Role của Lambda **chỉ** có `dynamodb:GetItem/PutItem/Scan` ở ARN table cụ thể (không phải `*`).
- [ ] CloudWatch Log Group `/aws/lambda/<name>` retention = 7 ngày.
- [ ] Test PUT 1 item → GET thấy item đó trong response.
- [ ] Log Lambda hiện trên CloudWatch Logs, không có lỗi permission.
- [ ] `terraform destroy` clean, không còn resource thừa.

---

## 🐛 Common errors

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `Runtime nodejs18.x is no longer supported` | Để runtime cũ | Đổi `runtime = "nodejs22.x"` |
| `AccessDeniedException: ... dynamodb:PutItem` | IAM policy thiếu action hoặc sai ARN | Kiểm tra `Resource` trong policy đúng `aws_dynamodb_table.this.arn` |
| `archive_file` không cập nhật khi sửa code | Quên truyền `source_code_hash` | Set `source_code_hash = data.archive_file.this.output_base64sha256` |
| `Cannot find module '@aws-sdk/lib-dynamodb'` | Quên `npm install` trong `src/` | `cd src && npm install` rồi `terraform apply` lại |
| Log group bị lỗi `already exists` | Lambda tự tạo log group trước Terraform | Import log group sẵn có (`terraform import`) hoặc đặt `depends_on` cho Lambda phụ thuộc log group |
| Lambda timeout (3s mặc định) | DynamoDB cold start hoặc payload lớn | Đặt `timeout = 10` trong module |

> 💡 **Mẹo về log group**: tạo `aws_cloudwatch_log_group` **trước** rồi để Lambda phụ thuộc nó (qua `depends_on`) — như vậy retention được set ngay từ đầu, tránh case Lambda tự sinh log group không có retention.

---

## ❓ Câu hỏi tự ôn

1. Vì sao Lambda runtime `nodejs18.x` không nên dùng cho code mới ở 2025+?
2. AWS SDK v3 khác v2 ở điểm nào? Vì sao SDK v3 đã có sẵn trên Lambda nhưng vẫn nên `npm install`?
3. Trong IAM policy của Lambda, vì sao phải dùng ARN table cụ thể thay vì `Resource = "*"`?
4. `source_code_hash` của Lambda dùng để làm gì? Chuyện gì xảy ra nếu không set?
5. DynamoDB `PAY_PER_REQUEST` vs `PROVISIONED` — chọn cái nào cho workload học/dev và vì sao?
6. Vì sao tạo CloudWatch Log Group bằng Terraform trước thay vì để Lambda tự tạo?

---

## 📚 Tham khảo

- [AWS Lambda Node.js runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-nodejs.html)
- [Lambda runtime support policy](https://docs.aws.amazon.com/lambda/latest/dg/runtime-support-policy.html)
- [AWS SDK v3 — DynamoDB DocumentClient](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/Package/-aws-sdk-lib-dynamodb/)
- [Terraform `archive_file` data source](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file)
- [`aws_lambda_function`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)
- [`aws_dynamodb_table`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table)

➡️ **Buổi tiếp theo**: [Buổi 19 — API Gateway](../buoi-19-project2-apigateway/README.md)
