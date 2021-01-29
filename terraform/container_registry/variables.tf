variable "resource_group" {
  type        = string
  description = "Name to give Resource Group"
}

variable "location" {
  type        = string
  description = "Azure location to deploy resources into"
}

variable "az_sp_id" {
  type        = string
  description = "Application ID of a Service Principal"
}

variable "registry_name" {
  type = string
  description = "Name to assign to the Azure Container Registry"
}

variable "registry_sku" {
  type = string
  description = "SKU tier to deploy the Azure Container Registry with. Options are: Basic, Standard or Premium."

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.registry_sku)
    error_message = "Argument \"registry_sku\" must be either \"Basic\", \"Standard\", or \"Premium\"."
  }
}
