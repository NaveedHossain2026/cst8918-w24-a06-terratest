output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "The name of the generated Azure Resource Group."
}

output "public_ip_address" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "The public IP address assigned to the web server VM."
}