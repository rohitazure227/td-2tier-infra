# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-td-${var.environment}"
  location = var.location
}

# 2. Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-td-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3. Subnet for Tier 1: Client / Application Servers
resource "azurerm_subnet" "client_subnet" {
  name                 = "snet-client-tier"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 4. Subnet for Tier 2: Secure Database Backend
resource "azurerm_subnet" "db_subnet" {
  name                 = "snet-db-tier"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  private_endpoint_network_policies = "Disabled" # Disable to allow Private Endpoint connections to SQL Server
}

# 5. Application Security Group (ASG) to tag Client interfaces
resource "azurerm_application_security_group" "client_asg" {
  name                = "asg-client-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 6. Dynamic Loop: Network Interfaces (NICs) for the Client tier
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

# 7. Dynamic Loop: Bind every single generated NIC interface card to the secure ASG Tag
resource "azurerm_network_interface_application_security_group_association" "nic_asg_assoc" {
  count                         = var.vm_count
  network_interface_id          = azurerm_network_interface.app_nic[count.index].id
  application_security_group_id = azurerm_application_security_group.client_asg.id
}

# 8. Azure SQL Logical Server 
resource "azurerm_mssql_server" "sql_server" {
  name                = "sql-td-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  version             = "12.0"

  minimum_tls_version = "1.2"

  azuread_administrator {
    login_username              = var.sql_admin_login
    object_id                   = var.sql_admin_object_id
    azuread_authentication_only = true
  }
}

# 9. Azure SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name        = "db-td-${var.environment}"
  server_id   = azurerm_mssql_server.sql_server.id
  sku_name    = "S0"
  max_size_gb = 10
}

# 10. Azure SQL Private Endpoint
resource "azurerm_private_endpoint" "sql_pe" {
  name                = "pe-sql-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.db_subnet.id

  private_service_connection {
    name                           = "psc-sql-${var.environment}"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
  private_dns_zone_group {
    name                 = "pdns-sql-${var.environment}"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
  }
}

# 11. Azure SQL Private DNS Zone for the Private Endpoint
resource "azurerm_private_dns_zone" "sql_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# 12. Link the Private DNS Zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "link-sql-dns-${var.environment}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
# 13. Dynamic Loop: Provision the Ubuntu Linux Virtual Machines
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

  # Configures an automated basic password bypass for training validation labs
  disable_password_authentication = true

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
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


