output "api_endpoint" {
  description = "API Gateway endpoint URL for hook scripts"
  value       = module.api.api_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name for harness config distribution"
  value       = module.storage.config_bucket_name
}

output "log_group_name" {
  description = "CloudWatch Logs group name for harness events"
  value       = module.storage.log_group_name
}

output "grafana_endpoint" {
  description = "Amazon Managed Grafana workspace URL"
  value       = module.grafana.grafana_endpoint
}
