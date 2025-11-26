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

${null} = az containerapp github-action add `
  --name api-node `
  --resource-group $ResourceGroup `
  --repo-url $RepoUrl `
  --branch $Branch `
  --container-name api-node `
  --environment $EnvironmentName `
  --registry-url $AcrServer `
  --azure-subscription $SubscriptionId `
  $(if ($GitHubToken) {"--token $GitHubToken"} else {""})

${null} = az containerapp github-action add `
  --name worker-python `
  --resource-group $ResourceGroup `
  --repo-url $RepoUrl `
  --branch $Branch `
  --container-name worker-python `
  --environment $EnvironmentName `
  --registry-url $AcrServer `
  --azure-subscription $SubscriptionId `
  $(if ($GitHubToken) {"--token $GitHubToken"} else {""})
