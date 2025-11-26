param location string = resourceGroup().location
param acrName string
param logAnalyticsName string
param envName string
param apiName string = 'api-node'
param workerName string = 'worker-python'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource env 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
  }
}

resource api 'Microsoft.App/containerApps@2023-05-01' = {
  name: apiName
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
      }
      registries: [
        {
          server: '${acr.name}.azurecr.io'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'api-node'
          image: '${acr.name}.azurecr.io/api-node:latest'
          resources: {
            cpu: 0.5
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-requests'
            custom: {
              type: 'http'
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

resource worker 'Microsoft.App/containerApps@2023-05-01' = {
  name: workerName
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
      }
      registries: [
        {
          server: '${acr.name}.azurecr.io'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'worker-python'
          image: '${acr.name}.azurecr.io/worker-python:latest'
          resources: {
            cpu: 0.5
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-requests'
            custom: {
              type: 'http'
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

output acrLoginServer string = '${acr.name}.azurecr.io'
output environmentId string = env.id
output apiAppName string = api.name
output workerAppName string = worker.name