terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.37.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 1.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0.1"
    }
  }
}

provider "azurerm" {
  subscription_id = var.az_sub
  client_id       = var.az_sp_id
  client_secret   = var.az_sp_password
  tenant_id       = var.az_tenant_id

  features {}
}

provider "azuread" {}

provider "random" {}
