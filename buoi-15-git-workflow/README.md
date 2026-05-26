# 🎓 Buổi 15 — Git Workflow cho Terraform Team

> Code Terraform **không khác code app**: vẫn cần branch, PR, review, CI. Nhưng nó có 2 thứ đặc biệt: **state file chứa secret** và **mỗi merge có thể đổi infra thật**. Buổi này hệ thống lại workflow phù hợp.

---

## 🎯 Mục tiêu

- Setup `.gitignore` chuẩn cho repo Terraform.
- Có PR template ép developer trả lời các câu hỏi quan trọng trước khi merge.
- Hiểu **trunk-based vs GitFlow** và vì sao Terraform team nên dùng **trunk-based + short-lived branches**.
- Bảo vệ branch `main` đúng cách trên GitHub.

> Buổi này **không có file Terraform**, chỉ là quy trình + template.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| Trunk-based | Branching model với 1 branch chính, branch tính năng sống ngắn |
| GitFlow | Branching model có develop + release + hotfix branches |
| Branch protection | Rule GitHub chặn push trực tiếp / require review |
| PR template | File `.github/pull_request_template.md` tự load khi mở PR |
| `.terraform.lock.hcl` | Lock file pin version provider (PHẢI commit) |
| Linear history | Chỉ cho phép squash/rebase merge, cấm merge commit |

---

## 📚 Lý thuyết

### Trunk-based vs GitFlow

| Tiêu chí | Trunk-based (khuyên dùng cho Terraform) | GitFlow |
|---|---|---|
| Branch chính | 1 (`main`) | 2 (`main` + `develop`) |
| Feature branch | Sống ngắn (vài giờ → 2 ngày) | Sống dài, có thể vài tuần |
| Release branch | Không có hoặc rất ngắn | Có `release/*`, `hotfix/*` |
| Phù hợp với | CI/CD liên tục, deploy thường xuyên | Phần mềm có version rời rạc (vd: app cài máy) |

### Vì sao Terraform team nên dùng **trunk-based**?

1. **State drift theo thời gian**: Branch sống lâu = state local của developer A lệch xa state thật → khi merge `terraform plan` ra diff lạ hoắc.
2. **Conflict ở `.tfstate` không thể merge**: state là JSON sinh tự động, không thể "merge" như source code. Branch sống ngắn ↔ ít rủi ro 2 người đụng nhau.
3. **Infra phải khớp với code mới nhất**: GitFlow có `develop` → `main` rất dễ "code prod" và "code dev" lệch nhau, infra càng lệch.
4. **Plan + Apply pipeline đơn giản**: trunk-based chỉ cần "PR → plan", "merge → apply". GitFlow phải maintain pipeline 2 nhánh → phức tạp.

### Quy ước branch trunk-based cho Terraform

```
main ◀─── PR (sống vài giờ)
   ├─ feat/add-rds-replica
   ├─ fix/sg-egress-typo
   └─ chore/upgrade-aws-provider
```

Quy tắc:
- Branch sống **không quá 2 ngày**. Nếu thay đổi to, chia nhỏ thành nhiều PR.
- Mỗi PR = **1 logical change** (1 resource group / 1 module).
- Merge xong, xoá branch ngay.

### Multi-environment trong trunk-based

Cách phổ biến: cùng `main`, env tách bằng folder + state khác nhau.

```
envs/
  dev/    ← merge main → CI auto apply dev
  prod/   ← merge main → CI manual approval → apply prod
```

KHÔNG có nhánh `dev` / `prod` riêng — code giống hệt, chỉ tfvars khác.

---

## 🛠️ Các bước thực hành

### Bước 1 — Copy `.gitignore` về root repo
File `.gitignore` trong folder này là template chuẩn. Lưu ý:
- Ignore: `.terraform/`, `*.tfstate*`, `*.tfvars`, `crash.log`, `*.tfplan`, `.terraformrc`...
- **KHÔNG ignore `.terraform.lock.hcl`** — file này phải commit để mọi người dùng đúng version provider.

### Bước 2 — Copy PR template
Đặt vào `.github/pull_request_template.md` ở root repo. GitHub tự động dùng nội dung này khi mở PR.

### Bước 3 — Bảo vệ branch `main` trên GitHub

GitHub repo → **Settings** → **Branches** → **Add branch protection rule**:

- **Branch name pattern**: `main`
- ✅ **Require a pull request before merging**
  - ✅ Require approvals (>= 1)
  - ✅ Dismiss stale approvals when new commits are pushed
- ✅ **Require status checks to pass before merging**
  - Tick các check CI: `terraform-fmt`, `terraform-validate`, `tflint`, `tfsec`, `terraform-plan`
  - ✅ Require branches to be up to date before merging
- ✅ **Require conversation resolution before merging**
- ✅ **Require linear history** (cấm merge commit, ép rebase/squash)
- ✅ **Do not allow bypassing the above settings**
- ❌ Force pushes, ❌ Deletions

### Bước 4 — Workflow PR mẫu

```bash
# Tạo branch
git checkout -b feat/add-bucket-images

# Sửa code, fmt
terraform fmt -recursive
terraform validate

# Chạy plan, lưu output
terraform plan -out=tfplan
terraform show -no-color tfplan > plan.txt

# Commit, push
git add .
git commit -m "feat(s3): add images bucket with versioning"
git push -u origin feat/add-bucket-images

# Mở PR trên GitHub, paste plan vào template
# Sau khi reviewer approve và CI pass → squash merge
# Xoá branch
git checkout main && git pull
git branch -d feat/add-bucket-images
```

---

## ✅ Đầu ra (Checklist)

- [ ] Repo có `.gitignore` đã copy từ template buổi này.
- [ ] Repo có `.github/pull_request_template.md`.
- [ ] Branch `main` đã bật protection rule (require PR + 1 review + status checks).
- [ ] Đã practice tạo 1 branch `feat/*`, mở PR, self-review, merge.
- [ ] Hiểu vì sao Terraform team dùng trunk-based.
- [ ] Repo KHÔNG có `*.tfstate`, `*.tfvars` thật trong git history.

---

## 🐞 Common Errors

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Lỡ commit `terraform.tfstate` chứa secret | Quên `.gitignore` | **Đổi mọi secret bị lộ ngay**, dùng `git filter-repo` hoặc BFG xoá khỏi history, rồi force push (cần phối hợp team) |
| `Lock file changes` mỗi developer mỗi khác | Mỗi máy chạy `terraform init` tạo hash khác (do platform) | Chạy `terraform providers lock -platform=linux_amd64 -platform=darwin_amd64 -platform=windows_amd64` để có hash đa nền tảng |
| PR có conflict ở `.terraform.lock.hcl` | Hai người upgrade provider khác version | Một người rebase, chạy lại `terraform init -upgrade`, commit lock file mới |
| Reviewer không thấy plan output | Quên paste vào PR | CI nên auto comment plan vào PR (xem buổi 20) |

---

## ❓ Câu hỏi tự ôn

1. Vì sao **không** ignore `.terraform.lock.hcl`?
2. Vì sao **phải** ignore `*.tfvars`? Trường hợp nào ngoại lệ?
3. Lỡ push `terraform.tfstate` lên GitHub public repo, làm gì đầu tiên?
4. Trunk-based khác GitFlow ở điểm nào? Vì sao Terraform team thích trunk-based?
5. PR template nên ép trả lời câu hỏi gì để giảm rủi ro destroy nhầm prod?
6. `Require linear history` có ý nghĩa gì? Khác giữa merge commit / squash / rebase?
7. Pipeline CI `terraform plan` chạy trên PR, làm sao để có quyền AWS mà không cần access key? (Gợi ý: OIDC — sẽ học buổi 20.)

---

## 📚 Tham khảo

- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- [GitHub — Branch protection rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Terraform — Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
