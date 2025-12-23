output "appServicePlanId" {
  description = "The ID of the App Service Plan."
  value       = azapi_resource.appServicePlan.id
}

output "webAppPortalId" {
  description = "The ID of the Web App."
  value       = azapi_resource.webAppPortal.id
}
