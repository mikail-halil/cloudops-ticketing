# Versions de Terraform et du provider Azure.
# En azurerm v4.x, `subscription_id` et le bloc `features {}` sont OBLIGATOIRES
# (sinon `terraform plan` échoue — erreur classique des anciens tutos v3).
terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
