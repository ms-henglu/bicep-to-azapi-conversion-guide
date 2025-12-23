output "api_management_service_id" {
  description = "The ID of the API Management service."
  value       = azapi_resource.api_management.id
}

output "api_management_service_name" {
  description = "The name of the API Management service."
  value       = azapi_resource.api_management.name
}
