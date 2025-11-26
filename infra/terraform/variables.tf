variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "tdc25-demo-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "tdc25demoregistry"
}

variable "log_analytics_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
  default     = "tdc25demo-law"
}

variable "aca_env_name" {
  description = "Name of the Container Apps Environment"
  type        = string
  default     = "tdc25demo-env"
}

variable "api_node_name" {
  description = "Name of the API Node Container App"
  type        = string
  default     = "tdc25-api-node"
}

variable "api_node_image" {
  description = "Image for API Node Container App"
  type        = string
  default     = "tdc25demoregistry.azurecr.io/api-node:latest"
}

variable "worker_python_name" {
  description = "Name of the Worker Python Container App"
  type        = string
  default     = "tdc25-worker-python"
}

variable "worker_python_image" {
  description = "Image for Worker Python Container App"
  type        = string
  default     = "tdc25demoregistry.azurecr.io/worker-python:latest"
}

variable "repo_url" {
  description = "Repository URL to link for ACA (e.g., https://github.com/<org>/<repo>)"
  type        = string
}

variable "github_branch" {
  description = "Branch to deploy from (e.g., main)"
  type        = string
  default     = "main"
}

variable "acr_server" {
  description = "ACR login server"
  type        = string
  default     = "tdc25demoregistry.azurecr.io"
}

variable "subscription_id" {
  description = "Azure Subscription ID (required if not logged in via Azure CLI)"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID (required if not logged in via Azure CLI)"
  type        = string
}
