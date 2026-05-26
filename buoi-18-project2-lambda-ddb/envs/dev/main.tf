# env dev — gọi 2 module lambda + dynamodb cho Project 2 buổi 18.

module "dynamodb" {
  source     = "../../modules/dynamodb"
  table_name = var.table_name
  hash_key   = "id"
}

module "lambda" {
  source = "../../modules/lambda"

  function_name = var.function_name
  # Trỏ vào folder src/ ở cùng buổi học (đã có handler.js + node_modules).
  source_dir = "${path.module}/../../src"
  handler    = "handler.handler"
  runtime    = "nodejs22.x"

  environment_variables = {
    TABLE_NAME = module.dynamodb.table_name
  }

  dynamodb_table_arn = module.dynamodb.table_arn
  log_retention_days = 7
}
