output "workspace_id" {
  value = aws_grafana_workspace.harness.id
}

output "grafana_endpoint" {
  value = "https://${aws_grafana_workspace.harness.endpoint}"
}

output "dashboard_url" {
  value = "${grafana_dashboard.session_timeline.url}"
}
