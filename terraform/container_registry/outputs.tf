output "acr_id" {
  value      = azurerm_container_registry.acr.id
  depends_on = [ azurerm_container_registry.acr ]
}

output "acr_login_server" {
  value      = azurerm_container_registry.acr.login_server
  depends_on = [ azurerm_container_registry.acr ]
}
