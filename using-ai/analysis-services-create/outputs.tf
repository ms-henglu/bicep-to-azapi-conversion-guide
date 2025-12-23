output "id" {
  value       = azapi_resource.server.id
  description = "The ID of the Azure Analysis Services server."
}

output "name" {
  value       = azapi_resource.server.name
  description = "The name of the Azure Analysis Services server."
}
