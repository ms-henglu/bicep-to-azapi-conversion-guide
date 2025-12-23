terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azapi" {}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

locals {
  tenant_id = var.tenant_id != null ? var.tenant_id : data.azurerm_client_config.current.tenant_id
}

resource "azapi_resource" "kv" {
  type      = "Microsoft.KeyVault/vaults@2023-07-01"
  name      = var.key_vault_name
  location  = var.location
  parent_id = var.resource_group_id

  body = {
    properties = {
      enabledForDeployment         = var.enabled_for_deployment
      enabledForDiskEncryption     = var.enabled_for_disk_encryption
      enabledForTemplateDeployment = var.enabled_for_template_deployment
      tenantId                     = local.tenant_id
      enableSoftDelete             = true
      softDeleteRetentionInDays    = 90
      accessPolicies = [
        {
          objectId = var.object_id
          tenantId = local.tenant_id
          permissions = {
            keys    = var.keys_permissions
            secrets = var.secrets_permissions
          }
        }
      ]
      sku = {
        name   = var.sku_name
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
  name      = var.secret_name
  parent_id = azapi_resource.kv.id

  body = {
    properties = {
      value = var.secret_value
    }
  }
}
