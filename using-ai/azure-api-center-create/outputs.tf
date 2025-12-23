output "api_center_id" {
  description = "The resource ID of the API Center."
  value       = azapi_resource.service.id
}

output "api_center_name" {
  description = "The name of the API Center."
  value       = azapi_resource.service.name
}
