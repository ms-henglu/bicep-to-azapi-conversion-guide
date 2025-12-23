terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azapi" {
}

resource "azapi_resource" "server" {
  type      = "Microsoft.AnalysisServices/servers@2017-08-01"
  name      = var.server_name
  location  = var.location
  parent_id = var.resource_group_id

  body = {
    sku = {
      name     = var.sku_name
      capacity = var.capacity
    }
    properties = {
      ipV4FirewallSettings   = var.firewall_settings
      backupBlobContainerUri = var.backup_blob_container_uri
    }
  }
}
