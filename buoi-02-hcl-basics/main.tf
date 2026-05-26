# Resource đầu tiên: tạo 1 file text ở local bằng provider hashicorp/local.
# - "local_file" là TYPE của resource (do provider local cung cấp).
# - "hello"      là NAME (tên gọi nội bộ trong Terraform, KHÔNG phải tên file).
resource "local_file" "hello" {
  # Đường dẫn file sẽ được tạo. path.module = thư mục chứa file .tf này.
  filename = "${path.module}/hello.txt"

  # Nội dung file. Đổi chuỗi này rồi apply lại để xem Terraform detect change.
  content = "Hello Terraform! Đây là file đầu tiên do Terraform tạo.\n"

  # Quyền file (đặt cho Linux/macOS; trên Windows sẽ bị bỏ qua).
  file_permission = "0644"
}

# Output: in ra đường dẫn file sau khi apply, để dễ kiểm tra.
output "hello_file_path" {
  description = "Đường dẫn tuyệt đối của file vừa tạo"
  value       = local_file.hello.filename
}
