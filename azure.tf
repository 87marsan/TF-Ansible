provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "myResourceGroup" {
  name     = "myResourceGroup"
  location = "northeurope" # Ändra till önskad Azure-region
}

# Skapa en nätverkssäkerhetsgrupp för appserver
resource "azurerm_network_security_group" "appServerNSG" {
  name                = "appServerNSG"
  location            = azurerm_resource_group.myResourceGroup.location
  resource_group_name = azurerm_resource_group.myResourceGroup.name
}

# Skapa en nätverkssäkerhetsgrupp för webbserver
resource "azurerm_network_security_group" "webbServerNSG" {
  name                = "webbServerNSG"
  location            = azurerm_resource_group.myResourceGroup.location
  resource_group_name = azurerm_resource_group.myResourceGroup.name
}

# Skapa en offentlig IP-adress för appserver
resource "azurerm_public_ip" "appServerPublicIP" {
  name                = "appServerPublicIP"
  location            = azurerm_resource_group.myResourceGroup.location
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Skapa en offentlig IP-adress för webbserver
resource "azurerm_public_ip" "webbServerPublicIP" {
  name                = "webbServerPublicIP"
  location            = azurerm_resource_group.myResourceGroup.location
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Skapa en virtuell nätverk
resource "azurerm_virtual_network" "myVMVNET" {
  name                = "myVMVNET"
  location            = azurerm_resource_group.myResourceGroup.location
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  address_space       = ["10.0.0.0/16"]
}

# Skapa en subnet för VMs
resource "azurerm_subnet" "myVMSubnet" {
  name                 = "myVMSubnet"
  resource_group_name  = azurerm_resource_group.myResourceGroup.name
  virtual_network_name = azurerm_virtual_network.myVMVNET.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Skapa en nätverksgränssnitt för appserver
resource "azurerm_network_interface" "appServerVMNic" {
  name                = "appServerVMNic"
  location            = azurerm_resource_group.myResourceGroup.location
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  enable_accelerated_networking = false
  enable_ip_forwarding = false
  
  ip_configuration {
    name                          = "ipconfigAppServer"
    subnet_id                     = azurerm_subnet.myVMSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.appServerPublicIP.id
  }

  depends_on = [
    azurerm_public_ip.appServerPublicIP,
  ]
}

# Skapa en nätverksgränssnitt för webbserver
resource "azurerm_network_interface" "webbServerVMNic" {
  name                = "webbServerVMNic"
  location            = azurerm_resource_group.myResourceGroup.location
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  enable_accelerated_networking = false
  enable_ip_forwarding = false
  
  ip_configuration {
    name                          = "ipconfigWebbServer"
    subnet_id                     = azurerm_subnet.myVMSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.webbServerPublicIP.id
  }

  depends_on = [
    azurerm_public_ip.webbServerPublicIP,
  ]
}

# Associera nätverksgränssnitt för appserver med nätverkssäkerhetsgrupp
resource "azurerm_network_interface_security_group_association" "appServerNSGAssoc" {
  network_interface_id      = azurerm_network_interface.appServerVMNic.id
  network_security_group_id = azurerm_network_security_group.appServerNSG.id
}

# Associera nätverksgränssnitt för webbserver med nätverkssäkerhetsgrupp
resource "azurerm_network_interface_security_group_association" "webbServerNSGAssoc" {
  network_interface_id      = azurerm_network_interface.webbServerVMNic.id
  network_security_group_id = azurerm_network_security_group.webbServerNSG.id
}

# Skapa virtuella maskiner för appserver och webbserver (komplettera med inställningar för VM som storlek, OS, etc.)
resource "azurerm_virtual_machine" "appServerVM" {
  name                  = "appServerVM"
  location              = azurerm_resource_group.myResourceGroup.location
  resource_group_name   = azurerm_resource_group.myResourceGroup.name
  network_interface_ids = [azurerm_network_interface.appServerVMNic.id]
  
  vm_size = "Standard_DS1_v2" # Ange önskad VM-storlek

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "appServerVM_os_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 30
  }

  os_profile {
    computer_name  = "appServerVM"
    admin_username = "azureadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub") 
    }
  }
}

resource "azurerm_virtual_machine" "webbServerVM" {
  name                  = "webbServerVM"
  location              = azurerm_resource_group.myResourceGroup.location
  resource_group_name   = azurerm_resource_group.myResourceGroup.name
  network_interface_ids = [azurerm_network_interface.webbServerVMNic.id]
  
  vm_size = "Standard_DS1_v2" # Ange önskad VM-storlek

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "webbServerVM_os_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 30
  }

  os_profile {
    computer_name  = "webbServerVM"
    admin_username = "azureadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub") 
    }
  }
}

# Skapa nätverksregler för appservern
resource "azurerm_network_security_rule" "appServerNSGRule22" {
  name                        = "AllowAppServerInbound22"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myResourceGroup.name
  network_security_group_name = azurerm_network_security_group.appServerNSG.name
}

resource "azurerm_network_security_rule" "appServerNSGRule5000" {
  name                        = "AllowAppServerInbound5000"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myResourceGroup.name
  network_security_group_name = azurerm_network_security_group.appServerNSG.name
}

# Skapa nätverksregler för webbservern
resource "azurerm_network_security_rule" "webbServerNSGRule22" {
  name                        = "AllowWebbServerInbound22"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myResourceGroup.name
  network_security_group_name = azurerm_network_security_group.webbServerNSG.name
}

resource "azurerm_network_security_rule" "webbServerNSGRule80" {
  name                        = "AllowWebbServerInbound80"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myResourceGroup.name
  network_security_group_name = azurerm_network_security_group.webbServerNSG.name
}

resource "azurerm_network_security_rule" "webbServerNSGRule5000" {
  name                        = "AllowWebbServerInbound5000"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myResourceGroup.name
  network_security_group_name = azurerm_network_security_group.webbServerNSG.name
}

output "appServerIP" {
  value = azurerm_public_ip.appServerPublicIP.ip_address
}

output "webbServerIP" {
  value = azurerm_public_ip.webbServerPublicIP.ip_address
}
