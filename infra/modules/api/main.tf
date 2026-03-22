# --- API Gateway HTTP API v2 ---

resource "aws_apigatewayv2_api" "harness" {
  name          = "${var.project_id}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "v1" {
  api_id      = aws_apigatewayv2_api.harness.id
  name        = "v1"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${var.project_id}-api"
  retention_in_days = 30
}

# --- Lambda Authorizer ---

resource "aws_apigatewayv2_authorizer" "bearer" {
  api_id                            = aws_apigatewayv2_api.harness.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = var.authorizer_invoke_arn
  authorizer_payload_format_version = "2.0"
  name                              = "bearer-token"
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]
  authorizer_result_ttl_in_seconds  = 300
}

resource "aws_lambda_permission" "authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.harness.execution_arn}/*"
}

# --- EventCollector Integration ---

resource "aws_apigatewayv2_integration" "event_collector" {
  api_id                 = aws_apigatewayv2_api.harness.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.event_collector_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_events" {
  api_id             = aws_apigatewayv2_api.harness.id
  route_key          = "POST /events"
  target             = "integrations/${aws_apigatewayv2_integration.event_collector.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.bearer.id
}

resource "aws_lambda_permission" "event_collector" {
  statement_id  = "AllowAPIGatewayInvokeEventCollector"
  action        = "lambda:InvokeFunction"
  function_name = var.event_collector_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.harness.execution_arn}/*"
}
