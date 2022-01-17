terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.66.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
     docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }

  required_version = ">= 0.14"
}