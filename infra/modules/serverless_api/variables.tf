variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. dev, staging, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_endpoint_url" {
  type        = string
  description = "Endpoint URL for ministack/local AWS emulation"
}

variable "aws_access_key_id" {
  type        = string
  description = "Access key for local AWS emulation"
}

variable "aws_secret_access_key" {
  type        = string
  description = "Secret key for local AWS emulation"
}

variable "lambda_runtime" {
  type        = string
  description = "Runtime used by the Lambda function"
}

variable "hello_route_key" {
  type        = string
  description = "Route key exposed by the HTTP API"
}

variable "api_gateway_stage_name" {
  type        = string
  description = "Stage name used by the HTTP API"
}

variable "lambda_basic_execution_policy_arn" {
  type        = string
  description = "IAM policy ARN attached to the Lambda execution role for basic logging"
}
