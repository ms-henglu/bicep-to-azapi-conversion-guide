variable "resource_group_id" {
  type        = string
  description = "The resource group ID where the resources will be deployed."
}

variable "location" {
  type        = string
  description = "Location of the Azure Analysis Services server."
}

variable "server_name" {
  type        = string
  description = "The name of the Azure Analysis Services server to create. Server name must begin with a letter, be lowercase alphanumeric, and between 3 and 63 characters in length. Server name must be unique per region."
}

variable "sku_name" {
  type        = string
  default     = "S0"
  description = "The sku name of the Azure Analysis Services server to create. Choose from: B1, B2, D1, S0, S1, S2, S3, S4, S8, S9. Some skus are region specific."
}

variable "capacity" {
  type        = number
  default     = 1
  description = "The total number of query replica scale-out instances. Scale-out of more than one instance is supported on selected regions only."
}

variable "firewall_settings" {
  type = object({
    firewallRules = list(object({
      firewallRuleName = string
      rangeStart       = string
      rangeEnd         = string
    }))
    enablePowerBIService = bool
  })
  default = {
    firewallRules = [
      {
        firewallRuleName = "AllowFromAll"
        rangeStart       = "0.0.0.0"
        rangeEnd         = "255.255.255.255"
      }
    ]
    enablePowerBIService = true
  }
  description = "The inbound firewall rules to define on the server. If not specified, firewall is disabled."
}

variable "backup_blob_container_uri" {
  type        = string
  default     = ""
  description = "The SAS URI to a private Azure Blob Storage container with read, write and list permissions. Required only if you intend to use the backup/restore functionality."
}
