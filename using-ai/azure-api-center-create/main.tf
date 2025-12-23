terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "azapi" {
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  api_center_name = var.api_center_name == "" ? "apicenter${random_string.suffix.result}" : var.api_center_name
  location        = var.location == "" ? data.azurerm_resource_group.rg.location : var.location
}

resource "azapi_resource" "service" {
  type      = "Microsoft.ApiCenter/services@2024-03-01"
  name      = local.api_center_name
  location  = local.location
  parent_id = data.azurerm_resource_group.rg.id

  body = {
    properties = {}
  }
}

resource "azapi_resource" "workspace" {
  type      = "Microsoft.ApiCenter/services/workspaces@2024-03-01"
  name      = "default"
  parent_id = azapi_resource.service.id

  body = {
    properties = {
      title       = "Default workspace"
      description = "Default workspace"
    }
  }
}

resource "azapi_resource" "api" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis@2024-03-01"
  name      = var.api_name
  parent_id = azapi_resource.workspace.id

  body = {
    properties = {
      title = var.api_name
      kind  = var.api_type
      externalDocumentation = [
        {
          description = "API Center documentation"
          title       = "API Center documentation"
          url         = "https://learn.microsoft.com/azure/api-center/overview"
        }
      ]
      contacts = [
        {
          email = "apideveloper@contoso.com"
          name  = "API Developer"
          url   = "https://learn.microsoft.com/azure/api-center/overview"
        }
      ]
      customProperties = {}
      summary          = "This is a test API, deployed using a template!"
      description      = "This is a test API, deployed using a template!"
    }
  }
}
