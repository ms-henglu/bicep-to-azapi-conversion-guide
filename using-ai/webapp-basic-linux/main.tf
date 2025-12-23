terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azapi" {
}

resource "azapi_resource" "appServicePlan" {
  type      = "Microsoft.Web/serverfarms@2022-03-01"
  name      = "AppServicePlan-${var.webAppName}"
  parent_id = var.resource_group_id
  location  = var.location

  body = {
    sku = {
      name = var.sku
    }
    kind = "linux"
    properties = {
      reserved = true
    }
  }
}

resource "azapi_resource" "webAppPortal" {
  type      = "Microsoft.Web/sites@2022-03-01"
  name      = "${var.webAppName}-webapp"
  parent_id = var.resource_group_id
  location  = var.location

  body = {
    kind = "app"
    properties = {
      serverFarmId = azapi_resource.appServicePlan.id
      siteConfig = {
        linuxFxVersion = var.linuxFxVersion
        ftpsState      = "FtpsOnly"
      }
      httpsOnly = true
    }
    identity = {
      type = "SystemAssigned"
    }
  }
}
