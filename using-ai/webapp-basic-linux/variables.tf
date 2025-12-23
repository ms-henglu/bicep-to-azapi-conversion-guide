variable "resource_group_id" {
  type        = string
  description = "The resource group ID where the resources will be deployed."
}

variable "location" {
  type        = string
  description = "Location for all resources."
}

variable "webAppName" {
  type        = string
  description = "Base name of the resource such as web app name and app service plan"
  default     = "AzureLinuxApp"
  validation {
    condition     = length(var.webAppName) >= 2
    error_message = "The webAppName must be at least 2 characters long."
  }
}

variable "sku" {
  type        = string
  description = "The SKU of App Service Plan"
  default     = "S1"
}

variable "linuxFxVersion" {
  type        = string
  description = "The Runtime stack of current web app"
  default     = "php|7.4"
}
