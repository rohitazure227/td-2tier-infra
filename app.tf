# Application Security Group
resource "azurerm_application_security_group" "client_asg" {
  name                = "asg-client-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Network Interfaces
resource "azurerm_network_interface" "app_nic" {
  count               = var.vm_count
  name                = "nic-app-${var.environment}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal-ip-config"
    subnet_id                     = azurerm_subnet.client_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# NIC → ASG association
resource "azurerm_network_interface_application_security_group_association" "nic_asg_assoc" {
  count                         = var.vm_count
  network_interface_id          = azurerm_network_interface.app_nic[count.index].id
  application_security_group_id = azurerm_application_security_group.client_asg.id
}

# Application Virtual Machines
resource "azurerm_linux_virtual_machine" "app_vm" {
  count               = var.vm_count
  name                = "vm-app-${var.environment}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.app_nic[count.index].id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}