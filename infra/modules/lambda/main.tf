# --- EventCollector Lambda ---

data "archive_file" "event_collector" {
  type        = "zip"
  source_dir  = "${var.lambda_source_dir}/event_collector"
  output_path = "${path.module}/.build/event_collector.zip"
}

resource "aws_lambda_function" "event_collector" {
  function_name    = "${var.project_id}-event-collector"
  role             = aws_iam_role.event_collector.arn
  handler          = "event_collector.handler"
  runtime          = "python3.12"
  memory_size      = 256
  timeout          = 10
  filename         = data.archive_file.event_collector.output_path
  source_code_hash = data.archive_file.event_collector.output_base64sha256

  environment {
    variables = {
      LOG_GROUP   = var.log_group_name
      RULES_TABLE = var.table_name
    }
  }
}

resource "aws_iam_role" "event_collector" {
  name = "${var.project_id}-event-collector-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "event_collector" {
  name = "${var.project_id}-event-collector-policy"
  role = aws_iam_role.event_collector.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          var.log_group_arn,
          "${var.log_group_arn}:*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.project_id}-event-collector:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
        ]
        Resource = [
          var.table_arn,
          "${var.table_arn}/index/*",
        ]
      },
    ]
  })
}

# --- Authorizer Lambda ---

data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "${var.lambda_source_dir}/authorizer"
  output_path = "${path.module}/.build/authorizer.zip"
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "${var.project_id}-authorizer"
  role             = aws_iam_role.authorizer.arn
  handler          = "authorizer.handler"
  runtime          = "python3.12"
  memory_size      = 128
  timeout          = 5
  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256

  environment {
    variables = {
      TOKEN_PARAMETER_NAME = var.api_token_parameter_name
    }
  }
}

resource "aws_iam_role" "authorizer" {
  name = "${var.project_id}-authorizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "authorizer" {
  name = "${var.project_id}-authorizer-policy"
  role = aws_iam_role.authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.project_id}-authorizer:*"
      },
      {
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = var.api_token_parameter_arn
      },
    ]
  })
}
