variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "dynamodb_billing_mode" {
  type        = string
  description = "Billing mode used by the DynamoDB tables"
}
