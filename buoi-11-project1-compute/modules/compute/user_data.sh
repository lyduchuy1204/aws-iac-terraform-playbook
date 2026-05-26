#!/bin/bash
# Script chạy lần đầu khi EC2 boot — Amazon Linux 2023
set -euo pipefail

# Cập nhật package
dnf update -y

# Cài nginx (gói chính thức trong AL2023 repo)
dnf install -y nginx

# Trang index đơn giản hiển thị instance ID
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /usr/share/nginx/html/index.html <<EOF
<!doctype html>
<html><head><title>IaC Playbook</title></head>
<body>
  <h1>Hello from $INSTANCE_ID</h1>
  <p>AZ: $AZ</p>
  <p>Served by: nginx on Amazon Linux 2023</p>
</body></html>
EOF

systemctl enable --now nginx
