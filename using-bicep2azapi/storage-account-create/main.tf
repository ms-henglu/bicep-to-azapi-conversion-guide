variable "storageAccountType" {
  type        = string
  default     = "Standard_LRS"
  description = "Storage Account type"
  validation {
    condition = contains([
      "Premium_LRS",
      "Premium_ZRS",
      "Standard_GRS",
      "Standard_GZRS",
      "Standard_LRS",
      "Standard_RAGRS",
      "Standard_RAGZRS",
      "Standard_ZRS",
    ], var.storageAccountType)
    error_message = "Allowed values are ['Premium_LRS','Premium_ZRS','Standard_GRS','Standard_GZRS','Standard_LRS','Standard_RAGRS','Standard_RAGZRS','Standard_ZRS']."
  }
}

//[INFO] Variables not allowed as default input value. All usage of `location` will be replaced with `azurerm_resource_group.test.location`

variable "storageAccountName" {
  type        = string
  default     = "store${"9464f0236eb34"}"
  description = "The name of the storage account"
}



resource "azapi_resource" "sa" {
  type                   = "Microsoft.Storage/storageAccounts@2022-09-01"
  name                   = var.storageAccountName
  parent_id              = azurerm_resource_group.test.id
  response_export_values = ["id"]

  location = azurerm_resource_group.test.location
  body = {
    sku = {
      name = var.storageAccountType
    }
    kind = "StorageV2"
    properties = {
    }
  }
}


output "storageAccountName" {
  value = var.storageAccountName
}

output "storageAccountId" {
  value = azapi_resource.sa.output.id
}


