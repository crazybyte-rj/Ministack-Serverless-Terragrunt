include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg            = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  common_inputs      = local.env_cfg.locals.common_inputs
  stack_name         = "${local.common_inputs.project_name}-${local.common_inputs.environment}"
  events_name        = "${local.stack_name}-events"
  events_dlq_name    = "${local.stack_name}-events-dlq"
  dlq_table_name     = "${local.stack_name}-dlq-events"
}

dependency "messaging" {
  config_path = "../messaging"

  mock_outputs = {
    dlq_queue_arn = "arn:aws:sqs:${local.common_inputs.aws_region}:${local.common_inputs.aws_account_id}:${local.events_dlq_name}"
    dlq_queue_url = "${local.common_inputs.aws_endpoint_url}/${local.common_inputs.aws_account_id}/${local.events_dlq_name}"
    sns_topic_arn = "arn:aws:sns:${local.common_inputs.aws_region}:${local.common_inputs.aws_account_id}:${local.events_name}"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "data_store" {
  config_path = "../data_store"

  mock_outputs = {
    dlq_table_name = local.dlq_table_name
    dlq_table_arn  = "arn:aws:dynamodb:${local.common_inputs.aws_region}:${local.common_inputs.aws_account_id}:table/${local.dlq_table_name}"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

terraform {
  source = "../../../modules/dlq_consumer"
}

inputs = merge(
  local.common_inputs,
  {
    dlq_queue_arn                      = dependency.messaging.outputs.dlq_queue_arn
    dlq_queue_url                      = dependency.messaging.outputs.dlq_queue_url
    dlq_table_name                     = dependency.data_store.outputs.dlq_table_name
    dlq_table_arn                      = dependency.data_store.outputs.dlq_table_arn
    sns_topic_arn                      = dependency.messaging.outputs.sns_topic_arn
    lambda_timeout                     = 60
    lambda_batch_size                  = 10
    maximum_batching_window_in_seconds = 5
  }
)
