terraform {
  required_version = ">= 0.13"


  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.81.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {

  }
}

resource "azurerm_resource_group" "example" {
  name     = "MysqlVM"
  location = "eastus"
}

resource "azurerm_virtual_network" "Atividade2" {
  name                = "MyVirtualNetwork"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
    faculdade = "impacta"
    turma = "es22"
  }
}

resource "azurerm_subnet" "subnetVN" {
  name                 = "My-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.Atividade2.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_public_ip" "PublicIP" {
  name                = "MyPublicIP"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_security_group" "MyFirewall" {
  name                = "FirewallVirtualNetwork"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "InterfaceNetworkPrincipal" {
  name                = "InterfaceVirtualNetwork"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "InterfaceConfiguration"
    subnet_id                     = azurerm_subnet.subnetVN.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.PublicIP.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.InterfaceNetworkPrincipal.id
  network_security_group_id = azurerm_network_security_group.MyFirewall.id
}

resource "azurerm_virtual_machine" "MyVirtualMachine" {
  name                  = "VirtualMachine-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.InterfaceNetworkPrincipal.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

data "azurerm_public_ip" "IP-Database" {
  name                = azurerm_public_ip.PublicIP.name
  resource_group_name = azurerm_resource_group.example.name
}

resource "time_sleep" "wait_30_seconds_db" {
  depends_on = [azurerm_virtual_machine.MyVirtualMachine]
  create_duration = "30s"
}