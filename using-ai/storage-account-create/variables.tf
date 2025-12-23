variable "resource_group_id" {
  type        = string
  description = "The resource group ID where the resources will be deployed."
}

variable "location" {
  type        = string
  description = "The storage account location."
}

variable "storage_account_type" {
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
      "Standard_ZRS"
    ], var.storage_account_type)
    error_message = "The storage account type must be one of the allowed values."
  }
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
  default     = null
}
