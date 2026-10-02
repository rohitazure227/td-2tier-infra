# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-td-${var.environment}"
  location = var.location
}