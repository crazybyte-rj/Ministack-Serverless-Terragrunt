variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB events table name"
}

variable "dynamodb_table_arn" {
  type        = string
  description = "DynamoDB events table ARN"
}
