include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "data_store" {
  config_path = "../data_store"

  mock_outputs = {
    table_name = "ministack-lab-dev-events"
    table_arn  = "arn:aws:dynamodb:us-east-1:000000000000:table/ministack-lab-dev-events"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "../../../modules/status_api"
}

inputs = merge(
  local.env_cfg.locals.common_inputs,
  {
    dynamodb_table_name = dependency.data_store.outputs.table_name
    dynamodb_table_arn  = dependency.data_store.outputs.table_arn
  }
)
