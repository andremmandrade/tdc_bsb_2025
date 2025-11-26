Param(
  [Parameter(Mandatory=$true)] [string]$SubscriptionId,
  [Parameter(Mandatory=$true)] [string]$ResourceGroup,
  [Parameter(Mandatory=$true)] [string]$EnvironmentName,
  [Parameter(Mandatory=$true)] [string]$RepoUrl,
  [Parameter(Mandatory=$true)] [string]$Branch,
  [Parameter(Mandatory=$true)] [string]$AcrServer,
  [Parameter(Mandatory=$false)] [string]$GitHubToken
)

az account set --subscription $SubscriptionId

Write-Host "Configuring GitHub Actions for api-node..."
if ($GitHubToken) {
  az containerapp github-action add `
    --name api-node `
    --resource-group $ResourceGroup `
    --repo-url $RepoUrl `
    --branch $Branch `
    --registry-url $AcrServer `
    --token $GitHubToken
} else {
  az containerapp github-action add `
    --name api-node `
    --resource-group $ResourceGroup `
    --repo-url $RepoUrl `
    --branch $Branch `
    --registry-url $AcrServer `
    --login-with-github
}

Write-Host "Configuring GitHub Actions for worker-python..."
if ($GitHubToken) {
  az containerapp github-action add `
    --name worker-python `
    --resource-group $ResourceGroup `
    --repo-url $RepoUrl `
    --branch $Branch `
    --registry-url $AcrServer `
    --token $GitHubToken
} else {
  az containerapp github-action add `
    --name worker-python `
    --resource-group $ResourceGroup `
    --repo-url $RepoUrl `
    --branch $Branch `
    --registry-url $AcrServer `
    --login-with-github
}
