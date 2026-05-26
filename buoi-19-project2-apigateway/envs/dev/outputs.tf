output "invoke_url" {
  description = "Invoke URL của stage. Test: curl <invoke_url>/items"
  value       = module.apigateway.invoke_url
}

output "rest_api_id" {
  description = "ID REST API."
  value       = module.apigateway.rest_api_id
}
