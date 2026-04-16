locals {
  common_inputs = {
    project_name                        = "ministack-lab"
    environment                         = "dev"
    aws_account_id                      = "000000000000"
    aws_region                          = "us-east-1"
    aws_access_key_id                   = "test"
    aws_secret_access_key               = "test"
    aws_endpoint_url                    = "http://localhost:4566"
    lambda_runtime                      = "python3.11"
    lambda_build_python                 = "python3"
    dynamodb_billing_mode               = "PAY_PER_REQUEST"
    api_gateway_stage_name              = "$default"
    api_gateway_local_domain            = "execute-api.localhost:4566"
    api_gateway_local_host_style_domain = "execute-api.localhost.localstack.cloud:4566"
  }
}
