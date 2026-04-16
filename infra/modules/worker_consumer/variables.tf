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

variable "lambda_runtime" {
  type        = string
  description = "Runtime used by the worker Lambda"
}

variable "lambda_build_python" {
  type        = string
  description = "Python executable used to install Lambda package dependencies"
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
  description = "Batch size used by the SQS event source mapping"
}

variable "lambda_function_response_types" {
  type        = list(string)
  description = "Function response types used by the SQS event source mapping"
}
