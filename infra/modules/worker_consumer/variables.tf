variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "sqs_queue_arn" {
  type        = string
  description = "SQS queue ARN consumed by the worker"
}

variable "sqs_queue_url" {
  type        = string
  description = "SQS queue URL consumed by the worker"
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for persisted events"
}

variable "dynamodb_table_arn" {
  type        = string
  description = "DynamoDB table ARN for IAM policies"
}
