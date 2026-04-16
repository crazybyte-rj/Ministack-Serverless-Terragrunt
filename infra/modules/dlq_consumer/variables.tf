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

variable "lambda_runtime" {
  type        = string
  description = "Runtime used by the DLQ consumer Lambda"
}

variable "lambda_build_python" {
  type        = string
  description = "Python executable used to install Lambda package dependencies"
}

variable "lambda_timeout" {
  type        = number
  description = "Timeout in seconds for the DLQ consumer Lambda"
}

variable "aws_region" {
  type        = string
  description = "AWS region exposed to the Lambda runtime"
}

variable "aws_access_key_id" {
  type        = string
  description = "AWS access key id exposed to the Lambda runtime"
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key exposed to the Lambda runtime"
}

variable "aws_endpoint_url" {
  type        = string
  description = "AWS endpoint URL exposed to the Lambda runtime"
}

variable "lambda_batch_size" {
  type        = number
  description = "Batch size used by the DLQ event source mapping"
}

variable "maximum_batching_window_in_seconds" {
  type        = number
  description = "Maximum batching window in seconds for the DLQ event source mapping"
}
