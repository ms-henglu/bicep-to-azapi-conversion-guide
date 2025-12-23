terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "azapi" {
}

resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

locals {
  dns_label_prefix = var.dns_label_prefix != null ? var.dns_label_prefix : lower("${var.vm_name}-${random_string.unique.result}")
  
  image_reference = {
    "Ubuntu-2004" = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts-gen2"
      version   = "latest"
    }
    "Ubuntu-2204" = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
  }

  linux_configuration = {
    disablePasswordAuthentication = true
    ssh = {
      publicKeys = [
        {
          path    = "/home/${var.admin_username}/.ssh/authorized_keys"
          keyData = var.admin_password_or_key
        }
      ]
    }
  }

  security_profile_json = {
    uefiSettings = {
      secureBootEnabled = true
      vTpmEnabled       = true
    }
    securityType = var.security_type
  }
}

resource "azapi_resource" "network_security_group" {
  type      = "Microsoft.Network/networkSecurityGroups@2023-09-01"
  name      = var.network_security_group_name
  location  = var.location
  parent_id = var.resource_group_id
  
  body = {
    properties = {
      securityRules = [
        {
          name = "SSH"
          properties = {
            priority                   = 1000
            protocol                   = "Tcp"
            access                     = "Allow"
            direction                  = "Inbound"
            sourceAddressPrefix        = "*"
            sourcePortRange            = "*"
            destinationAddressPrefix   = "*"
            destinationPortRange       = "22"
          }
        }
      ]
    }
  }
}

resource "azapi_resource" "virtual_network" {
  type      = "Microsoft.Network/virtualNetworks@2023-09-01"
  name      = var.virtual_network_name
  location  = var.location
  parent_id = var.resource_group_id
  
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.1.0.0/16"]
      }
      subnets = [
        {
          name = var.subnet_name
          properties = {
            networkSecurityGroup = {
              id = azapi_resource.network_security_group.id
            }
            addressPrefix                     = "10.1.0.0/24"
            privateEndpointNetworkPolicies    = "Enabled"
            privateLinkServiceNetworkPolicies = "Enabled"
          }
        }
      ]
    }
  }
}

resource "azapi_resource" "public_ip_address" {
  type      = "Microsoft.Network/publicIPAddresses@2023-09-01"
  name      = "${var.vm_name}PublicIP"
  location  = var.location
  parent_id = var.resource_group_id
  
  body = {
    sku = {
      name = "Basic"
    }
    properties = {
      publicIPAllocationMethod = "Dynamic"
      publicIPAddressVersion   = "IPv4"
      dnsSettings = {
        domainNameLabel = local.dns_label_prefix
      }
      idleTimeoutInMinutes = 4
    }
  }
  
  response_export_values = ["properties.dnsSettings.fqdn"]
}

resource "azapi_resource" "network_interface" {
  type      = "Microsoft.Network/networkInterfaces@2023-09-01"
  name      = "${var.vm_name}NetInt"
  location  = var.location
  parent_id = var.resource_group_id
  
  body = {
    properties = {
      ipConfigurations = [
        {
          name = "ipconfig1"
          properties = {
            subnet = {
              id = "${azapi_resource.virtual_network.id}/subnets/${var.subnet_name}"
            }
            privateIPAllocationMethod = "Dynamic"
            publicIPAddress = {
              id = azapi_resource.public_ip_address.id
            }
          }
        }
      ]
      networkSecurityGroup = {
        id = azapi_resource.network_security_group.id
      }
    }
  }
}

resource "azapi_resource" "vm" {
  type      = "Microsoft.Compute/virtualMachines@2023-09-01"
  name      = var.vm_name
  location  = var.location
  parent_id = var.resource_group_id
  
  body = {
    properties = {
      hardwareProfile = {
        vmSize = var.vm_size
      }
      storageProfile = {
        osDisk = {
          createOption = "FromImage"
          managedDisk = {
            storageAccountType = "Standard_LRS"
          }
        }
        imageReference = local.image_reference[var.ubuntu_os_version]
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.network_interface.id
          }
        ]
      }
      osProfile = {
        computerName   = var.vm_name
        adminUsername  = var.admin_username
        adminPassword  = var.admin_password_or_key
        linuxConfiguration = var.authentication_type == "password" ? null : local.linux_configuration
      }
      securityProfile = var.security_type == "TrustedLaunch" ? local.security_profile_json : null
    }
  }
}

resource "azapi_resource" "vm_extension" {
  count     = var.security_type == "TrustedLaunch" ? 1 : 0
  type      = "Microsoft.Compute/virtualMachines/extensions@2023-09-01"
  name      = "GuestAttestation"
  location  = var.location
  parent_id = azapi_resource.vm.id
  
  body = {
    properties = {
      publisher               = "Microsoft.Azure.Security.LinuxAttestation"
      type                    = "GuestAttestation"
      typeHandlerVersion      = "1.0"
      autoUpgradeMinorVersion = true
      enableAutomaticUpgrade  = true
      settings = {
        AttestationConfig = {
          MaaSettings = {
            maaEndpoint   = ""
            maaTenantName = "GuestAttestation"
          }
        }
      }
    }
  }
}
