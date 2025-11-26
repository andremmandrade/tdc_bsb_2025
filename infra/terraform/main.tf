// Backend storage account is pre-provisioned outside Terraform to comply with AAD-only policies.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    demo = "TDC 2025 BSB"
    owner = "Copilot Demo"
    purpose = "AI+CI/CD showcase"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
  tags = {
    demo = "TDC 2025 BSB"
    owner = "Copilot Demo"
  }
}

# Image build and push are handled by CI/CD pipelines (GitHub Actions / Azure DevOps).

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    demo = "TDC 2025 BSB"
    owner = "Copilot Demo"
  }
}

resource "azurerm_container_app_environment" "aca_env" {
  name                = var.aca_env_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  tags = {
    demo = "TDC 2025 BSB"
    owner = "Copilot Demo"
  }
}

resource "azurerm_container_app" "api_node" {
  name                         = var.api_node_name
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  # location removed (set automatically)
  tags = {
    demo = "TDC 2025 BSB"
    owner = "Copilot Demo"
    service = "Node API"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_pull.id]
  }
  revision_mode = "Single"
  template {
    container {
      name   = "api-node"
      image  = var.api_node_image
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "KEDA_CONCURRENT_REQUESTS"
        value = "50"
      }
    }
  }
  ingress {
    external_enabled = true
    target_port      = 3000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

resource "azurerm_container_app" "worker_python" {
  name                         = var.worker_python_name
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  # location removed (set automatically)
  tags = {
    demo = "TDC 2025 BSB"
    owner = "Copilot Demo"
    service = "Python Worker"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_pull.id]
  }
  revision_mode = "Single"
  template {
    container {
      name   = "worker-python"
      image  = var.worker_python_image
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "KEDA_CONCURRENT_REQUESTS"
        value = "50"
      }
    }
  }
  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# Note: GitHub Actions integration for ACA is configured via Azure CLI (az containerapp github-action add).
# Terraform azurerm currently does not support a container app source control resource.

# User-assigned identity for pulling images from ACR
resource "azurerm_user_assigned_identity" "acr_pull" {
  name                = "tdc25-acr-pull-mi"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags = {
    demo   = "TDC 2025 BSB"
    owner  = "Copilot Demo"
    purpose = "ACR pull identity"
  }
}

# Grant ACR pull permission to the user-assigned identity
resource "azurerm_role_assignment" "acr_pull_role" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_pull.principal_id
}

# Grant ACR pull permission to the Container Apps managed identities

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aca_env_id" {
  value = azurerm_container_app_environment.aca_env.id
}

output "api_node_app_name" {
  value = azurerm_container_app.api_node.name
}

output "worker_python_app_name" {
  value = azurerm_container_app.worker_python.name
}
