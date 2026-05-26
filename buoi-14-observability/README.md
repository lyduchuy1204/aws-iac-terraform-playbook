# 🎓 Buổi 14 — Observability: Logs, Metrics, Alarms

> Hạ tầng phải có "mắt" để DevOps biết khi nào nó ốm. Buổi này dựng bộ ba kinh điển trên AWS: **CloudWatch Logs + CloudWatch Metric Alarm + SNS email**.

---

## 🎯 Mục tiêu

- Hiểu mô hình quan sát của AWS: **Logs / Metrics / Alarms / Notifications**.
- Tạo được CloudWatch Log Group có retention hợp lý (tránh tốn tiền).
- Tạo Metric Alarm CPU > 80% trong 5 phút và nhận email cảnh báo qua SNS.
- Biết cách stress test EC2 để nghiệm thu alarm.

---

## 📖 Thuật ngữ buổi này

| Từ | Nghĩa ngắn |
|---|---|
| CloudWatch Logs | Dịch vụ lưu log trên AWS |
| Log Group | Container chứa log streams |
| Retention | Số ngày giữ log trước khi tự xoá |
| CloudWatch Metrics | Time-series data points (CPU, memory…) |
| Alarm | Rule so sánh metric với threshold, có 3 trạng thái OK/ALARM/INSUFFICIENT_DATA |
| SNS Topic | Kênh broadcast notification (email/SMS/Lambda…) |
| `evaluation_periods` | Số chu kỳ liên tiếp vượt ngưỡng để alarm trigger |
| `period` | Độ dài 1 chu kỳ (giây) |

---

## 📂 Cấu trúc folder buổi này

```
buoi-14-observability/
├── README.md
├── main.tf            ← code mẫu sẵn: Log Group + SNS + Alarm
├── variables.tf       ← khai báo notification_email, instance_id…
├── outputs.tf
└── versions.tf
```

> 💡 **Code đã có sẵn**, bạn chỉ cần truyền 2 biến qua `terraform.tfvars` (`notification_email`, `instance_id`) là chạy được.

---

## 📚 Lý thuyết ngắn

### CloudWatch Logs
- Log Group: container chứa log streams. **Retention** = số ngày giữ log (mặc định "Never expire" → tốn tiền không cần thiết). Mức học/dev nên chọn **7 ngày**.
- Log Stream: 1 stream cho 1 nguồn (instance, lambda, container).
- EC2 muốn đẩy log lên Log Group cần cài **CloudWatch Agent** (qua user-data) và gắn IAM Role có policy `CloudWatchAgentServerPolicy`.

### CloudWatch Metrics
- Metric tự động: nhiều dịch vụ AWS bắn metric mặc định (EC2 `CPUUtilization`, RDS `CPUUtilization`, ALB `RequestCount`...).
- Custom metric: bạn tự `PutMetricData`. Phí ~$0.30/metric/tháng — cẩn thận khi sinh nhiều dimension.
- Alarm: so sánh metric với threshold trong khoảng thời gian nhất định.

### Alarm states
- `OK` — đang trong ngưỡng.
- `ALARM` — vượt ngưỡng đủ số chu kỳ liên tiếp.
- `INSUFFICIENT_DATA` — thiếu dữ liệu (vd: instance vừa start).

### SNS (Simple Notification Service)
- Topic = kênh broadcast. Subscriber có thể là email, SMS, Lambda, SQS, HTTPS endpoint.
- Email subscription cần **xác nhận qua link** trong email mới active.

---

## 🧱 Kiến trúc buổi 14

```
EC2 (CloudWatch Agent) ──logs──▶ CloudWatch Log Group (retention 7 ngày)
       │
       │ metric CPUUtilization
       ▼
CloudWatch Metric Alarm (CPU > 80% / 5 phút)
       │ ALARM state
       ▼
SNS Topic ──email──▶ Inbox của bạn
```

---

## 🛠️ Các bước thực hành

> **Tiền đề**: Bạn đã hoàn thành Project 1 (buổi 10–13) hoặc có 1 EC2 đang chạy để gắn alarm vào.

> 📌 **Tiền đề**: Buổi này cần 1 EC2 instance đang chạy để gắn alarm vào.
> - Nếu bạn vừa hoàn thành Project 1 (B10–B13) và **chưa destroy**: dùng instance đó.
> - Nếu **đã destroy** Project 1 để tiết kiệm cost: cần `apply` lại B10 (Network) + B11 (Compute) trước, sau đó lấy Instance ID. Hoặc tự tạo 1 EC2 t3.micro trên Console (free tier).

### Bước 1 — Chuẩn bị input
Lấy **Instance ID** EC2 đang chạy:
```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text
```

### Bước 2 — Khai báo biến và apply

Tạo file `terraform.tfvars` (KHÔNG commit) với:
```hcl
notification_email = "ban-cua-ban@example.com"
instance_id        = "i-0abcd1234ef567890"
```

```bash
terraform init
terraform plan
terraform apply
```

### Bước 3 — Confirm subscription
- Mở email, bấm link **Confirm subscription** mà AWS Notifications gửi.
- Kiểm tra trên Console SNS → topic → subscription status = `Confirmed`.

### Bước 4 — Stress test EC2
SSH hoặc Session Manager vào instance, chạy 1 trong 2 cách:

**Cách 1 (khuyên dùng) — `stress-ng`** (Amazon Linux 2023 cài qua `dnf`):
```bash
sudo dnf install -y stress-ng
stress-ng --cpu 2 --timeout 300s
```

> ⚠️ **Lưu ý**: AL2023 KHÔNG có gói `stress` cũ trong repo mặc định. Dùng `stress-ng` thay thế.

**Cách 2 (fallback, không cần cài gì)**:
```bash
# Mở 2 terminal, chạy mỗi cái 1 lệnh để bão hoà 2 vCPU
yes > /dev/null &
dd if=/dev/zero of=/dev/null &
# Để chạy 5–10 phút
# Khi xong: kill %1 %2
```

> 📌 **Lưu ý về Log Group**: Buổi 14 tạo Log Group rỗng (chưa có log stream). Đó là **kỳ vọng** — vì user-data buổi 11 chỉ cài nginx, CHƯA cài CloudWatch Agent. Nếu muốn EC2 thật sự đẩy log lên Log Group, xem mục mở rộng dưới.

### 📦 (Mở rộng) Cài CloudWatch Agent qua user-data

> ⚠️ **Đây là bước NÂNG CAO** — không bắt buộc cho buổi 14. Bao gồm:
> 1. Sửa `user_data.sh` của module B11.
> 2. Re-`apply` B11 (instance cũ KHÔNG tự nhận user-data mới — phải **terminate** thủ công hoặc dùng "Instance Refresh" của ASG).
> 3. Sửa IAM Role B11, attach thêm policy `CloudWatchAgentServerPolicy`.
> 4. Re-`apply` B14 nếu Log Group name khác.
>
> Nếu bạn mới làm B14 lần đầu, có thể **bỏ qua section này** và quay lại sau khi đã quen Project 1. Mục tiêu chính của B14 là alarm + SNS, KHÔNG phải log shipping.

Sửa `user_data.sh` của Launch Template buổi 11, thêm:

```bash
# Cài CloudWatch Agent
sudo dnf install -y amazon-cloudwatch-agent

# Cấu hình tối thiểu — đẩy /var/log/messages lên Log Group buổi 14
cat > /tmp/cw-agent-config.json <<'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [{
          "file_path": "/var/log/messages",
          "log_group_name": "/aws/ec2/buoi-14-app",
          "log_stream_name": "{instance_id}",
          "retention_in_days": 7
        }]
      }
    }
  }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/tmp/cw-agent-config.json -s
```

Đồng thời IAM Role EC2 (buổi 11) phải có thêm policy `CloudWatchAgentServerPolicy`.

### Bước 5 — Quan sát
- CloudWatch → Alarms → trạng thái chuyển từ `OK` → `ALARM`.
- Email vào inbox với subject kiểu `ALARM: "..." in Asia Pacific (Singapore)`.
- Sau khi stop stress, alarm tự về `OK` sau vài phút.

### Bước 6 — Dọn dẹp
```bash
terraform destroy
```

---

## ✅ Đầu ra (Checklist)

- [ ] `aws_cloudwatch_log_group` tạo thành công, retention = 7 ngày.
- [ ] `aws_sns_topic` + email subscription **đã confirm**.
- [ ] `aws_cloudwatch_metric_alarm` ở trạng thái `OK` ban đầu.
- [ ] Stress test → alarm chuyển `ALARM`, nhận email.
- [ ] Stop stress → alarm về `OK`.
- [ ] `terraform destroy` sạch.

---

## 🐞 Common Errors

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Không nhận email | Chưa confirm subscription | Mở mail AWS Notifications, bấm link confirm |
| Alarm ở `INSUFFICIENT_DATA` | Instance vừa start, chưa đủ datapoint | Đợi 5–10 phút |
| `stress: command not found` (AL2023) | AL2023 không có gói `stress` cũ | Dùng `stress-ng` hoặc fallback `dd`/`yes` |
| `InvalidParameter: instance does not exist` | Sai instance_id hoặc instance đã terminate | Lấy lại ID đang running |
| Metric không xuất hiện | EC2 detailed monitoring chưa bật | `period` của alarm để 300s (basic monitoring) là đủ |
| Email confirmation không tới | Spam folder, hoặc address sai | Check spam, sửa biến và `terraform apply` lại |
| Log Group rỗng (không có stream) | EC2 chưa cài CloudWatch Agent | Đây là kỳ vọng buổi 14. Xem mục "Cài CloudWatch Agent" để thêm |

---

## ❓ Câu hỏi tự ôn

1. Vì sao Log Group nên có `retention_in_days`? Mặc định "Never expire" có rủi ro gì?
2. Phân biệt 3 trạng thái alarm: `OK`, `ALARM`, `INSUFFICIENT_DATA`.
3. Vì sao SNS email cần confirm subscription? Điều này phòng chống điều gì?
4. Tham số `evaluation_periods` và `period` của alarm khác nhau thế nào? Cho ví dụ "CPU > 80% trong 5 phút".
5. Nếu cần alarm cho **RDS** thay EC2, đổi `namespace` và `dimensions` ra sao?
6. Tại sao buổi này dùng `stress-ng` chứ không phải `stress`?
7. Nếu muốn cảnh báo qua **Slack** thay vì email, thay đổi gì trong kiến trúc SNS?

---

## 📚 Tham khảo

- [CloudWatch Alarms — AWS Docs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [CloudWatch Agent on EC2](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-on-EC2-Instance.html)
- [SNS Email Subscription](https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html)
