variable "keyVaultName" {
  type        = string
  description = "Specifies the name of the key vault."
}

//[INFO] Variables not allowed as default input value. All usage of `location` will be replaced with `azurerm_resource_group.test.location`

variable "enabledForDeployment" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault."
}

variable "enabledForDiskEncryption" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys."
}

variable "enabledForTemplateDeployment" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault."
}

//[INFO] Variables not allowed as default input value. All usage of `tenantId` will be replaced with `data.azurerm_client_config.current.tenant_id`

variable "objectId" {
  type        = string
  description = "Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets."
}

variable "keysPermissions" {
  type = list(any)
  default = [
    "list",
  ]
  description = "Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge."
}

variable "secretsPermissions" {
  type = list(any)
  default = [
    "list",
  ]
  description = "Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge."
}

variable "skuName" {
  type        = string
  default     = "standard"
  description = "Specifies whether the key vault is a standard vault or a premium vault."
  validation {
    condition = contains([
      "standard",
      "premium",
    ], var.skuName)
    error_message = "Allowed values are ['standard','premium']."
  }
}

variable "secretName" {
  type        = string
  description = "Specifies the name of the secret that you want to create."
}

variable "secretValue" {
  type        = string
  description = "Specifies the value of the secret that you want to create."
}



resource "azapi_resource" "kv" {
  type                   = "Microsoft.KeyVault/vaults@2023-07-01"
  name                   = var.keyVaultName
  parent_id              = azurerm_resource_group.test.id
  response_export_values = ["name", "id"]

  location = azurerm_resource_group.test.location
  body = {
    properties = {
      enabledForDeployment         = var.enabledForDeployment
      enabledForDiskEncryption     = var.enabledForDiskEncryption
      enabledForTemplateDeployment = var.enabledForTemplateDeployment
      tenantId                     = data.azurerm_client_config.current.tenant_id
      enableSoftDelete             = true
      softDeleteRetentionInDays    = 90
      accessPolicies = [
        {
          objectId = var.objectId
          tenantId = data.azurerm_client_config.current.tenant_id
          permissions = {
            keys    = var.keysPermissions
            secrets = var.secretsPermissions
          }
        },
      ]
      sku = {
        name   = var.skuName
        family = "A"
      }
      networkAcls = {
        defaultAction = "Allow"
        bypass        = "AzureServices"
      }
    }
  }
}

resource "azapi_resource" "secret" {
  type      = "Microsoft.KeyVault/vaults/secrets@2023-07-01"
  name      = var.secretName
  parent_id = azapi_resource.kv.id

  body = {
    properties = {
      value = var.secretValue
    }
  }
}


output "location" {
  value = azurerm_resource_group.test.location
}

output "name" {
  value = azapi_resource.kv.output.name
}

output "resourceGroupName" {
  value = azurerm_resource_group.test.name
}

output "resourceId" {
  value = azapi_resource.kv.output.id
}


