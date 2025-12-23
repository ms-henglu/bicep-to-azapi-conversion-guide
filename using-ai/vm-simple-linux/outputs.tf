output "admin_username" {
  value = var.admin_username
}

output "hostname" {
  value = azapi_resource.public_ip_address.output.properties.dnsSettings.fqdn
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${azapi_resource.public_ip_address.output.properties.dnsSettings.fqdn}"
}
