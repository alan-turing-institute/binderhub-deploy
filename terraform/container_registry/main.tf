# Create a random string of length 4 to append to the ACR name
# This is required global uniqueness
resource "random_string" "random_chars" {
  length = 4
  special = false
  upper = false
}

# output "random_chars" {
#   value = random_string.random_chars.result
# }

# Create an Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${var.registry_name}${random_string.random_chars.result}"
  resource_group_name = var.resource_group
  location            = var.location
  sku                 = var.registry_sku
}

# Assign the AcrPush role to the Service Principal
resource "azurerm_role_assignment" "acrpush" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.az_sp_id
}
