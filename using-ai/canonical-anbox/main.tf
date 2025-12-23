terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azapi" {
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

locals {
  anbox_mgmt_ports      = var.expose_anbox_management_service ? ["8444"] : []
  anbox_base_ports      = ["80", "443", "5349", "60000-60100"]
  anbox_container_ports = var.expose_anbox_container_services ? ["10000-11000"] : []
  
  anbox_destination_port_ranges = concat(local.anbox_mgmt_ports, local.anbox_base_ports, local.anbox_container_ports)

  cloud_config_with_token = <<EOF
#cloud-config

package_upgrade: true

ubuntu_advantage:
  token: ${var.ubuntu_pro_token}
  enable:
    - anbox-cloud
EOF

  cloud_config_without_token = <<EOF
#cloud-config

package_upgrade: true

ubuntu_advantage:
  enable:
    - anbox-cloud
EOF

  cloud_config = base64encode(var.ubuntu_pro_token != "" ? local.cloud_config_with_token : local.cloud_config_without_token)

  data_disks = var.add_dedicated_data_disk_for_lxd ? [
    {
      createOption = "Empty"
      diskSizeGB   = var.virtual_machine_data_disk_size_in_gb
      lun          = 0
      managedDisk = {
        storageAccountType = "Premium_LRS"
      }
    }
  ] : []

  image_plan = var.ubuntu_pro_token == "" ? {
    name      = var.ubuntu_image_sku
    product   = var.ubuntu_image_offer
    publisher = "canonical"
  } : null

  linux_configuration = {
    disablePasswordAuthentication = true
    ssh = {
      publicKeys = [
        {
          path    = "/home/${var.administrator_username}/.ssh/authorized_keys"
          keyData = var.administrator_public_ssh_key
        }
      ]
    }
  }

  network_interface_name = "${var.virtual_machine_name}NetworkInterface"
  public_ip_address_name = "${var.virtual_machine_name}PublicIP"
}

resource "azapi_resource" "virtual_network" {
  type      = "Microsoft.Network/virtualNetworks@2023-09-01"
  parent_id = data.azurerm_resource_group.rg.id
  name      = var.virtual_network_name
  location  = var.location

  body = {
    properties = {
      addressSpace = {
        addressPrefixes = [var.virtual_network_address_prefix]
      }
      subnets = [
        {
          name = var.subnet_name
          properties = {
            addressPrefix = var.subnet_address_prefix
          }
        }
      ]
    }
  }
}

resource "azapi_resource" "network_security_group" {
  type      = "Microsoft.Network/networkSecurityGroups@2023-09-01"
  parent_id = data.azurerm_resource_group.rg.id
  name      = var.network_security_group_name
  location  = var.location

  body = {
    properties = {
      securityRules = [
        {
          name = "SSH"
          properties = {
            priority                 = 1000
            protocol                 = "Tcp"
            access                   = "Allow"
            direction                = "Inbound"
            sourceAddressPrefix      = "*"
            sourcePortRange          = "*"
            destinationAddressPrefix = "*"
            destinationPortRange     = "22"
          }
        },
        {
          name = "Anbox"
          properties = {
            priority                 = 1010
            protocol                 = "*"
            access                   = "Allow"
            direction                = "Inbound"
            sourceAddressPrefix      = "*"
            sourcePortRange          = "*"
            destinationAddressPrefix = "*"
            destinationPortRanges    = local.anbox_destination_port_ranges
          }
        }
      ]
    }
  }
}

resource "azapi_resource" "public_ip_address" {
  type      = "Microsoft.Network/publicIPAddresses@2023-09-01"
  parent_id = data.azurerm_resource_group.rg.id
  name      = local.public_ip_address_name
  location  = var.location

  body = {
    properties = {
      publicIPAllocationMethod = "Static"
      publicIPAddressVersion   = "IPv4"
    }
  }
  
  response_export_values = ["properties.ipAddress"]
}

resource "azapi_resource" "network_interface" {
  type      = "Microsoft.Network/networkInterfaces@2023-09-01"
  parent_id = data.azurerm_resource_group.rg.id
  name      = local.network_interface_name
  location  = var.location

  body = {
    properties = {
      ipConfigurations = [
        {
          name = "${local.network_interface_name}IPConfiguration"
          properties = {
            subnet = {
              id = azapi_resource.virtual_network.id != null ? "${azapi_resource.virtual_network.id}/subnets/${var.subnet_name}" : null
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

resource "azapi_resource" "virtual_machine" {
  type      = "Microsoft.Compute/virtualMachines@2023-09-01"
  parent_id = data.azurerm_resource_group.rg.id
  name      = var.virtual_machine_name
  location  = var.location

  body = merge(
    {
      properties = {
        hardwareProfile = {
          vmSize = var.virtual_machine_size
        }
        storageProfile = {
          osDisk = {
            createOption = "FromImage"
            diskSizeGB   = var.virtual_machine_operating_system_disk_size_in_gb
            managedDisk = {
              storageAccountType = "Standard_LRS"
            }
          }
          imageReference = {
            publisher = "Canonical"
            offer     = var.ubuntu_image_offer
            sku       = var.ubuntu_image_sku
            version   = "latest"
          }
          dataDisks = local.data_disks
        }
        networkProfile = {
          networkInterfaces = [
            {
              id = azapi_resource.network_interface.id
            }
          ]
        }
        osProfile = {
          computerName       = var.virtual_machine_name
          adminUsername      = var.administrator_username
          adminPassword      = var.administrator_public_ssh_key
          linuxConfiguration = local.linux_configuration
          customData         = local.cloud_config
        }
      }
    },
    local.image_plan != null ? { plan = local.image_plan } : {}
  )
}
