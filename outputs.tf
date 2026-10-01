output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "The actual name of the resource group created."
}

output "virtual_network_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The structural layout name of the virtual network."
}

output "client_private_ips" {
  value       = azurerm_network_interface.app_nic[*].private_ip_address
  description = "A dynamic array listing all private IP addresses assigned to your client VMs."
}
