# =============================================================================
# tflint config — chạy cho cloud AWS
# Cài plugin AWS:
#   tflint --init
# Chạy:
#   tflint --recursive
# =============================================================================

# Plugin tflint mặc định (rule chung HCL)
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Plugin AWS — bật các rule riêng cho AWS resource
plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  # deep_check = true sẽ gọi AWS API để verify (cần credentials, chậm)
  # Để false ở local dev, bật ở CI nếu cần.
  deep_check = false
}

# --- Một số rule HCL phổ biến ---
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

# --- Rule AWS đặc thù ---
rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_db_instance_invalid_type" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags = [
    "Owner",
    "Environment",
    "Project",
    "ManagedBy",
  ]
}
