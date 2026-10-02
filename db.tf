# Azure SQL Logical Server
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

# Azure SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name        = "db-td-${var.environment}"
  server_id   = azurerm_mssql_server.sql_server.id
  sku_name    = "S0"
  max_size_gb = 10
}