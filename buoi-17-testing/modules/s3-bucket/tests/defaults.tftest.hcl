# =============================================================================
# defaults.tftest.hcl
#
# Test PLAN-ONLY (không gọi AWS thật, không tốn tiền):
#   - Truyền name, kiểm tra resource bucket sẽ được plan với đúng tên đó.
#   - Kiểm tra versioning mặc định = "Enabled".
#   - Kiểm tra public access block bật cả 4 setting.
# =============================================================================

# Provider config dùng cho tất cả run trong file này.
# Plan không thực sự gọi AWS, nhưng provider AWS cần khai báo region để init.
provider "aws" {
  region                      = "ap-southeast-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# Run #1 — plan với input mặc định (versioning_enabled = true)
run "plan_with_defaults" {
  command = plan

  variables {
    name = "buoi17-default-bucket-test"
    tags = {
      Project   = "playbook"
      Owner     = "tester"
      ManagedBy = "Terraform"
    }
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "buoi17-default-bucket-test"
    error_message = "Bucket name không khớp với input 'name'."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning phải Enabled khi versioning_enabled = true (default)."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls == true &&
      aws_s3_bucket_public_access_block.this.block_public_policy == true &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls == true &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    )
    error_message = "Public access block phải bật đủ 4 setting."
  }

  assert {
    condition = (
      aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    )
    error_message = "Encryption mặc định phải là AES256."
  }
}

# Run #2 — plan với versioning bị tắt
run "plan_versioning_disabled" {
  command = plan

  variables {
    name               = "buoi17-no-version-bucket"
    versioning_enabled = false
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Disabled"
    error_message = "Versioning phải Disabled khi versioning_enabled = false."
  }
}
