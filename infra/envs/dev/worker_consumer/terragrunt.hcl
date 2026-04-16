include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_cfg            = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  common_inputs      = local.env_cfg.locals.common_inputs
  stack_name         = "${local.common_inputs.project_name}-${local.common_inputs.environment}"
  events_name        = "${local.stack_name}-events"
  events_table_name  = local.events_name
}

dependency "messaging" {
  config_path = "../messaging"

  mock_outputs = {
    sqs_queue_arn = "arn:aws:sqs:${local.common_inputs.aws_region}:${local.common_inputs.aws_account_id}:${local.events_name}"
    sqs_queue_url = "${local.common_inputs.aws_endpoint_url}/${local.common_inputs.aws_account_id}/${local.events_name}"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
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
  source = "../../../modules/worker_consumer"
}

inputs = merge(
  local.common_inputs,
  {
    sqs_queue_arn                  = dependency.messaging.outputs.sqs_queue_arn
    sqs_queue_url                  = dependency.messaging.outputs.sqs_queue_url
    dynamodb_table_name            = dependency.data_store.outputs.table_name
    dynamodb_table_arn             = dependency.data_store.outputs.table_arn
    lambda_batch_size              = 10
    lambda_function_response_types = ["ReportBatchItemFailures"]
  }
)
