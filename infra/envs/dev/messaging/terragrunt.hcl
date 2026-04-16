include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../modules/messaging"
}

inputs = merge(
  local.env_cfg.locals.common_inputs,
  {
    sqs_max_receive_count = 5
  }
)
