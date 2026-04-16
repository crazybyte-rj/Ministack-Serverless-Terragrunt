include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg            = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  common_inputs      = local.env_cfg.locals.common_inputs
  stack_name         = "${local.common_inputs.project_name}-${local.common_inputs.environment}"
  events_table_name  = "${local.stack_name}-events"
}

dependency "data_store" {
  config_path = "../data_store"

  mock_outputs = {
    table_name = local.events_table_name
    table_arn  = "arn:aws:dynamodb:${local.common_inputs.aws_region}:${local.common_inputs.aws_account_id}:table/${local.events_table_name}"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "../../../modules/status_api"
}

inputs = merge(
  local.common_inputs,
  {
    dynamodb_table_name = dependency.data_store.outputs.table_name
    dynamodb_table_arn  = dependency.data_store.outputs.table_arn
    status_route_key    = "GET /events/{id}/status"
    health_route_key    = "GET /health"
  }
)
