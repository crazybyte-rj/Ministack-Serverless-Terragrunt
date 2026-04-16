locals {
  env_cfg       = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  common_inputs = local.env_cfg.locals.common_inputs
}

remote_state {
  backend = "local"

  config = {
    path = "${get_parent_terragrunt_dir()}/state/${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region                      = "${local.common_inputs.aws_region}"
  access_key                  = "${local.common_inputs.aws_access_key_id}"
  secret_key                  = "${local.common_inputs.aws_secret_access_key}"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = "${local.common_inputs.aws_endpoint_url}"
    apigatewayv2   = "${local.common_inputs.aws_endpoint_url}"
    cloudwatch     = "${local.common_inputs.aws_endpoint_url}"
    cloudwatchlogs = "${local.common_inputs.aws_endpoint_url}"
    dynamodb       = "${local.common_inputs.aws_endpoint_url}"
    iam            = "${local.common_inputs.aws_endpoint_url}"
    lambda         = "${local.common_inputs.aws_endpoint_url}"
    sns            = "${local.common_inputs.aws_endpoint_url}"
    sqs            = "${local.common_inputs.aws_endpoint_url}"
    sts            = "${local.common_inputs.aws_endpoint_url}"
  }
}
EOF
}
