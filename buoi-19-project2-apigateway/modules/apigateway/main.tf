# Module API Gateway REST + Lambda Proxy Integration.
# Cấu trúc: REST API → Resource /items → Method GET, POST → Integration AWS_PROXY → Lambda.

# 1) REST API.
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "REST API cho Project 2 — buổi 19"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# 2) Resource /items (con của root).
resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = var.resource_path_part
}

# 3) Method GET /items — không auth (mức học).
resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "GET"
  authorization = "NONE"
}

# 4) Method POST /items.
resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "POST"
  authorization = "NONE"
}

# 5) Integration AWS_PROXY cho GET — gọi Lambda. Integration POST = AWS, integration_http_method
#    luôn là POST (cách API Gateway invoke Lambda nội bộ).
resource "aws_api_gateway_integration" "get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# 6) Integration AWS_PROXY cho POST.
resource "aws_api_gateway_integration" "post" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# 7) Resource-based policy cho Lambda — cho phép API Gateway này invoke.
#    Source ARN dùng "/*/*" để cover mọi method/path của API này.
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke-${var.api_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# 8) Deployment — snapshot config. Trigger redeploy khi resource/method/integration đổi.
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.items.id,
      aws_api_gateway_method.get.id,
      aws_api_gateway_method.post.id,
      aws_api_gateway_integration.get.id,
      aws_api_gateway_integration.post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.get,
    aws_api_gateway_integration.post,
  ]
}

# 9) Stage — pointer public. URL có dạng https://<id>.execute-api.<region>.amazonaws.com/<stage>.
resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name
  tags          = var.tags
}
