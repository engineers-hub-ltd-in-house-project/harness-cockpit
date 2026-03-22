terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

locals {
  lambda_source_dir = "${path.module}/../src/lambda"
}

module "storage" {
  source = "./modules/storage"

  project_id         = var.project_id
  log_retention_days = var.log_retention_days
  harness_api_token  = var.harness_api_token
}

module "lambda" {
  source = "./modules/lambda"

  project_id               = var.project_id
  log_group_name           = module.storage.log_group_name
  log_group_arn            = module.storage.log_group_arn
  table_name               = module.storage.table_name
  table_arn                = module.storage.table_arn
  api_token_parameter_arn  = module.storage.api_token_parameter_arn
  api_token_parameter_name = module.storage.api_token_parameter_name
  lambda_source_dir        = local.lambda_source_dir
}

module "api" {
  source = "./modules/api"

  project_id                    = var.project_id
  event_collector_invoke_arn    = module.lambda.event_collector_invoke_arn
  event_collector_function_name = module.lambda.event_collector_function_name
  authorizer_invoke_arn         = module.lambda.authorizer_invoke_arn
  authorizer_function_arn       = module.lambda.authorizer_function_arn
  authorizer_function_name      = module.lambda.authorizer_function_name
}

module "grafana" {
  source = "./modules/grafana"

  project_id            = var.project_id
  grafana_admin_user_id = var.grafana_admin_user_id
  log_group_arn         = module.storage.log_group_arn
  aws_region            = var.aws_region
  dashboard_json_path   = "${path.module}/../src/grafana/session-timeline.json"
}
