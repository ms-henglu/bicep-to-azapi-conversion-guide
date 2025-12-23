variable "webAppName" {
  type        = string
  default     = "AzureLinuxApp"
  description = "Base name of the resource such as web app name and app service plan "
}

variable "sku" {
  type        = string
  default     = "S1"
  description = "The SKU of App Service Plan "
}

variable "linuxFxVersion" {
  type        = string
  default     = "php|7.4"
  description = "The Runtime stack of current web app"
}

//[INFO] Variables not allowed as default input value. All usage of `location` will be replaced with `azurerm_resource_group.test.location`


locals {
  webAppPortalName = "${var.webAppName}-webapp"
}

locals {
  appServicePlanName = "AppServicePlan-${var.webAppName}"
}


resource "azapi_resource" "appServicePlan" {
  type                   = "Microsoft.Web/serverfarms@2022-03-01"
  name                   = local.appServicePlanName
  parent_id              = azurerm_resource_group.test.id
  response_export_values = ["id"]

  location = azurerm_resource_group.test.location
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
  name      = local.webAppPortalName
  parent_id = azurerm_resource_group.test.id

  location = azurerm_resource_group.test.location
  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "app"
    properties = {
      serverFarmId = azapi_resource.appServicePlan.output.id
      siteConfig = {
        linuxFxVersion = var.linuxFxVersion
        ftpsState      = "FtpsOnly"
      }
      httpsOnly = true
    }
  }
}



