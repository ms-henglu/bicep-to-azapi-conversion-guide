variable "resource_group_id" {
  type        = string
  description = "The resource group ID where the resources will be deployed."
}

variable "location" {
  type        = string
  description = "Specifies the Azure location where the key vault should be created."
}

variable "key_vault_name" {
  type        = string
  description = "Specifies the name of the key vault."
}

variable "enabled_for_deployment" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault."
}

variable "enabled_for_disk_encryption" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys."
}

variable "enabled_for_template_deployment" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault."
}

variable "tenant_id" {
  type        = string
  description = "Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. If not provided, defaults to the current subscription's tenant ID."
  default     = null
}

variable "object_id" {
  type        = string
  description = "Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault."
}

variable "keys_permissions" {
  type        = list(string)
  default     = ["list"]
  description = "Specifies the permissions to keys in the vault."
}

variable "secrets_permissions" {
  type        = list(string)
  default     = ["list"]
  description = "Specifies the permissions to secrets in the vault."
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "Specifies whether the key vault is a standard vault or a premium vault."
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The sku_name must be either 'standard' or 'premium'."
  }
}

variable "secret_name" {
  type        = string
  description = "Specifies the name of the secret that you want to create."
}

variable "secret_value" {
  type        = string
  sensitive   = true
  description = "Specifies the value of the secret that you want to create."
}
