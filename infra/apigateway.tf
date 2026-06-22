# apigateway.tf — the public HTTPS front door for the api Lambda.
# We use an "HTTP API" (API Gateway v2): simpler and cheaper than the older REST API.

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project_name}-http"
  protocol_type = "HTTP"

  # Allow browsers to call this API (needed for the Stage 8 dashboard).
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = ["*"]
  }
}

# Connect the API to our Lambda ("AWS_PROXY" = pass the whole request through).
resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Routes: which URL paths map to the integration above.
resource "aws_apigatewayv2_route" "latest" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /latest"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "history" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /history"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

# A "stage" is a deployed, reachable version of the API. "$default" auto-deploys
# changes, so the URL has no extra path segment.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

# Permission: explicitly allow API Gateway to invoke the api Lambda.
# (Without this, the front door isn't allowed to call the function.)
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
