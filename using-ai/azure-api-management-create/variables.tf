variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "location" {
  type        = string
  description = "Location for all resources. Defaults to the resource group location."
  default     = ""
}

variable "api_management_service_name" {
  type        = string
  description = "The name of the API Management service instance."
  default     = "apiservice-example"
}

variable "publisher_email" {
  type        = string
  description = "The email address of the owner of the service."
}

variable "publisher_name" {
  type        = string
  description = "The name of the owner of the service."
}

variable "sku" {
  type        = string
  description = "The pricing tier of this API Management service."
  default     = "Developer"
  validation {
    condition     = contains(["Consumption", "Developer", "Basic", "Basicv2", "Standard", "Standardv2", "Premium"], var.sku)
    error_message = "The sku must be one of the following: Consumption, Developer, Basic, Basicv2, Standard, Standardv2, Premium."
  }
}

variable "sku_count" {
  type        = number
  description = "The instance size of this API Management service."
  default     = 1
  validation {
    condition     = contains([0, 1, 2], var.sku_count)
    error_message = "The sku_count must be one of the following: 0, 1, 2."
  }
}
