# AI + CI/CD Demo with Azure Container Apps

This demo shows how AI-assisted development pairs with CI/CD (GitHub Actions and Azure DevOps) to build and deploy microservices to Azure Container Apps (KEDA-based scaling).

## Quickstart

### Prerequisites
- Node.js 20+
- Python 3.11+
- Docker Desktop
- Azure CLI (`az`), Container Apps extension (`az extension add -n containerapp`)
- An Azure Container Registry (ACR) and a Container Apps Environment

### Run locally
```powershell
# From repo root
docker-compose build
docker-compose up
# API: http://localhost:3000/health
# Worker: http://localhost:8000/health
```

### GitHub Actions
- Set repository secrets: `AZURE_CREDENTIALS`, `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `RESOURCE_GROUP`, `CONTAINERAPPS_ENV`.
- Push to `main` to trigger build, push, and deploy.

### Azure DevOps
- Configure service connection (Azure Resource Manager).
- Set pipeline variables: `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `RESOURCE_GROUP`, `CONTAINERAPPS_ENV`.

## Structure
- `services/api-node`: Node.js REST API
- `services/worker-python`: Python FastAPI service
- `infra/bicep`: Azure infra (ACR, Log Analytics, Container Apps Env, apps)
- `.github/workflows/deploy.yml`: GitHub Actions pipeline
- `azure-pipelines.yml`: Azure DevOps pipeline
- `docker-compose.yml`: local dev orchestration
- `docs/`: concept docs

## Notes
- Replace placeholder values for ACR, resource group, environment, and image tags.
- Pipelines assume infra is provisioned; run Bicep or azd before first deploy.

## Azure Terraform Backend Prerequisites (AAD-only)

Before running any Terraform commands in `infra/terraform`, the remote state storage must exist and use Azure AD authentication (no shared keys). Create the storage account and container manually, then initialize Terraform.

### Manual Setup (WSL)

1) Register the Container Apps resource provider:

```bash
az provider register --namespace Microsoft.App --wait
```

2) Create the storage account (AAD-only, no shared keys):

```bash
az storage account create \
	--name tdc25tfstatekcb4b7 \
	--resource-group tdc25-demo-rg \
	--location eastus \
	--sku Standard_LRS \
	--encryption-services blob \
	--https-only true \
	--allow-blob-public-access false \
	--allow-shared-key-access false \
	--min-tls-version TLS1_2 \
	--tags demo="TDC 2025 BSB" purpose="Terraform State"
```

3) Create the `tfstate` container:

```bash
az storage container create \
	--name tfstate \
	--account-name tdc25tfstatekcb4b7 \
	--auth-mode login
```

4) Assign Storage Blob Data Contributor to your user:

```bash
az role assignment create \
	--assignee $(az ad signed-in-user show --query id -o tsv) \
	--role "Storage Blob Data Contributor" \
	--scope "/subscriptions/<YOUR_SUBSCRIPTION_ID>/resourceGroups/tdc25-demo-rg/providers/Microsoft.Storage/storageAccounts/tdc25tfstatekcb4b7"
```

5) Initialize Terraform backend and run plan/apply:

```bash
cd "/mnt/c/Users/andreandrade/OneDrive - Microsoft/demos/tdc_2025_bsb/infra/terraform"
export ARM_STORAGE_USE_AZUREAD=true
export ARM_USE_AZUREAD=true
terraform init -reconfigure
terraform validate
terraform plan -var "subscription_id=<YOUR_SUBSCRIPTION_ID>" -var "tenant_id=<YOUR_TENANT_ID>"
terraform apply -var "subscription_id=<YOUR_SUBSCRIPTION_ID>" -var "tenant_id=<YOUR_TENANT_ID>" -auto-approve
```

### Notes
- If the storage account or container is missing, Terraform may return 404s when saving state. Create them first.
- RBAC changes can take ~1–2 minutes to propagate. If you see 403s, wait and retry.
- Ensure Azure CLI in WSL is logged in and set to the correct subscription: `az login` and `az account set --subscription <YOUR_SUBSCRIPTION_ID>`.

## Lessons Learned

- Azure AD-only storage accounts require explicit AAD auth for Terraform backend. Setting `ARM_STORAGE_USE_AZUREAD=true` (and `ARM_USE_AZUREAD=true`) prevents fallback to shared keys, avoiding 403 errors.
- The AzureRM provider may probe storage capabilities (e.g., queues). While shared keys are disabled, AAD roles like `Storage Blob Data Contributor` are sufficient for blob operations; queue roles may be needed in some environments.
- Always pre-create the backend storage account and container when enterprise policies disable key-based authentication.
- Register required resource providers (e.g., `Microsoft.App`) before provisioning Container Apps to avoid `MissingSubscriptionRegistration` 409 errors.
- Use `terraform init -reconfigure` after backend changes to refresh auth and provider versions.
