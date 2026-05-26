# 🎓 Buổi 19 — Project 2: API Gateway

> **Thời lượng**: ~2 giờ · **Loại**: Project 2 (phần 2/3) · **Code thực hành**: ✅ · **Tiền đề**: hoàn thành buổi 18

---

## 🎯 Mục tiêu

Expose Lambda từ buổi 18 thành REST API public, có URL gọi được bằng `curl` từ máy bạn:

- API Gateway **REST API** (KHÔNG dùng HTTP API — playbook ở mức cơ bản, REST API có nhiều flag để học IAM, mapping template, deployment).
- Resource `/items`, method **GET** + **POST**.
- Integration **AWS_PROXY** với Lambda — Lambda nhận `event` đầy đủ thông tin HTTP, tự trả về `{ statusCode, body }`.
- Stage `dev` deploy được, có invoke URL.
- `aws_lambda_permission` cho API Gateway invoke Lambda (nếu thiếu sẽ bị 500 Internal Server Error).

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| API Gateway REST | API v1, đầy đủ feature (mapping template, API key…) |
| HTTP API | API v2, gọn hơn, rẻ hơn |
| Lambda Proxy Integration (AWS_PROXY) | API Gateway forward toàn bộ HTTP request làm event Lambda |
| Resource | Path trong API (vd `/items`) |
| Method | HTTP verb gắn vào resource (GET/POST/PUT/DELETE) |
| Stage | Pointer tới deployment, có invoke URL |
| `aws_lambda_permission` | Cho phép API Gateway invoke Lambda |

---

## 📚 Lý thuyết tóm tắt

### REST API vs HTTP API

| Tiêu chí | REST API | HTTP API |
|---|---|---|
| Tuổi đời | Cũ (v1) | Mới (v2, 2019) |
| Tính năng | Đầy đủ: API key, Usage Plan, Request Validator, mapping template, WAF | Tinh gọn |
| Giá | Đắt hơn (~$3.5/M request) | Rẻ hơn (~$1/M request) |
| Phù hợp | Học, enterprise feature | Production simple |

> Playbook chọn **REST API** vì mục đích học: Terraform resource model phức tạp hơn, dạy được nhiều thứ hơn (deployment, stage, method, integration tách rời).

### Lambda Proxy Integration (AWS_PROXY)

API Gateway forward toàn bộ HTTP request thành 1 JSON event chuẩn cho Lambda:

```json
{
  "httpMethod": "POST",
  "path": "/items",
  "headers": { "...": "..." },
  "queryStringParameters": null,
  "body": "{\"id\":\"1\",\"name\":\"Coffee\"}",
  "isBase64Encoded": false,
  "requestContext": { "...": "..." }
}
```

Lambda phải trả về object đúng shape:

```json
{ "statusCode": 200, "headers": { ... }, "body": "..." }
```

Code `src/handler.js` ở buổi 18 đã làm đúng việc này.

### Vì sao cần `aws_lambda_permission`

API Gateway gọi Lambda qua resource-based policy của Lambda (KHÔNG phải IAM role). Nếu thiếu, request trả về:

```
{"Message":"Internal server error"}
```

và CloudWatch Lambda **không thấy log** — lỗi bị chặn ở tầng API Gateway.

### `source_arn` trong `aws_lambda_permission` — pattern `*/*` nghĩa là gì?

```hcl
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
  #                                                          ▲ ▲
  #                                                          │ └─ HTTP method (GET/POST/...)
  #                                                          └─── stage (dev/prod/...)
}
```

`/*/*` đọc là: "cho phép API Gateway này invoke từ **mọi stage** + **mọi method**". Nếu muốn chặt hơn:
- `/dev/*` → chỉ stage `dev`, mọi method.
- `/dev/GET/items` → chỉ stage `dev`, method GET, path `/items`.

> 💡 Production thường dùng `/${stage}/*/*` để policy không phải update khi thêm method mới.

### `aws_api_gateway_deployment` vs `aws_api_gateway_stage`

- **Deployment** = snapshot config tại thời điểm đó.
- **Stage** = pointer tới 1 deployment, có URL công khai (`/dev`, `/prod`).
- Để deployment redeploy khi config đổi, dùng `triggers = { redeployment = sha1(jsonencode(...)) }`.
- Tách stage khỏi deployment giúp blue/green hoặc rollback nhanh (đổi pointer).

---

## 🗂️ Cấu trúc folder

```
buoi-19-project2-apigateway/
├── README.md
├── modules/
│   └── apigateway/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
└── envs/
    └── dev/
        ├── main.tf                   ← gọi module, lấy Lambda từ buổi 18
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        ├── backend.tf
        └── terraform.tfvars.example
```

> ⚠️ Lambda + DynamoDB ở buổi 18 phải được apply trước. Buổi 19 đọc output qua `terraform_remote_state` (hoặc bạn copy ARN qua tfvars). Cách dùng `terraform_remote_state` được show ở `envs/dev/main.tf`.

---

## 🛠️ Các bước thực hành

### Bước 1 — Chuẩn bị output từ buổi 18

Buổi 18 đã `terraform apply` xong, có sẵn output `lambda_invoke_arn`, `lambda_function_name`. Hai cách lấy:

**Cách A — `terraform_remote_state`** (khuyến nghị):

```hcl
data "terraform_remote_state" "lambda" {
  backend = "s3"
  config = {
    bucket = "REPLACE-ME-tfstate-<account-id>"
    key    = "buoi-18-project2-lambda-ddb/dev/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
```

**Cách B — Truyền qua tfvars** (đơn giản hơn):

Copy giá trị từ `terraform output` của buổi 18 vào `terraform.tfvars` ở buổi 19.

### Bước 2 — Apply

```bash
cd envs/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

### Bước 3 — Test bằng `curl`

Lấy invoke URL:

```bash
INVOKE_URL=$(terraform output -raw invoke_url)
echo $INVOKE_URL
# Ví dụ: https://abc123def4.execute-api.ap-southeast-1.amazonaws.com/dev
```

#### Test POST tạo item:

```bash
curl -X POST "$INVOKE_URL/items" \
  -H "Content-Type: application/json" \
  -d '{"id":"1","name":"Coffee","price":35000}'
```

Kỳ vọng: `201 Created`, body `{ "message": "Item đã được lưu", ... }`.

#### Test GET danh sách:

```bash
curl "$INVOKE_URL/items"
```

Kỳ vọng: `200 OK`, body `{ "items": [...], "count": 1 }`.

#### Test method không hỗ trợ:

```bash
curl -X DELETE "$INVOKE_URL/items"
```

Kỳ vọng: `403` (API Gateway chặn ở level method) — vì module chỉ định nghĩa GET + POST.

## 🔒 Cảnh báo bảo mật: API public KHÔNG có auth

API Gateway tạo ở buổi này có invoke URL public, **KHÔNG có auth**. Bất kỳ ai có URL đều gọi được.

**Hậu quả nếu để chạy lâu**:
- Bot scan internet tìm endpoint API mở → spam request → tốn Lambda invocation + DynamoDB write.
- Có thể bị abuse làm worker (proxy, mining...).

**Quy tắc khi học**:
- Demo xong → `terraform destroy` ngay.
- Hoặc thêm API Key (xem `aws_api_gateway_api_key` + `aws_api_gateway_usage_plan`).
- Hoặc thêm Cognito Authorizer cho production.

Buổi 16 đã đề cập: `tfsec` sẽ cảnh báo `aws-api-gateway-no-public-access` — đây là rule nhắc bạn không để API public lâu.

---

### Bước 4 — Destroy

```bash
terraform destroy   # ở buổi 19 trước
cd ../../buoi-18-project2-lambda-ddb/envs/dev
terraform destroy   # rồi mới buổi 18
```

---

## ✅ Đầu ra checklist

- [ ] `terraform apply` thành công ở `envs/dev`.
- [ ] Trên Console: API Gateway có REST API, resource `/items`, method GET + POST, integration AWS_PROXY → Lambda.
- [ ] Stage `dev` đã được deploy, có invoke URL.
- [ ] `aws_lambda_permission` xuất hiện trên Lambda (Console → Lambda → Configuration → Permissions → Resource-based policy).
- [ ] `curl POST /items` trả về 201.
- [ ] `curl GET /items` trả về 200, list có item vừa tạo.
- [ ] CloudWatch log group của Lambda thấy invocation từ API Gateway (request id chứa `apigw`).
- [ ] `terraform destroy` clean.

---

## 🐛 Common errors

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `curl` trả về `{"Message":"Internal server error"}` | Thiếu `aws_lambda_permission` | Module đã có sẵn, kiểm tra `source_arn` đúng API Gateway execution ARN |
| `Missing Authentication Token` | Path sai (gõ `/item` thay vì `/items`) hoặc gọi vào root `/` | Kiểm tra resource path đã định nghĩa |
| Đổi handler nhưng API vẫn cũ | Deployment chưa redeploy | Module dùng `triggers = sha1(jsonencode(...))` để force redeploy. Nếu sửa method/resource phải apply lại |
| `403 Forbidden` | Method chưa định nghĩa hoặc `authorization = "NONE"` chưa set | Kiểm tra `aws_api_gateway_method` |
| Stage không có invoke URL | Quên tạo `aws_api_gateway_stage` riêng | Kiểm tra resource stage tách khỏi deployment |
| `BadRequestException: ... at least one resource` | Tạo deployment trước khi có method | `depends_on = [aws_api_gateway_integration.this]` |

---

## ❓ Câu hỏi tự ôn

1. REST API và HTTP API khác nhau ở những điểm nào? Vì sao playbook chọn REST API?
2. Lambda Proxy Integration là gì? Lambda nhận event có format thế nào?
3. Vì sao cần `aws_lambda_permission` riêng dù Lambda role đã có? Trust giữa API Gateway và Lambda là loại policy nào?
4. `aws_api_gateway_deployment` và `aws_api_gateway_stage` khác nhau ra sao? Vì sao phải tách?
5. Khi sửa code Lambda, cần redeploy API Gateway không? Vì sao?
6. Cách dùng `terraform_remote_state` để chia sẻ output giữa 2 stack?

---

## 📚 Tham khảo

- [API Gateway REST API resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api)
- [Lambda proxy integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)
- [REST vs HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vs-rest.html)
- [`terraform_remote_state`](https://developer.hashicorp.com/terraform/language/state/remote-state-data)

➡️ **Buổi tiếp theo**: [Buổi 20 — CI/CD GitHub Actions](../buoi-20-project2-cicd/README.md)
