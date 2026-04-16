output "api_invoke_url" {
  description = "Invoke URL for the HTTP API"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_invoke_url_local" {
  description = "Local invoke URL (ministack ApiEndpoint format)"
  value       = "http://${aws_apigatewayv2_api.http_api.id}.${var.api_gateway_local_domain}/${var.api_gateway_stage_name}"
}

output "api_invoke_url_local_host_style" {
  description = "Local invoke URL (compat host style fallback)"
  value       = "http://${aws_apigatewayv2_api.http_api.id}.${var.api_gateway_local_host_style_domain}"
}

output "api_lambda_name" {
  description = "API ingest Lambda function name"
  value       = aws_lambda_function.ingest.function_name
}
