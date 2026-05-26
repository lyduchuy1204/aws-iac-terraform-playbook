# 🎓 Buổi 20 — Project 2: GitHub Actions CI/CD (OIDC)

> **Thời lượng**: ~3 giờ · **Loại**: Project 2 (phần 3/3) · **Code thực hành**: ✅ · **Tiền đề**: hoàn thành buổi 18 + 19

---

## 🎯 Mục tiêu

Push code → CI tự động `plan/apply` Terraform, **KHÔNG cần access key dài hạn** trong GitHub Secrets.

- Dựng OIDC trust giữa GitHub Actions và AWS IAM (1 lần, qua stack `iam-bootstrap/`).
- IAM Role `github-actions-deployer` chỉ tin tưởng đúng repo của bạn.
- 3 workflow: plan trên PR, apply dev trên push main, apply prod trên git tag (manual approval).
- Hiểu vì sao OIDC an toàn hơn access key tĩnh.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| OIDC | OpenID Connect, chuẩn xác thực federation |
| JWT | JSON Web Token, chuỗi text được ký số |
| Issuer | Bên cấp JWT (GitHub: `token.actions.githubusercontent.com`) |
| `sub` claim | Trường định danh "ai" trong JWT |
| `aud` claim | Trường định danh "ai dùng token" (AWS: `sts.amazonaws.com`) |
| Trust policy | JSON ở IAM Role, định nghĩa ai được assume |
| AssumeRoleWithWebIdentity | API STS đổi JWT → AWS credentials tạm |

---

## 📚 Lý thuyết tóm tắt

### 📖 OIDC primer trong 5 phút (cho người chưa từng nghe)

> Đọc kỹ section này nếu bạn lần đầu nghe các từ JWT / OIDC / claim / issuer / federation.

**Vấn đề kinh điển**: GitHub Actions cần quyền truy cập AWS (để `terraform apply`). Cách cũ là tạo IAM access key, lưu vào GitHub Secrets. Nhưng access key là **chìa khóa vĩnh viễn** — leak ra là thảm họa.

**OIDC giải quyết bằng cơ chế "passport control"**:

```
   GitHub Actions                    AWS IAM
        │                               │
   1.   │ Job khởi động, GitHub tự sinh │
        │ JWT (như "passport tạm" 1h)   │
        │                               │
   2.   │──── "Tôi là job X của repo Y, ─►
        │     đây là passport ký bởi   │ "Để tôi check chữ ký..."
        │     GitHub (issuer)"          │
        │                               │
   3.   │                          ◄──── "Passport hợp lệ. Bạn nói
        │                               │  bạn là 'repo:lyduc/my-repo:*'.
        │                               │  Trust policy của tôi cho phép
        │                               │  pattern đó assume role này.
        │                               │  ĐÂY là credentials tạm 1h."
        │                               │
   4.   │ Dùng credentials tạm để       │
        │ gọi terraform apply            │
        ▼                               ▼
```

**Các từ khóa bạn vừa gặp**:

| Từ | Nghĩa cho người mới |
|---|---|
| **JWT** (JSON Web Token) | Chuỗi text được ký số. Decode ra là 1 JSON gồm các "claim" (mệnh đề). Dán vào https://jwt.io xem nội dung. |
| **Issuer** | "Quốc gia" cấp passport. Trong OIDC GitHub: `https://token.actions.githubusercontent.com`. |
| **Subject (`sub`)** | Trường quan trọng nhất trong JWT. Đại diện "ai đang xin quyền". GitHub set `sub` theo định dạng: `repo:<owner>/<repo>:<context>` (ví dụ `repo:lyduc/my-repo:ref:refs/heads/main`). |
| **Audience (`aud`)** | "Quốc gia muốn vào". Với AWS: `sts.amazonaws.com`. |
| **Trust policy** | "Quy định nhập cảnh" của AWS Role: passport phải đúng issuer + sub + aud thì mới cho assume. |
| **Federation** | Cơ chế tin tưởng chéo giữa 2 hệ identity (GitHub ↔ AWS). |
| **STS AssumeRoleWithWebIdentity** | API AWS đổi JWT → credentials AWS tạm 1h. |

**Cách xem JWT thực tế từ GitHub Actions**:

Trong workflow, thêm step debug 1 lần để xem:

```yaml
- name: Debug — xem JWT claim
  run: |
    REQ_TOKEN=$(curl -s -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
      "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" | jq -r .value)
    echo "$REQ_TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq .
  env:
    ACTIONS_ID_TOKEN_REQUEST_TOKEN: ${{ env.ACTIONS_ID_TOKEN_REQUEST_TOKEN }}
    ACTIONS_ID_TOKEN_REQUEST_URL: ${{ env.ACTIONS_ID_TOKEN_REQUEST_URL }}
```

> 📌 **Hai biến `ACTIONS_ID_TOKEN_REQUEST_*` từ đâu ra?**
> GitHub Actions **tự động inject** 2 biến này vào job khi workflow có `permissions: id-token: write`. Nếu thiếu permission đó, biến sẽ KHÔNG xuất hiện và lệnh debug fail. Đây cũng là lý do mọi job dùng OIDC phải khai báo `permissions: id-token: write` ở đầu.

Output sẽ thấy claim `sub` thật (ví dụ `repo:lyduc/aws-iac-terraform-playbook:ref:refs/heads/main`). Hiểu được claim này, bạn viết được trust policy chuẩn.

> 🔒 **Cảnh báo bảo mật về `pull_request`**: GitHub cho phép PR từ **fork** (người ngoài). Nếu trust policy match `repo:org/repo:pull_request`, **bất kỳ ai** mở PR đều assume được role → có thể chạy code độc trong workflow → đánh cắp credentials. Vì vậy với role `apply`, **TUYỆT ĐỐI không** match `pull_request`. Chỉ cho `plan` (read-only).

---

### OIDC vs Access Key trong CI/CD

| Vấn đề | Access Key (cũ) | OIDC (mới) |
|---|---|---|
| Lưu ở đâu? | GitHub Secrets (long-lived) | Không lưu — token sinh ra theo từng run |
| Rò rỉ thì sao? | Xài vĩnh viễn cho tới khi rotate | Token hết hạn ~1 giờ |
| Giới hạn được scope? | Khó (theo IAM user) | Dễ — giới hạn theo repo, branch, environment |
| Audit | Khó truy gốc | CloudTrail thấy rõ run nào, repo nào |
| Rotate | Phải làm thủ công định kỳ | Không cần rotate |

GitHub có sẵn OIDC Provider issuer `https://token.actions.githubusercontent.com`. AWS IAM tin tưởng provider này, sau đó workflow xin token tạm với role `github-actions-deployer`.

### Trust policy theo `sub` claim

Token GitHub có claim `sub` ví dụ: `repo:my-org/my-repo:ref:refs/heads/main`. AWS condition `StringLike` so khớp pattern để giới hạn:

| Pattern `sub` | Cho phép |
|---|---|
| `repo:org/repo:*` | Mọi branch / tag / PR / environment của repo |
| `repo:org/repo:ref:refs/heads/main` | Chỉ branch `main` |
| `repo:org/repo:environment:production` | Chỉ workflow chạy với `environment: production` |
| `repo:org/repo:pull_request` | **CHỈ DÙNG cho role plan read-only**. KHÔNG bao giờ cho role apply, vì PR từ fork (người ngoài) cũng match pattern này → có thể chạy code độc trong workflow nếu role có quyền write. |

> 💡 **Production**: tách 2 role riêng — `deployer-dev` cho push main, `deployer-prod` cho `environment: production`. Buổi này dùng 1 role demo; phần Bonus dưới hướng dẫn tách.

### Manual approval với GitHub Environments

GitHub repo → Settings → Environments → tạo `production` → bật **Required reviewers**. Workflow declare `environment: production` sẽ pause cho tới khi reviewer approve.

---

## 🗂️ Cấu trúc folder

```
buoi-20-project2-cicd/
├── README.md
├── iam-bootstrap/
│   ├── main.tf                       ← OIDC provider + IAM Role + policy
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── terraform.tfvars.example
└── .github/
    └── workflows/
        ├── terraform-plan.yml        ← PR → plan + comment
        ├── terraform-apply.yml       ← push main → apply dev
        └── terraform-prod.yml        ← tag v* → apply prod (approval)
```

> 📌 Folder `.github/workflows/` ở đây là **mẫu để copy** lên ROOT của repo Terraform thật. GitHub chỉ load workflow ở `.github/workflows/` của root repo. Khi triển khai thật, copy hoặc symlink các YAML này lên root.

---

## 🛠️ Các bước thực hành

### Bước 1 — Bootstrap OIDC + IAM Role (1 lần duy nhất)

```bash
cd iam-bootstrap
cp terraform.tfvars.example terraform.tfvars
# Sửa github_repo = "your-org/your-repo"
terraform init
terraform plan
terraform apply
```

Output:

- `role_arn` — copy ARN này vào secret/var `AWS_ROLE_TO_ASSUME` của GitHub repo (Settings → Secrets and variables → Actions).

> ⚠️ Stack này KHÔNG có S3 backend — state local là chấp nhận được vì 1 lần duy nhất, không thay đổi nhiều. Hoặc đặt backend S3 nếu muốn quản lý chung.

### Bước 2 — Cấu hình GitHub repo

1. **Variables** (Settings → Secrets and variables → Actions → Variables):
   - `AWS_ROLE_TO_ASSUME` = ARN role từ output bước 1.
   - `AWS_REGION` = `ap-southeast-1`.
2. **Environments** (Settings → Environments):
   - Tạo `production` → Required reviewers: chính bạn → Save.

### Bước 3 — Copy workflow lên root repo

Copy 3 file `.github/workflows/*.yml` ở buổi này lên `.github/workflows/` của ROOT repo.

### Bước 4 — Thử pipeline

#### Plan (PR):

```bash
git checkout -b feat/test-ci
# sửa 1 file .tf gì đó (ví dụ thêm tag)
git commit -am "test ci"
git push -u origin feat/test-ci
# Mở PR → workflow terraform-plan chạy → bot comment plan
```

#### Apply dev (merge main):

Merge PR → workflow `terraform-apply` chạy → apply env dev.

#### Apply prod (git tag):

```bash
git tag v0.1.0
git push --tags
# Workflow terraform-prod chạy, dừng ở approval gate → bạn approve trên Console GitHub
```

---

## ✅ Đầu ra checklist

- [ ] `iam-bootstrap` apply thành công, có `aws_iam_openid_connect_provider` và role `github-actions-deployer`.
- [ ] Trust policy chỉ chấp nhận `repo:<owner>/<repo>:*` (kiểm tra IAM Console).
- [ ] GitHub repo có variable `AWS_ROLE_TO_ASSUME` + `AWS_REGION`.
- [ ] Environment `production` có required reviewer.
- [ ] Mở 1 PR thử → workflow `terraform-plan` chạy, có comment plan.
- [ ] Merge main → workflow `terraform-apply` chạy, infra dev được cập nhật.
- [ ] Tag `v*` → workflow `terraform-prod` pause chờ approval, sau approve thì apply prod.
- [ ] CloudTrail thấy event `AssumeRoleWithWebIdentity` mỗi run.
- [ ] KHÔNG có `AWS_ACCESS_KEY_ID` trong GitHub Secrets cho deploy.

---

## 🐛 Common errors

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `Could not assume role with OIDC` | Trust policy `sub` không khớp | Kiểm tra `github_repo` đúng `owner/repo`, không có dấu `https://` |
| `InvalidIdentityToken: Couldn't retrieve verification key` | Thumbprint của OIDC provider không khớp cert root CA của GitHub | Cập nhật `thumbprint_list` trong `aws_iam_openid_connect_provider`. GitHub đôi khi rotate cert — xem [GitHub OIDC docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) |
| `AccessDenied: ... iam:CreateOpenIDConnectProvider` | User chạy bootstrap thiếu quyền IAM | Dùng admin để chạy bootstrap |
| Workflow không có quyền lấy OIDC token | Thiếu `permissions: id-token: write` | Thêm vào workflow YAML |
| `Error: ConditionalCheckFailedException` | Lock state khi nhiều run cùng lúc | Bình thường — đợi run trước xong, hoặc xoá `.tflock` thủ công |
| Bot không comment plan | Thiếu `permissions: pull-requests: write` | Thêm vào job |
| Apply prod không pause | Quên khai báo `environment: production` ở job | Thêm `environment: production` |
| Token expired giữa apply | Apply chạy quá 1 giờ | Tách stack nhỏ hơn, hoặc bật `role-duration-seconds` (max 3600 với OIDC) |

---

## ❓ Câu hỏi tự ôn

1. OIDC giữa GitHub và AWS hoạt động qua mấy bước? Token có thời hạn bao lâu?
2. Vì sao OIDC an toàn hơn access key tĩnh trong GitHub Secrets?
3. Trust policy giới hạn theo `sub` claim như thế nào? Pattern `repo:org/repo:*` cho phép cái gì?
4. `id-token: write` permission làm gì? Nếu thiếu sẽ ra sao?
5. Manual approval cho prod làm bằng cơ chế gì của GitHub? Job declare thế nào?
6. Vì sao tách role dev / prod là pattern an toàn hơn dùng 1 role chung?

---

## 🎁 Bonus: Tách role dev / prod

Trong `iam-bootstrap/main.tf`, tạo 2 role:

```hcl
# Role dev — chấp nhận push main + PR
sub: "repo:org/repo:ref:refs/heads/main"
sub: "repo:org/repo:pull_request"

# Role prod — chỉ chấp nhận environment production
sub: "repo:org/repo:environment:production"
```

Workflow dev assume role dev, workflow prod assume role prod. Như vậy ngay cả khi PR ác ý, không assume được role prod.

---

## 📚 Tham khảo

- [GitHub OIDC + AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [`aws-actions/configure-aws-credentials`](https://github.com/aws-actions/configure-aws-credentials)
- [`hashicorp/setup-terraform`](https://github.com/hashicorp/setup-terraform)
- [GitHub Environments + protection rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [`aws_iam_openid_connect_provider`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider)

➡️ **Buổi tiếp theo**: [Buổi 21 — Vận hành & Rollback](../buoi-21-operations-rollback/README.md)
