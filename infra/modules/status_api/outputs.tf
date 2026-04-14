output "api_endpoint" {
  value       = aws_apigatewayv2_api.http_api.api_endpoint
  description = "API Gateway HTTP endpoint"
}

output "api_invoke_url" {
  value       = aws_apigatewayv2_stage.default.invoke_url
  description = "Invoke URL for the status HTTP API"
}

output "api_invoke_url_local" {
  value       = "http://${aws_apigatewayv2_api.http_api.id}.execute-api.localhost:4566/$default"
  description = "Local invoke URL (ministack ApiEndpoint format)"
}

output "api_invoke_url_local_host_style" {
  value       = "http://${aws_apigatewayv2_api.http_api.id}.execute-api.localhost.localstack.cloud:4566"
  description = "Local invoke URL (compat host style fallback)"
}

output "api_id" {
  value       = aws_apigatewayv2_api.http_api.id
  description = "API Gateway HTTP API ID"
}
