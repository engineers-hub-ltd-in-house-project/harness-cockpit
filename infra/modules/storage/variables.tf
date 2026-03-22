variable "project_id" {
  description = "Project identifier used in resource naming"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 90
}

variable "harness_api_token" {
  description = "Bearer token for API Gateway authentication"
  type        = string
  sensitive   = true
}
