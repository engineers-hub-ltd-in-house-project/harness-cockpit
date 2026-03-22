output "log_group_name" {
  value = aws_cloudwatch_log_group.harness_events.name
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.harness_events.arn
}

output "table_name" {
  value = aws_dynamodb_table.harness_rules.name
}

output "table_arn" {
  value = aws_dynamodb_table.harness_rules.arn
}

output "config_bucket_name" {
  value = aws_s3_bucket.harness_configs.id
}

output "config_bucket_arn" {
  value = aws_s3_bucket.harness_configs.arn
}

output "api_token_parameter_arn" {
  value = aws_ssm_parameter.api_token.arn
}

output "api_token_parameter_name" {
  value = aws_ssm_parameter.api_token.name
}
