terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azapi" {}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azapi_resource" "api_management" {
  type      = "Microsoft.ApiManagement/service@2023-05-01-preview"
  name      = var.api_management_service_name
  parent_id = data.azurerm_resource_group.rg.id
  location  = var.location == "" ? data.azurerm_resource_group.rg.location : var.location

  body = {
    sku = {
      name     = var.sku
      capacity = var.sku_count
    }
    properties = {
      publisherEmail = var.publisher_email
      publisherName  = var.publisher_name
    }
  }
}
