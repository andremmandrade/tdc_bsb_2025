# Demo Overview: AI + CI/CD + Azure Container Apps

- AI assists coding, testing, and documentation.
- CI/CD automates build, push, and deploy.
- Azure Container Apps uses KEDA for event-driven scaling.

## Flow
1. Write code and tests (with AI help).
2. Push changes → pipeline runs.
3. Images built and pushed to ACR.
4. Deploy to Container Apps with scale rules.

## Secrets/Variables
- `AZURE_CREDENTIALS`: Azure federated credentials JSON for GitHub.
- `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `RESOURCE_GROUP`, `CONTAINERAPPS_ENV`.

## Provisioning
- Use `infra/bicep/main.bicep` to provision ACR, Log Analytics, Env, and apps.
- Or adopt Azure Developer CLI (`azd`) templates.

## Scaling
- HTTP concurrency rules are included for demo; replace with custom KEDA triggers for queues/events if needed.
