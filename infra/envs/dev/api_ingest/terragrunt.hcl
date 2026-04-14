include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "messaging" {
  config_path = "../messaging"

  mock_outputs = {
    sns_topic_arn = "arn:aws:sns:us-east-1:000000000000:ministack-lab-dev-events"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "../../../modules/api_ingest"
}

inputs = merge(
  local.env_cfg.locals.common_inputs,
  {
    sns_topic_arn = dependency.messaging.outputs.sns_topic_arn
  }
)
