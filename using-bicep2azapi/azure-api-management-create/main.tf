variable "apiManagementServiceName" {
  type        = string
  default     = "apiservice${"edd2f60e55e54"}"
  description = "The name of the API Management service instance"
}

variable "publisherEmail" {
  type        = string
  description = "The email address of the owner of the service"
}

variable "publisherName" {
  type        = string
  description = "The name of the owner of the service"
}

variable "sku" {
  type        = string
  default     = "Developer"
  description = "The pricing tier of this API Management service"
  validation {
    condition = contains([
      "Consumption",
      "Developer",
      "Basic",
      "Basicv2",
      "Standard",
      "Standardv2",
      "Premium",
    ], var.sku)
    error_message = "Allowed values are ['Consumption','Developer','Basic','Basicv2','Standard','Standardv2','Premium']."
  }
}

variable "skuCount" {
  type        = number
  default     = 1
  description = "The instance size of this API Management service."
  validation {
    condition = contains([
      0,
      1,
      2,
    ], var.skuCount)
    error_message = "Allowed values are [0,1,2]."
  }
}

//[INFO] Variables not allowed as default input value. All usage of `location` will be replaced with `azurerm_resource_group.test.location`



resource "azapi_resource" "apiManagementService" {
  type      = "Microsoft.ApiManagement/service@2023-05-01-preview"
  name      = var.apiManagementServiceName
  parent_id = azurerm_resource_group.test.id

  location = azurerm_resource_group.test.location
  body = {
    sku = {
      name     = var.sku
      capacity = var.skuCount
    }
    properties = {
      publisherEmail = var.publisherEmail
      publisherName  = var.publisherName
    }
  }
}



