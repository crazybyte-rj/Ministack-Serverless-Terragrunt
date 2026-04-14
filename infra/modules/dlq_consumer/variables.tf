variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "dlq_queue_arn" {
  type        = string
  description = "SQS DLQ queue ARN"
}

variable "dlq_queue_url" {
  type        = string
  description = "SQS DLQ queue URL"
}

variable "dlq_table_name" {
  type        = string
  description = "DynamoDB DLQ events table name"
}

variable "dlq_table_arn" {
  type        = string
  description = "DynamoDB DLQ events table ARN"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alerts"
}
