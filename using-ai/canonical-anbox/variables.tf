variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "Location of all resources."
  type        = string
}

variable "add_dedicated_data_disk_for_lxd" {
  description = "Add a dedicated disk for the LXD storage pool"
  type        = bool
  default     = true
}

variable "administrator_public_ssh_key" {
  description = "Public SSH key of the virtual machine administrator"
  type        = string
  sensitive   = true
}

variable "administrator_username" {
  description = "Virtual machine administrator username"
  type        = string
}

variable "expose_anbox_container_services" {
  description = "Expose Anbox container services to the public internet on the port range 10000-11000; when false, Anbox container services will only be accessible from the virtual machine"
  type        = bool
  default     = false
}

variable "expose_anbox_management_service" {
  description = "Expose the Anbox Management Service to the public internet on port 8444; when false, the Anbox Management Service will only be accessible from the virtual machine"
  type        = bool
  default     = false
}

variable "network_security_group_name" {
  description = "Name of the virtual machine network interface security group"
  type        = string
  default     = "anboxVirtualMachineNetworkInterfaceSecurityGroup"
}

variable "subnet_address_prefix" {
  description = "CIDR block of the virtual network subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "subnet_name" {
  description = "Name of the virtual network subnet"
  type        = string
  default     = "anboxVirtualNetworkSubnet"
}

variable "ubuntu_image_offer" {
  description = "Offer of the Ubuntu image from which to launch the virtual machine; must be a Pro offer if an argument is not provided for the ubuntuProToken parameter"
  type        = string
  default     = "0001-com-ubuntu-pro-jammy"
}

variable "ubuntu_image_sku" {
  description = "SKU of the Ubuntu image from which to launch the virtual machine; must be a Pro SKU if an argument is not provided for the ubuntuProToken parameter"
  type        = string
  default     = "pro-22_04-lts-gen2"
}

variable "ubuntu_pro_token" {
  description = "Ubuntu Pro token to attach to the virtual machine; will be ignored by cloud-init if the arguments provided for the ubuntuImageOffer and ubuntuImageSKU parameters correspond to a Pro image"
  type        = string
  default     = ""
}

variable "virtual_machine_data_disk_size_in_gb" {
  description = "Size of the virtual machine data disk (LXD storage pool) when applicable; see the addDedicatedDataDiskForLXD parameter"
  type        = number
  default     = 100
  validation {
    condition     = var.virtual_machine_data_disk_size_in_gb >= 100 && var.virtual_machine_data_disk_size_in_gb <= 1023
    error_message = "The data disk size must be between 100 and 1023 GB."
  }
}

variable "virtual_machine_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "anboxVirtualMachine"
}

variable "virtual_machine_operating_system_disk_size_in_gb" {
  description = "Size of the virtual machine operating system disk"
  type        = number
  default     = 40
  validation {
    condition     = var.virtual_machine_operating_system_disk_size_in_gb >= 40 && var.virtual_machine_operating_system_disk_size_in_gb <= 1023
    error_message = "The OS disk size must be between 40 and 1023 GB."
  }
}

variable "virtual_machine_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "virtual_network_address_prefix" {
  description = "CIDR block of the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "anboxVirtualNetwork"
}
