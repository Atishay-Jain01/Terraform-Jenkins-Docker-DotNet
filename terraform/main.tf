# az role assignment create --assignee 4cff40a6-c2fd-4f73-9c89-bc0ce1b04bff --role "User Access Administrator" --scope /subscriptions/5187ad8c-dab9-4f44-8672-7b7009fec855

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
  required_version = ">=1.0.0"
}

provider "azurerm" {
  subscription_id = "de917971-3ca5-454f-9a61-16d7bab4eff2"
  tenant_id       = "7c2c734c-c7d5-4011-aa42-2e92378d364c"
  features {}
}

# Variables
variable "location" {
  default = "eastus2"
}

variable "resource_group_name" {
  default = "rg-aks-assignment"
}

variable "acr_name" {
  default = "acr150425assignment" 
}

variable "aks_cluster_name" {
  default = "aks150425assignment"
}

variable "dns_prefix" {
  default = "myakscluster"
}

variable "node_count" {
  default = 2
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    Environment = "Development"
  }
}

# Role assignment to allow AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id

 
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
