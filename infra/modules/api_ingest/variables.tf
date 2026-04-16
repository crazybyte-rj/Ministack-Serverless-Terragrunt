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

variable "lambda_runtime" {
  type        = string
  description = "Runtime used by the ingest Lambda"
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

variable "publish_event_route_key" {
  type        = string
  description = "Route key for the event publishing endpoint"
}

variable "health_route_key" {
  type        = string
  description = "Route key for the health endpoint"
}

variable "api_gateway_stage_name" {
  type        = string
  description = "Stage name used by the HTTP API"
}

variable "api_gateway_local_domain" {
  type        = string
  description = "Local domain suffix used to build the API invoke URL"
}

variable "api_gateway_local_host_style_domain" {
  type        = string
  description = "Local host-style domain suffix used to build the API invoke URL"
}
