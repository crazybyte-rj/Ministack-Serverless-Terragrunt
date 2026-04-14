include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "messaging" {
  config_path = "../messaging"

  mock_outputs = {
    sqs_queue_arn = "arn:aws:sqs:us-east-1:000000000000:ministack-lab-dev-events"
    sqs_queue_url = "http://localhost:4566/000000000000/ministack-lab-dev-events"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
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
  source = "../../../modules/worker_consumer"
}

inputs = merge(
  local.env_cfg.locals.common_inputs,
  {
    sqs_queue_arn       = dependency.messaging.outputs.sqs_queue_arn
    sqs_queue_url       = dependency.messaging.outputs.sqs_queue_url
    dynamodb_table_name = dependency.data_store.outputs.table_name
    dynamodb_table_arn  = dependency.data_store.outputs.table_arn
  }
)
