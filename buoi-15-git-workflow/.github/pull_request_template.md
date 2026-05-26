# Pull Request — Terraform Change

## 📝 Mô tả ngắn

<!-- Mô tả 2–3 câu: PR này thay đổi gì, vì sao. -->

## 🎯 Loại thay đổi

- [ ] Thêm resource mới
- [ ] Sửa cấu hình resource đang có
- [ ] Refactor (không thay đổi infra)
- [ ] Bugfix
- [ ] Nâng cấp version provider/module
- [ ] Xoá resource

## ✅ Checklist trước khi merge

### Validation cục bộ
- [ ] Đã chạy `terraform fmt -recursive`
- [ ] Đã chạy `terraform validate`
- [ ] Đã chạy `terraform plan` và đính kèm output vào PR
- [ ] Đã chạy `tflint` (nếu có config)
- [ ] Đã chạy `tfsec` hoặc `trivy iac` — không còn cảnh báo HIGH/CRITICAL chưa giải trình

### Tác động lên hạ tầng
- [ ] Có resource nào bị **destroy** trong plan không? Nếu có, liệt kê:
  - <!-- liệt kê -->
- [ ] Có resource nào bị **replace (destroy + create)** không? Nếu có, đánh giá rủi ro mất dữ liệu:
  - <!-- liệt kê -->
- [ ] Có thay đổi **state** (move/import/rm) không? Đã backup state chưa?
- [ ] Resource quan trọng (RDS, S3 production) có `prevent_destroy = true` chưa?

### Bảo mật & chi phí
- [ ] Không commit `*.tfvars` chứa secret hoặc password
- [ ] Không commit file state (`*.tfstate*`)
- [ ] Đã ước tính chi phí tăng thêm (Infracost) nếu PR có resource trả phí

### Tài liệu
- [ ] README module đã cập nhật input/output mới (nếu có)
- [ ] Changelog / commit message rõ ràng

## 📎 Plan output

<details>
<summary>terraform plan</summary>

```
<!-- paste plan vào đây -->
```

</details>

## 🔗 Issue/Ticket liên quan

<!-- Closes #123 -->
