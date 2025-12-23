output "ssh_command" {
  value = "ssh -i $PATH_TO_ADMINISTRATOR_PRIVATE_SSH_KEY ${var.administrator_username}@${azapi_resource.public_ip_address.output.properties.ipAddress}"
}

output "virtual_machine_public_ip_address" {
  value = azapi_resource.public_ip_address.output.properties.ipAddress
}
