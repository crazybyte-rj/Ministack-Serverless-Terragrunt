include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg       = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  common_inputs = local.env_cfg.locals.common_inputs
  stack_name    = "${local.common_inputs.project_name}-${local.common_inputs.environment}"
  events_name   = "${local.stack_name}-events"
}

dependency "messaging" {
  config_path = "../messaging"

  mock_outputs = {
    sns_topic_arn = "arn:aws:sns:${local.common_inputs.aws_region}:${local.common_inputs.aws_account_id}:${local.events_name}"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "../../../modules/api_ingest"
}

inputs = merge(
  local.common_inputs,
  {
    sns_topic_arn           = dependency.messaging.outputs.sns_topic_arn
    publish_event_route_key = "POST /events"
    health_route_key        = "GET /health"
  }
)
