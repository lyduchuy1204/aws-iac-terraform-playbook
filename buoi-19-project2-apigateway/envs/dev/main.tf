# env dev — gọi module apigateway và lấy thông tin Lambda từ state buổi 18.

# Đọc output của stack buổi 18 (Lambda + DynamoDB) qua S3 backend.
data "terraform_remote_state" "lambda" {
  backend = "s3"
  config = {
    bucket = var.lambda_state_bucket
    key    = var.lambda_state_key
    region = var.region
  }
}

module "apigateway" {
  source = "../../modules/apigateway"

  api_name           = var.api_name
  stage_name         = var.stage_name
  resource_path_part = "items"

  lambda_function_name = data.terraform_remote_state.lambda.outputs.lambda_function_name
  lambda_invoke_arn    = data.terraform_remote_state.lambda.outputs.lambda_invoke_arn
}
