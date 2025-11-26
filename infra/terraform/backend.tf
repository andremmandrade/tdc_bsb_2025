terraform {
  backend "azurerm" {
    resource_group_name  = "tdc25-demo-rg"
    storage_account_name = "tdc25tfstatekcb4b7"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
