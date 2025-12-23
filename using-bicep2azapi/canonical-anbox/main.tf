variable "addDedicatedDataDiskForLXD" {
  type = bool
  default = true
  description = "Add a dedicated disk for the LXD storage pool"
}

variable "administratorPublicSSHKey" {
  type = string
  description = "Public SSH key of the virtual machine administrator"
}

variable "administratorUsername" {
  type = string
  description = "Virtual machine administrator username"
}

variable "exposeAnboxContainerServices" {
  type = bool
  default = false
  description = "Expose Anbox container services to the public internet on the port range 10000-11000; when false, Anbox container services will only be accessible from the virtual machine"
}

variable "exposeAnboxManagementService" {
  type = bool
  default = false
  description = "Expose the Anbox Management Service to the public internet on port 8444; when false, the Anbox Management Service will only be accessible from the virtual machine"
}

//[INFO] Variables not allowed as default input value. All usage of `location` will be replaced with `azurerm_resource_group.test.location`

variable "networkSecurityGroupName" {
  type = string
  default = "anboxVirtualMachineNetworkInterfaceSecurityGroup"
  description = "Name of the virtual machine network interface security group"
}

variable "subnetAddressPrefix" {
  type = string
  default = "10.0.0.0/24"
  description = "CIDR block of the virtual network subnet"
}

variable "subnetName" {
  type = string
  default = "anboxVirtualNetworkSubnet"
  description = "Name of the virtual network subnet"
}

variable "ubuntuImageOffer" {
  type = string
  default = "0001-com-ubuntu-pro-jammy"
  description = "Offer of the Ubuntu image from which to launch the virtual machine; must be a Pro offer if an argument is not provided for the ubuntuProToken parameter"
}

variable "ubuntuImageSKU" {
  type = string
  default = "pro-22_04-lts-gen2"
  description = "SKU of the Ubuntu image from which to launch the virtual machine; must be a Pro SKU if an argument is not provided for the ubuntuProToken parameter"
}

variable "ubuntuProToken" {
  type = string
  default = ""
  description = "Ubuntu Pro token to attach to the virtual machine; will be ignored by cloud-init if the arguments provided for the ubuntuImageOffer and ubuntuImageSKU parameters correspond to a Pro image (see https://cloudinit.readthedocs.io/en/latest/reference/modules.html#ubuntu-pro)"
}

variable "virtualMachineDataDiskSizeInGB" {
  type = number
  default = 100
  description = "Size of the virtual machine data disk (LXD storage pool) when applicable; see the addDedicatedDataDiskForLXD parameter; must comply with https://anbox-cloud.io/docs/reference/requirements#anbox-cloud-appliance-4"
}

variable "virtualMachineName" {
  type = string
  default = "anboxVirtualMachine"
  description = "Name of the virtual machine"
}

variable "virtualMachineOperatingSystemDiskSizeInGB" {
  type = number
  default = 40
  description = "Size of the virtual machine operating system disk; must comply with https://anbox-cloud.io/docs/reference/requirements#anbox-cloud-appliance-4"
}

variable "virtualMachineSize" {
  type = string
  default = "Standard_D4s_v5"
  description = "Size of the virtual machine; must comply with https://anbox-cloud.io/docs/reference/requirements#anbox-cloud-appliance-4"
}

variable "virtualNetworkAddressPrefix" {
  type = string
  default = "10.0.0.0/16"
  description = "CIDR block of the virtual network"
}

variable "virtualNetworkName" {
  type = string
  default = "anboxVirtualNetwork"
  description = "Name of the virtual network"
}


locals {
  anboxDestinationPortRangesAnboxManagementService = var.exposeAnboxManagementService ? [
    "8444",
  ] : [
  ]
}

locals {
  anboxDestinationPortRangesBase = [
    "80",
    "443",
    "5349",
    "60000-60100",
  ]
}

locals {
  anboxDestinationPortRangesContainers = var.exposeAnboxContainerServices ? [
    "10000-11000",
  ] : [
  ]
}

locals {
  anboxDestinationPortRanges = 
}

locals {
  cloudConfigWithToken = "#cloud-config

package_upgrade: true

ubuntu_advantage:
  token: ubuntuProToken
  enable:
    - anbox-cloud"
}

locals {
  cloudConfigWithoutToken = "#cloud-config

package_upgrade: true

ubuntu_advantage:
  enable:
    - anbox-cloud"
}

locals {
  cloudConfig = 
}

locals {
  dataDisks = var.addDedicatedDataDiskForLXD ? [
    {
      createOption = "Empty"
      diskSizeGB = var.virtualMachineDataDiskSizeInGB
      lun = 0
      managedDisk = {
        storageAccountType = "Premium_LRS"
      }
    },
  ] : [
  ]
}

locals {
  imagePlan = length(var.ubuntuProToken) == 0 ? {
    name = var.ubuntuImageSKU
    product = var.ubuntuImageOffer
    publisher = "canonical"
  } : null
}

locals {
  linuxConfiguration = {
    disablePasswordAuthentication = true
    ssh = {
      publicKeys = [
        {
          path = "/home/${var.administratorUsername}/.ssh/authorized_keys"
          keyData = var.administratorPublicSSHKey
        },
      ]
    }
  }
}

locals {
  networkInterfaceName = "${var.virtualMachineName}NetworkInterface"
}

locals {
  publicIPAddressName = "${var.virtualMachineName}PublicIP"
}


resource "azapi_resource" "virtualNetwork" {
  type      = "Microsoft.Network/virtualNetworks@2023-09-01"
  name      = var.virtualNetworkName
  parent_id = azurerm_resource_group.test.id

  location = azurerm_resource_group.test.location
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = [
          var.virtualNetworkAddressPrefix,
        ]
      }
      subnets = [
        {
          name = var.subnetName
          properties = {
            addressPrefix = var.subnetAddressPrefix
          }
        },
      ]
    }
  }
}

resource "azapi_resource" "networkSecurityGroup" {
  type      = "Microsoft.Network/networkSecurityGroups@2023-09-01"
  name      = var.networkSecurityGroupName
  parent_id = azurerm_resource_group.test.id
  response_export_values = ["id"]

  location = azurerm_resource_group.test.location
  body = {
    properties = {
      securityRules = [
        {
          name = "SSH"
          properties = {
            priority = 1000
            protocol = "Tcp"
            access = "Allow"
            direction = "Inbound"
            sourceAddressPrefix = "*"
            sourcePortRange = "*"
            destinationAddressPrefix = "*"
            destinationPortRange = "22"
          }
        },
        {
          name = "Anbox"
          properties = {
            priority = 1010
            protocol = "*"
            access = "Allow"
            direction = "Inbound"
            sourceAddressPrefix = "*"
            sourcePortRange = "*"
            destinationAddressPrefix = "*"
            destinationPortRanges = local.anboxDestinationPortRanges
          }
        },
      ]
    }
  }
}

resource "azapi_resource" "publicIPAddress" {
  type      = "Microsoft.Network/publicIPAddresses@2023-09-01"
  name      = local.publicIPAddressName
  parent_id = azurerm_resource_group.test.id
  response_export_values = ["id", "properties"]

  location = azurerm_resource_group.test.location
  body = {
    properties = {
      publicIPAllocationMethod = "Static"
      publicIPAddressVersion = "IPv4"
    }
  }
}

resource "azapi_resource" "networkInterface" {
  type      = "Microsoft.Network/networkInterfaces@2023-09-01"
  name      = local.networkInterfaceName
  parent_id = azurerm_resource_group.test.id
  response_export_values = ["id"]

  location = azurerm_resource_group.test.location
  body = {
    properties = {
      ipConfigurations = [
        {
          name = "${local.networkInterfaceName}IPConfiguration"
          properties = {
            subnet = {
              id = .id
            }
            privateIPAllocationMethod = "Dynamic"
            publicIPAddress = {
              id = azapi_resource.publicIPAddress.output.id
            }
          }
        },
      ]
      networkSecurityGroup = {
        id = azapi_resource.networkSecurityGroup.output.id
      }
    }
  }
}

resource "azapi_resource" "virtualMachine" {
  type      = "Microsoft.Compute/virtualMachines@2023-09-01"
  name      = var.virtualMachineName
  parent_id = azurerm_resource_group.test.id

  location = azurerm_resource_group.test.location
  body = {
    plan = local.imagePlan
    properties = {
      hardwareProfile = {
        vmSize = var.virtualMachineSize
      }
      storageProfile = {
        osDisk = {
          createOption = "FromImage"
          diskSizeGB = var.virtualMachineOperatingSystemDiskSizeInGB
          managedDisk = {
            storageAccountType = "Standard_LRS"
          }
        }
        imageReference = {
          publisher = "Canonical"
          offer = var.ubuntuImageOffer
          sku = var.ubuntuImageSKU
          version = "latest"
        }
        dataDisks = local.dataDisks
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.networkInterface.output.id
          },
        ]
      }
      osProfile = {
        computerName = var.virtualMachineName
        adminUsername = var.administratorUsername
        adminPassword = var.administratorPublicSSHKey
        linuxConfiguration = local.linuxConfiguration
        customData = local.cloudConfig
      }
    }
  }
}


output "sshCommand" {
  value = "ssh -i $PATH_TO_ADMINISTRATOR_PRIVATE_SSH_KEY ${var.administratorUsername}@${azapi_resource.publicIPAddress.output.properties.output.ipAddress}"
}

output "virtualMachinePublicIPAddress" {
  value = azapi_resource.publicIPAddress.output.properties.output.ipAddress
}


