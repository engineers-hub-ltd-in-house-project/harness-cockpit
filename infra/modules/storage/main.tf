data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = "${var.project_id}-configs-${local.account_id}"
}

# --- CloudWatch Logs ---

resource "aws_cloudwatch_log_group" "harness_events" {
  name              = "/harness/claude-code/events"
  retention_in_days = var.log_retention_days
}

# --- DynamoDB (Single Table Design) ---

resource "aws_dynamodb_table" "harness_rules" {
  name         = "HarnessRules"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }
}

# --- S3 (Config Distribution) ---

resource "aws_s3_bucket" "harness_configs" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_versioning" "harness_configs" {
  bucket = aws_s3_bucket.harness_configs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "harness_configs" {
  bucket = aws_s3_bucket.harness_configs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- SSM Parameter Store ---

resource "aws_ssm_parameter" "harness_mode" {
  name  = "/harness/${var.project_id}/mode"
  type  = "String"
  value = "permissive"
}

resource "aws_ssm_parameter" "api_token" {
  name  = "/harness/api-token"
  type  = "SecureString"
  value = var.harness_api_token
}
