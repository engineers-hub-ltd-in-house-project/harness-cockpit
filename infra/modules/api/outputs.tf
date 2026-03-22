output "api_endpoint" {
  value = "${aws_apigatewayv2_api.harness.api_endpoint}/v1"
}

output "api_id" {
  value = aws_apigatewayv2_api.harness.id
}

output "api_execution_arn" {
  value = aws_apigatewayv2_api.harness.execution_arn
}
