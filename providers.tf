terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Employs the stable 3.x series of the AzureRM features
    }
  }
}

provider "azurerm" {
  features {} # This block is mandatory for the Azure provider to function properly, even if left empty. It enables all default features.
}