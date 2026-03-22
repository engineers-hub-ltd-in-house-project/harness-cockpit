variable "project_id" {
  description = "Project identifier used in resource naming"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch Logs group name for harness events"
  type        = string
}

variable "log_group_arn" {
  description = "CloudWatch Logs group ARN"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name for rules"
  type        = string
}

variable "table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

variable "api_token_parameter_arn" {
  description = "SSM Parameter Store ARN for the API token"
  type        = string
}

variable "api_token_parameter_name" {
  description = "SSM Parameter Store name for the API token"
  type        = string
}

variable "lambda_source_dir" {
  description = "Root directory containing Lambda source code"
  type        = string
}
