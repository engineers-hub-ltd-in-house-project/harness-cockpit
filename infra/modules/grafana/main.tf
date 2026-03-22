terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# --- IAM Role for Grafana ---

resource "aws_iam_role" "grafana" {
  name = "${var.project_id}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "grafana.amazonaws.com"
      }
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = local.account_id
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "grafana" {
  name = "${var.project_id}-grafana-policy"
  role = aws_iam_role.grafana.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
        ]
        Resource = [
          var.log_group_arn,
          "${var.log_group_arn}:*",
          "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/apigateway/${var.project_id}-api:*",
          "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.project_id}-*:*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = "logs:DescribeLogGroups"
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:*"
      },
    ]
  })
}

# --- Grafana Workspace ---

resource "aws_grafana_workspace" "harness" {
  name                     = "${var.project_id}-dashboard"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  data_sources             = ["CLOUDWATCH"]

  configuration = jsonencode({
    plugins = {
      pluginAdminEnabled = true
    }
    unifiedAlerting = {
      enabled = true
    }
  })
}

# --- Admin User Association ---

resource "aws_grafana_role_association" "admin" {
  role         = "ADMIN"
  user_ids     = [var.grafana_admin_user_id]
  workspace_id = aws_grafana_workspace.harness.id
}

# --- Grafana API Key for Terraform provisioning ---

resource "aws_grafana_workspace_api_key" "terraform" {
  key_name        = "terraform"
  key_role        = "ADMIN"
  seconds_to_live = 2592000 # 30 days
  workspace_id    = aws_grafana_workspace.harness.id
}

# --- Grafana Provider Configuration ---

provider "grafana" {
  url  = "https://${aws_grafana_workspace.harness.endpoint}"
  auth = aws_grafana_workspace_api_key.terraform.key
}

# --- CloudWatch Data Source ---

resource "grafana_data_source" "cloudwatch" {
  type = "cloudwatch"
  name = "Amazon CloudWatch"

  json_data_encoded = jsonencode({
    defaultRegion = var.aws_region
    authType      = "workspace-iam-role"
  })
}

# --- Session Timeline Dashboard ---

resource "grafana_dashboard" "session_timeline" {
  config_json = file(var.dashboard_json_path)
}
