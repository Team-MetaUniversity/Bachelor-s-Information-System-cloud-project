provider "azurerm" {
  features {}
}

terraform {
required_version = ">=0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    azuread = {
      version = ">= 2.26.0" // https://github.com/terraform-providers/terraform-provider-azuread/releases
    }
     kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }
     kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
      azapi = {
      source  = "azure/azapi"
      version = "~> 1.12.0"
    }
  }
}
provider "kubernetes" {
  config_path         = "~/.kube/config"
  config_context      = "cluster-exciting-catfish"
}
provider "helm" {
  debug = true
  kubernetes {
   config_path         = "~/.kube/config"
   config_context      = "cluster-exciting-catfish"
  }
}
provider "kubectl" {
  config_path         = "~/.kube/config"
  config_context      = "cluster-exciting-catfish"
}



