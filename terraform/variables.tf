variable "az_sub" {
  type        = string
  description = "Name or ID of Azure Subscription"
}

variable "az_sp_id" {
  type = string
  description = "Application ID of Azure Service Principal"
}

variable "az_sp_password" {
  type        = string
  description = "Application password of Azure Service Principal"
}

variable "az_tenant_id" {
  type        = string
  description = "ID of the Azure tenant"
}

variable "resource_group" {
  type        = string
  description = "Name to give Resource Group"
}

variable "location" {
  type        = string
  description = "Azure location to deploy resources into"
}

variable "aks_name" {
  type        = string
  description = "Name to give the Kubernetes cluster"
}

variable "vm_size" {
  type        = string
  description = "Virtual Machine type to deploy"
}

variable "node_count" {
  type        = number
  description = "Number of nodes to deploy"
}

variable "binderhub_name" {
  type        = string
  description = "Name of your BinderHub"
}

variable "enable_acr" {
  type        = bool
  description = "Deploy an Azure Container Registry"
  default     = false
}

variable "registry_name" {
  type        = string
  description = "Name to assign to the Azure Container Registry"
  default     = null
}

variable "registry_sku" {
  type        = string
  description = "SKU tier to deploy the Azure Container Registry with. Options are: Basic, Standard or Premium."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.registry_sku)
    error_message = "Argument \"registry_sku\" must be either \"Basic\", \"Standard\", or \"Premium\"."
  }
}
