variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN where events are published"
}
