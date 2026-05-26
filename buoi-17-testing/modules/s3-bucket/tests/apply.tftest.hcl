# =============================================================================
# apply.tftest.hcl
#
# Test APPLY THẬT (TỐN TIỀN — bucket S3 free tier nhưng vẫn tính API call):
#   - Tạo bucket thật trên AWS.
#   - Assert ARN có format đúng "arn:aws:s3:::<name>".
#   - Assert output bucket_name == name.
#   - terraform test TỰ ĐỘNG destroy resource sau khi run xong.
#
# Yêu cầu:
#   - AWS credentials hợp lệ trong môi trường (AWS_PROFILE / AWS_ACCESS_KEY_ID).
#   - Tên bucket phải unique toàn cầu — dùng random suffix.
# =============================================================================

provider "aws" {
  region = "ap-southeast-1"
}

# Sinh suffix random để tên bucket không bị trùng giữa các lần chạy CI
run "setup_random_suffix" {
  module {
    source = "./tests/setup"
  }
}

# Run chính: apply module với bucket name có suffix
run "apply_creates_real_bucket" {
  command = apply

  variables {
    name = "buoi17-test-${run.setup_random_suffix.suffix}"
    tags = {
      Project     = "playbook"
      Owner       = "tester"
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # ARN format S3 chuẩn: arn:aws:s3:::<bucket_name>
  assert {
    condition     = can(regex("^arn:aws:s3:::buoi17-test-[a-z0-9]+$", output.bucket_arn))
    error_message = "ARN bucket không đúng format 'arn:aws:s3:::<name>'."
  }

  # Output bucket_name phải khớp input name
  assert {
    condition     = output.bucket_name == "buoi17-test-${run.setup_random_suffix.suffix}"
    error_message = "Output bucket_name không khớp input name."
  }

  # bucket_id == bucket_name với S3
  assert {
    condition     = output.bucket_id == output.bucket_name
    error_message = "Với S3, bucket_id phải bằng bucket_name."
  }
}
