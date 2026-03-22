variable "project_id" {
  description = "Project identifier used in resource naming"
  type        = string
}

variable "event_collector_invoke_arn" {
  description = "Invoke ARN of the EventCollector Lambda"
  type        = string
}

variable "event_collector_function_name" {
  description = "Function name of the EventCollector Lambda"
  type        = string
}

variable "authorizer_invoke_arn" {
  description = "Invoke ARN of the Authorizer Lambda"
  type        = string
}

variable "authorizer_function_arn" {
  description = "ARN of the Authorizer Lambda function"
  type        = string
}

variable "authorizer_function_name" {
  description = "Function name of the Authorizer Lambda"
  type        = string
}
