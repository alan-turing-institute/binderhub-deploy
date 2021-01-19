# Kubernetes cluster
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_name

    addon_profile {
      azure_policy {
        enabled = true
      }

      kube_dashboard {
        enabled = true
      }
    }

  default_node_pool {
    name           = "default"
    vm_size        = var.vm_size
    vnet_subnet_id = azurerm_subnet.subnet.id
    node_count     = var.node_count
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.0.0.0/16"
  }

  role_based_access_control {
    enabled = true
  }

  service_principal {
    client_id     = var.az_sp_id
    client_secret = var.az_sp_password
  }
}
