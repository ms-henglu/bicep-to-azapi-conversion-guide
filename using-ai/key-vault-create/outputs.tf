output "location" {
  value = azapi_resource.kv.location
}

output "name" {
  value = azapi_resource.kv.name
}

output "resource_group_name" {
  value = split("/", var.resource_group_id)[4]
}

output "resource_id" {
  value = azapi_resource.kv.id
}
