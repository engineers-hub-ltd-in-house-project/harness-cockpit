output "event_collector_function_name" {
  value = aws_lambda_function.event_collector.function_name
}

output "event_collector_invoke_arn" {
  value = aws_lambda_function.event_collector.invoke_arn
}

output "authorizer_function_name" {
  value = aws_lambda_function.authorizer.function_name
}

output "authorizer_invoke_arn" {
  value = aws_lambda_function.authorizer.invoke_arn
}

output "authorizer_function_arn" {
  value = aws_lambda_function.authorizer.arn
}
