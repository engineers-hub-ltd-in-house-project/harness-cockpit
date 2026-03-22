variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = "yusuke.sato"
}

variable "project_id" {
  description = "Project identifier used in resource naming"
  type        = string
  default     = "harness-cockpit"
}

variable "harness_api_token" {
  description = "Bearer token for API Gateway authentication"
  type        = string
  sensitive   = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 90
}

variable "grafana_admin_user_id" {
  description = "IAM Identity Center user ID for Grafana workspace admin"
  type        = string
  default     = "c7f4eab8-f051-70e9-e666-d97ddfb7ad77"
}
