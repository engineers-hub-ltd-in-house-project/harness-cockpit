variable "project_id" {
  description = "Project identifier used in resource naming"
  type        = string
}

variable "grafana_admin_user_id" {
  description = "IAM Identity Center user ID for Grafana admin"
  type        = string
}

variable "log_group_arn" {
  description = "CloudWatch Logs group ARN for harness events"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch data source"
  type        = string
}

variable "dashboard_json_path" {
  description = "Path to the Grafana dashboard JSON file"
  type        = string
}
