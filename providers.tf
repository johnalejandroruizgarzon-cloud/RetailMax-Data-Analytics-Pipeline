# providers.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Usamos una versión estable de la rama 3.x
    }
  }
  
  # Nota: El backend remoto (Storage Account para el tfstate) 
  # se configurará aquí en un paso posterior para cumplir con la rúbrica.
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}