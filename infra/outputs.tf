output "public_ip_address" {
  description = "IP publique de la VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "ssh_command" {
  description = "Commande pour se connecter en SSH"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

output "app_url" {
  description = "URL de l'application une fois déployée"
  value       = "http://${azurerm_public_ip.pip.ip_address}"
}
