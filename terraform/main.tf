# Import modules
module "default_infra" {
  source         = "./default_infra"
  az_sp_id       = var.az_sp_id
  az_sp_password = var.az_sp_password
  resource_group = var.resource_group
  location       = var.location
  aks_name       = var.aks_name
  vm_size        = var.vm_size
  node_count     = var.node_count
  binderhub_name = var.binderhub_name
}

# Subscription
data "azurerm_subscription" "current" {
    subscription_id = var.az_sub
}
