variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "sqs_max_receive_count" {
  type        = number
  description = "Maximum number of receives before sending messages to the DLQ"
}
