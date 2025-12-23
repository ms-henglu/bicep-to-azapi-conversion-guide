variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group where resources will be deployed."
}

variable "location" {
  type        = string
  description = "Location for all resources."
}

variable "vm_name" {
  type        = string
  default     = "simpleLinuxVM"
  description = "The name of your Virtual Machine."
}

variable "admin_username" {
  type        = string
  description = "Username for the Virtual Machine."
}

variable "authentication_type" {
  type        = string
  default     = "password"
  description = "Type of authentication to use on the Virtual Machine. SSH key is recommended."
  validation {
    condition     = contains(["sshPublicKey", "password"], var.authentication_type)
    error_message = "The authentication_type must be either 'sshPublicKey' or 'password'."
  }
}

variable "admin_password_or_key" {
  type        = string
  sensitive   = true
  description = "SSH Key or password for the Virtual Machine. SSH key is recommended."
}

variable "dns_label_prefix" {
  type        = string
  default     = null
  description = "Unique DNS Name for the Public IP used to access the Virtual Machine. If not provided, a unique one will be generated."
}

variable "ubuntu_os_version" {
  type        = string
  default     = "Ubuntu-2004"
  description = "The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version."
  validation {
    condition     = contains(["Ubuntu-2004", "Ubuntu-2204"], var.ubuntu_os_version)
    error_message = "The ubuntu_os_version must be either 'Ubuntu-2004' or 'Ubuntu-2204'."
  }
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "The size of the VM"
}

variable "virtual_network_name" {
  type        = string
  default     = "vNet"
  description = "Name of the VNET"
}

variable "subnet_name" {
  type        = string
  default     = "Subnet"
  description = "Name of the subnet in the virtual network"
}

variable "network_security_group_name" {
  type        = string
  default     = "SecGroupNet"
  description = "Name of the Network Security Group"
}

variable "security_type" {
  type        = string
  default     = "TrustedLaunch"
  description = "Security Type of the Virtual Machine."
  validation {
    condition     = contains(["Standard", "TrustedLaunch"], var.security_type)
    error_message = "The security_type must be either 'Standard' or 'TrustedLaunch'."
  }
}
