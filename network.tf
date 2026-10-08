# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-td-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Application subnet
resource "azurerm_subnet" "client_subnet" {
  name                 = "snet-client-tier"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Database / Private Endpoint subnet
resource "azurerm_subnet" "db_subnet" {
  name                 = "snet-db-tier"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]

  private_endpoint_network_policies = "Disabled"
}