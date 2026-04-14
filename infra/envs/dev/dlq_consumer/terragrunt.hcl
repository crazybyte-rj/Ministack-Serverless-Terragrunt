include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "messaging" {
  config_path = "../messaging"

  mock_outputs = {
    dlq_queue_arn = "arn:aws:sqs:us-east-1:000000000000:ministack-lab-dev-events-dlq"
    dlq_queue_url = "http://localhost:4566/000000000000/ministack-lab-dev-events-dlq"
    sns_topic_arn = "arn:aws:sns:us-east-1:000000000000:ministack-lab-dev-events"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "data_store" {
  config_path = "../data_store"

  mock_outputs = {
    dlq_table_name = "ministack-lab-dev-dlq-events"
    dlq_table_arn  = "arn:aws:dynamodb:us-east-1:000000000000:table/ministack-lab-dev-dlq-events"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

terraform {
  source = "../../../modules/dlq_consumer"
}

inputs = merge(
  local.env_cfg.locals.common_inputs,
  {
    dlq_queue_arn  = dependency.messaging.outputs.dlq_queue_arn
    dlq_queue_url  = dependency.messaging.outputs.dlq_queue_url
    dlq_table_name = dependency.data_store.outputs.dlq_table_name
    dlq_table_arn  = dependency.data_store.outputs.dlq_table_arn
    sns_topic_arn  = dependency.messaging.outputs.sns_topic_arn
  }
)
