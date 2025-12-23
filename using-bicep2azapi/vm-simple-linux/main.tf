variable "vmName" {
  type = string
  default = "simpleLinuxVM"
  description = "The name of your Virtual Machine."
}

variable "adminUsername" {
  type = string
  description = "Username for the Virtual Machine."
}

variable "authenticationType" {
  type = string
  default = "password"
  description = "Type of authentication to use on the Virtual Machine. SSH key is recommended."
  validation {
    condition     = contains([
      "sshPublicKey",
      "password",
    ], var.authenticationType)
    error_message = "Allowed values are ['sshPublicKey','password']."
  }
}

variable "adminPasswordOrKey" {
  type = string
  description = "SSH Key or password for the Virtual Machine. SSH key is recommended."
}

variable "dnsLabelPrefix" {
  type = string
//[WARN]  Variables not allowed as default input value. default value: lower("${var.vmName}-${"3b8c19e6cead4"}")
  description = "Unique DNS Name for the Public IP used to access the Virtual Machine."
}

variable "ubuntuOSVersion" {
  type = string
  default = "Ubuntu-2004"
  description = "The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version."
  validation {
    condition     = contains([
      "Ubuntu-2004",
      "Ubuntu-2204",
    ], var.ubuntuOSVersion)
    error_message = "Allowed values are ['Ubuntu-2004','Ubuntu-2204']."
  }
}

//[INFO] Variables not allowed as default input value. All usage of `location` will be replaced with `azurerm_resource_group.test.location`

variable "vmSize" {
  type = string
  default = "Standard_D2s_v3"
  description = "The size of the VM"
}

variable "virtualNetworkName" {
  type = string
  default = "vNet"
  description = "Name of the VNET"
}

variable "subnetName" {
  type = string
  default = "Subnet"
  description = "Name of the subnet in the virtual network"
}

variable "networkSecurityGroupName" {
  type = string
  default = "SecGroupNet"
  description = "Name of the Network Security Group"
}

variable "securityType" {
  type = string
  default = "TrustedLaunch"
  description = "Security Type of the Virtual Machine."
  validation {
    condition     = contains([
      "Standard",
      "TrustedLaunch",
    ], var.securityType)
    error_message = "Allowed values are ['Standard','TrustedLaunch']."
  }
}


locals {
  imageReference = {
    Ubuntu-2004 = {
      publisher = "Canonical"
      offer = "0001-com-ubuntu-server-focal"
      sku = "20_04-lts-gen2"
      version = "latest"
    }
    Ubuntu-2204 = {
      publisher = "Canonical"
      offer = "0001-com-ubuntu-server-jammy"
      sku = "22_04-lts-gen2"
      version = "latest"
    }
  }
}

locals {
  publicIPAddressName = "${var.vmName}PublicIP"
}

locals {
  networkInterfaceName = "${var.vmName}NetInt"
}

locals {
  osDiskType = "Standard_LRS"
}

locals {
  subnetAddressPrefix = "10.1.0.0/24"
}

locals {
  addressPrefix = "10.1.0.0/16"
}

locals {
  linuxConfiguration = {
    disablePasswordAuthentication = true
    ssh = {
      publicKeys = [
        {
          path = "/home/${var.adminUsername}/.ssh/authorized_keys"
          keyData = var.adminPasswordOrKey
        },
      ]
    }
  }
}

locals {
  securityProfileJson = {
    uefiSettings = {
      secureBootEnabled = true
      vTpmEnabled = true
    }
    securityType = var.securityType
  }
}

locals {
  extensionName = "GuestAttestation"
}

locals {
  extensionPublisher = "Microsoft.Azure.Security.LinuxAttestation"
}

locals {
  extensionVersion = "1.0"
}

locals {
  maaTenantName = "GuestAttestation"
}

locals {
  maaEndpoint = substr("emptystring", 0, 0)
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
          name = "ipconfig1"
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
      ]
    }
  }
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
          local.addressPrefix,
        ]
      }
      subnets = [
        {
          name = var.subnetName
          properties = {
            networkSecurityGroup = {
              id = azapi_resource.networkSecurityGroup.output.id
            }
            addressPrefix = local.subnetAddressPrefix
            privateEndpointNetworkPolicies = "Enabled"
            privateLinkServiceNetworkPolicies = "Enabled"
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
    sku = {
      name = "Basic"
    }
    properties = {
      publicIPAllocationMethod = "Dynamic"
      publicIPAddressVersion = "IPv4"
      dnsSettings = {
        domainNameLabel = var.dnsLabelPrefix
      }
      idleTimeoutInMinutes = 4
    }
  }
}

resource "azapi_resource" "vm" {
  type      = "Microsoft.Compute/virtualMachines@2023-09-01"
  name      = var.vmName
  parent_id = azurerm_resource_group.test.id

  location = azurerm_resource_group.test.location
  body = {
    properties = {
      hardwareProfile = {
        vmSize = var.vmSize
      }
      storageProfile = {
        osDisk = {
          createOption = "FromImage"
          managedDisk = {
            storageAccountType = local.osDiskType
          }
        }
        imageReference = 
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.networkInterface.output.id
          },
        ]
      }
      osProfile = {
        computerName = var.vmName
        adminUsername = var.adminUsername
        adminPassword = var.adminPasswordOrKey
        linuxConfiguration = ((var.authenticationType == "password") ? null : local.linuxConfiguration)
      }
      securityProfile = (var.securityType == "TrustedLaunch") ? local.securityProfileJson : null
    }
  }
}

resource "azapi_resource" "vmExtension" {
  type      = "Microsoft.Compute/virtualMachines/extensions@2023-09-01"
  name      = local.extensionName
  parent_id = azapi_resource.vm.id

  count       = (var.securityType == "TrustedLaunch" && local.securityProfileJson.uefiSettings.secureBootEnabled && local.securityProfileJson.uefiSettings.vTpmEnabled) ? 1 : 0
  location = azurerm_resource_group.test.location
  body = {
    properties = {
      publisher = local.extensionPublisher
      type = local.extensionName
      typeHandlerVersion = local.extensionVersion
      autoUpgradeMinorVersion = true
      enableAutomaticUpgrade = true
      settings = {
        AttestationConfig = {
          MaaSettings = {
            maaEndpoint = local.maaEndpoint
            maaTenantName = local.maaTenantName
          }
        }
      }
    }
  }
}


output "adminUsername" {
  value = var.adminUsername
}

output "hostname" {
  value = azapi_resource.publicIPAddress.output.properties.output.dnsSettings.output.fqdn
}

output "sshCommand" {
  value = "ssh ${var.adminUsername}@${azapi_resource.publicIPAddress.output.properties.output.dnsSettings.output.fqdn}"
}


