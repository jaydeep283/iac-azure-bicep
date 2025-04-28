param location string = resourceGroup().location
param acrName string
param aksPrincipalId string 

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(aksPrincipalId, acr.id, 'acrpull')
  scope: acr
  properties: {
    principalId: aksPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer
