# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.binderhub_name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/8"]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.binderhub_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.240.0.0/16"]
}
