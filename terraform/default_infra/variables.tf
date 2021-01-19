variable "az_sp_id" {
  type = string
  description = "Application ID of Azure Service Principal"
}

variable "az_sp_password" {
  type        = string
  description = "Application password of Azure Service Principal"
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
