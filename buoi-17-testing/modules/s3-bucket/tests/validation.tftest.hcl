# =============================================================================
# validation.tftest.hcl
#
# Test VARIABLE VALIDATION:
#   - Truyền tên bucket KHÔNG hợp lệ → variable validation phải chặn.
#   - Dùng `expect_failures = [var.name]` để khẳng định lỗi đến từ validation
#     trên biến đó, KHÔNG phải lỗi runtime.
# =============================================================================

provider "aws" {
  region                      = "ap-southeast-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# Run #1 — tên có ký tự HOA → phải bị chặn
run "reject_uppercase_name" {
  command = plan

  variables {
    name = "INVALID-Bucket-Name"
  }

  expect_failures = [
    var.name,
  ]
}

# Run #2 — tên quá ngắn (< 3 ký tự) → phải bị chặn
run "reject_too_short_name" {
  command = plan

  variables {
    name = "ab"
  }

  expect_failures = [
    var.name,
  ]
}

# Run #3 — tên bắt đầu bằng dấu gạch ngang → phải bị chặn
run "reject_leading_dash" {
  command = plan

  variables {
    name = "-leading-dash-bucket"
  }

  expect_failures = [
    var.name,
  ]
}

# Run #4 — tên có ký tự đặc biệt → phải bị chặn
run "reject_special_char" {
  command = plan

  variables {
    name = "bucket_with_underscore"
  }

  expect_failures = [
    var.name,
  ]
}

# Run #5 — tên hợp lệ → KHÔNG có expect_failures, plan phải pass
run "accept_valid_name" {
  command = plan

  variables {
    name = "valid-bucket-name-123"
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "valid-bucket-name-123"
    error_message = "Tên hợp lệ phải đi tới được resource."
  }
}
