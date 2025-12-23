//[INFO] Variables not allowed as default input value. All usage of `location` will be replaced with `azurerm_resource_group.test.location`

variable "apiCenterName" {
  type        = string
  default     = "apicenter${"d6898d9925774"}"
  description = "The name of the API center."
}

variable "apiName" {
  type        = string
  default     = "first-api"
  description = "The name of an API to register in the API center."
}

variable "apiType" {
  type        = string
  default     = "rest"
  description = "The type of the API to register in the API center."
  validation {
    condition = contains([
      "rest",
      "soap",
      "graphql",
      "grpc",
      "webhook",
      "websocket",
    ], var.apiType)
    error_message = "Allowed values are ['rest','soap','graphql','grpc','webhook','websocket']."
  }
}



resource "azapi_resource" "apiCenterService" {
  type      = "Microsoft.ApiCenter/services@2024-03-01"
  name      = var.apiCenterName
  parent_id = azurerm_resource_group.test.id

  location = azurerm_resource_group.test.location
  body = {
    properties = {
    }
  }
}

resource "azapi_resource" "apiCenterWorkspace" {
  type      = "Microsoft.ApiCenter/services/workspaces@2024-03-01"
  name      = "default"
  parent_id = azapi_resource.apiCenterService.id

  body = {
    properties = {
      title       = "Default workspace"
      description = "Default workspace"
    }
  }
}

resource "azapi_resource" "apiCenterAPI" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis@2024-03-01"
  name      = var.apiName
  parent_id = azapi_resource.apiCenterWorkspace.id

  body = {
    properties = {
      title = var.apiName
      kind  = var.apiType
      externalDocumentation = [
        {
          description = "API Center documentation"
          title       = "API Center documentation"
          url         = "https://learn.microsoft.com/azure/api-center/overview"
        },
      ]
      contacts = [
        {
          email = "apideveloper@contoso.com"
          name  = "API Developer"
          url   = "https://learn.microsoft.com/azure/api-center/overview"
        },
      ]
      customProperties = {
      }
      summary     = "This is a test API, deployed using a template!"
      description = "This is a test API, deployed using a template!"
    }
  }
}



