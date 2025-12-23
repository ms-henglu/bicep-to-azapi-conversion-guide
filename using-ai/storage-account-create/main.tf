terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

resource "random_string" "unique" {
  length  = 13
  special = false
  upper   = false
  numeric = true
}

locals {
  storage_account_name = var.storage_account_name != null ? var.storage_account_name : "store${random_string.unique.result}"
}

resource "azapi_resource" "sa" {
  type      = "Microsoft.Storage/storageAccounts@2022-09-01"
  name      = local.storage_account_name
  location  = var.location
  parent_id = var.resource_group_id

  body = {
    sku = {
      name = var.storage_account_type
    }
    kind = "StorageV2"
    properties = {}
  }
}
