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
