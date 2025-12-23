variable "serverName" {
  type        = string
  description = "The name of the Azure Analysis Services server to create. Server name must begin with a letter, be lowercase alphanumeric, and between 3 and 63 characters in length. Server name must be unique per region."
}

//[INFO] Variables not allowed as default input value. All usage of `location` will be replaced with `azurerm_resource_group.test.location`

variable "skuName" {
  type        = string
  default     = "S0"
  description = "The sku name of the Azure Analysis Services server to create. Choose from: B1, B2, D1, S0, S1, S2, S3, S4, S8, S9. Some skus are region specific. See https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-overview#availability-by-region"
}

variable "capacity" {
  type        = number
  default     = 1
  description = "The total number of query replica scale-out instances. Scale-out of more than one instance is supported on selected regions only. See https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-overview#availability-by-region"
}

variable "firewallSettings" {
  type = map(any)
  default = {
    firewallRules = [
      {
        firewallRuleName = "AllowFromAll"
        rangeStart       = "0.0.0.0"
        rangeEnd         = "255.255.255.255"
      },
    ]
    enablePowerBIService = true
  }
  description = "The inbound firewall rules to define on the server. If not specified, firewall is disabled."
}

variable "backupBlobContainerUri" {
  type        = string
  default     = ""
  description = "The SAS URI to a private Azure Blob Storage container with read, write and list permissions. Required only if you intend to use the backup/restore functionality. See https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-backup"
}



resource "azapi_resource" "server" {
  type      = "Microsoft.AnalysisServices/servers@2017-08-01"
  name      = var.serverName
  parent_id = azurerm_resource_group.test.id

  location = azurerm_resource_group.test.location
  body = {
    sku = {
      name     = var.skuName
      capacity = var.capacity
    }
    properties = {
      ipV4FirewallSettings   = var.firewallSettings
      backupBlobContainerUri = var.backupBlobContainerUri
    }
  }
}



