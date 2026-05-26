# 🎓 Buổi 00 — Chuẩn bị môi trường

> **Thời lượng**: ~1 giờ · **Loại**: Setup · **Code thực hành**: ❌ (chưa có)

---

## 🎯 Mục tiêu

Sau buổi này, máy bạn phải có đủ công cụ để học toàn bộ playbook:

- AWS CLI v2 nói chuyện được với account của bạn.
- Terraform `>= 1.11` (cần cho S3 native locking ở buổi 06).
- Git, VS Code có extension `HashiCorp Terraform`.
- IAM user riêng cho việc học (KHÔNG dùng root).
- Budget Alert $5 để khỏi cháy ví khi quên `destroy`.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| IAM User | Account người-dùng có credentials đăng nhập riêng |
| Access Key | Cặp key/secret để gọi AWS API từ CLI |
| Profile (`~/.aws/credentials`) | Nhóm credentials có tên, dùng `--profile` chuyển qua lại |
| Region | Khu vực địa lý chứa datacenter AWS (vd `ap-southeast-1` = Singapore) |
| MFA | Xác thực 2 yếu tố qua app TOTP |

---

## 📚 Lý thuyết tóm tắt

- **AWS CLI v2** là CLI chính thức để gọi API AWS từ máy local. Terraform AWS provider đọc credential từ chuỗi mặc định: env var → `~/.aws/credentials` → IAM Role (nếu chạy trên EC2).
- **Terraform** là binary đơn lẻ, không cần runtime. Chỉ cần download và để vào `PATH`.
- **IAM user vs root**: root có toàn quyền billing và không thể bị giới hạn — TUYỆT ĐỐI không tạo access key cho root. Tạo IAM user riêng để dùng hằng ngày.
- **Budget Alert** không chặn chi phí, chỉ gửi email cảnh báo khi vượt ngưỡng. Đặt $5 để biết sớm nếu quên xoá NAT Gateway / RDS.
- **Region khuyến nghị**: `ap-southeast-1` (Singapore) — gần Việt Nam, đầy đủ service.

---

## 🛠️ Các bước thực hành

### Bước 1 — Cài đặt công cụ

#### 🪟 Windows (PowerShell, dùng Chocolatey)

Mở **PowerShell as Administrator**:

```powershell
# Cài Chocolatey (nếu chưa có)
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Cài bộ công cụ
choco install -y awscli terraform git vscode

# Kiểm tra
aws --version
terraform -version
git --version
code --version
```

> Nếu công ty chặn Chocolatey: tải MSI từ https://aws.amazon.com/cli/ và https://developer.hashicorp.com/terraform/install rồi cài tay.

#### 🍎 macOS (Homebrew)

```bash
# Cài Homebrew (nếu chưa có)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Cài bộ công cụ
brew install awscli git
brew install hashicorp/tap/terraform
brew install --cask visual-studio-code

# Kiểm tra
aws --version
terraform -version
git --version
code --version
```

#### 🐧 Linux (Ubuntu/Debian, apt)

```bash
# AWS CLI v2 (gói chính thức, KHÔNG dùng apt vì version cũ)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Terraform (HashiCorp APT repo)
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# Git + VS Code
sudo apt-get install -y git
sudo snap install --classic code

# Kiểm tra
aws --version
terraform -version
git --version
code --version
```

### Bước 2 — Cài extension VS Code

Mở VS Code → **Extensions** (Ctrl+Shift+X) → cài:

- `HashiCorp Terraform` (publisher: HashiCorp) — syntax + IntelliSense + format on save.
- `AWS Toolkit` (publisher: Amazon Web Services) — xem resource AWS từ VS Code (optional).

Hoặc cài qua CLI:

```bash
code --install-extension HashiCorp.terraform
code --install-extension AmazonWebServices.aws-toolkit-vscode
```

### Bước 3 — Tạo IAM user trên AWS Console

1. Đăng nhập AWS Console bằng **root** (1 lần duy nhất).
2. Vào **IAM** → **Users** → **Create user**.
3. User name: `terraform-learner`.
4. Permissions: **Attach policies directly** → chọn `AdministratorAccess` (chỉ cho mục đích học, prod thì không).
5. Sau khi tạo xong, vào user → tab **Security credentials** → **Create access key** → loại **Command Line Interface (CLI)** → copy `Access key ID` và `Secret access key`.

> ⚠️ **Secret access key chỉ hiện 1 lần**. Copy ngay vào file tạm.

### Bước 4 — Configure AWS CLI

```bash
aws configure
```

Nhập lần lượt:

```
AWS Access Key ID [None]: AKIA...           ← paste access key
AWS Secret Access Key [None]: wJalrXUt...   ← paste secret
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

Kiểm tra:

```bash
aws sts get-caller-identity
```

Output mẫu:

```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/terraform-learner"
}
```

### Bước 5 — Bật Budget Alert $5

1. AWS Console → **Billing and Cost Management** → **Budgets** → **Create budget**.
2. Chọn **Use a template** → **Monthly cost budget**.
3. Budget name: `learning-budget-5usd`.
4. Budget amount: `5` USD.
5. Email recipients: email của bạn.
6. **Create budget**.

> Budget Alert sẽ gửi email khi đạt 85% và 100% ngưỡng. Không chặn chi phí, chỉ cảnh báo.

### Bước 6 — Tuỳ chọn nhưng nên làm: bật MFA cho IAM user

IAM → Users → `terraform-learner` → tab **Security credentials** → **Assign MFA device** → dùng app Google Authenticator / Authy.

---

## ✅ Đầu ra checklist

- [ ] `aws --version` ≥ 2.x
- [ ] `terraform -version` ≥ 1.11
- [ ] `git --version` ≥ 2.x
- [ ] VS Code có extension `HashiCorp Terraform`
- [ ] `aws sts get-caller-identity` trả về Account ID + ARN của `terraform-learner`
- [ ] IAM user `terraform-learner` có MFA (khuyến nghị)
- [ ] Budget Alert $5 đã được tạo, email đã xác nhận

---

## 🐛 Common errors

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `Unable to locate credentials` | Chưa chạy `aws configure` hoặc sai profile | Chạy lại `aws configure`, hoặc set `AWS_PROFILE` |
| `An error occurred (InvalidClientTokenId)` | Access key bị disable / xoá | Tạo lại access key trên Console |
| `terraform: command not found` (sau khi cài) | `PATH` chưa refresh | Mở terminal mới, hoặc `source ~/.bashrc` |
| `aws configure` báo region invalid | Gõ sai region code | Dùng đúng `ap-southeast-1` (không phải `ap-south-1`) |
| Choco/Brew bị chặn ở môi trường công ty | Proxy / firewall | Tải installer thủ công từ trang chính thức |

---

## ❓ Câu hỏi tự ôn

1. Vì sao KHÔNG được tạo access key cho root account?
2. Thứ tự ưu tiên Terraform AWS provider tìm credential là gì?
3. Budget Alert có chặn chi phí khi vượt ngưỡng không? Vì sao?
4. Region `ap-southeast-1` ở thành phố nào? Tại sao chọn region này thay vì `us-east-1`?
5. File `~/.aws/credentials` và `~/.aws/config` khác nhau ở đâu?

---

## 📚 Tham khảo

- [AWS CLI v2 Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform Install](https://developer.hashicorp.com/terraform/install)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

➡️ **Buổi tiếp theo**: [Buổi 00b — AWS Foundations cơ bản](../buoi-00b-aws-foundations/README.md)
