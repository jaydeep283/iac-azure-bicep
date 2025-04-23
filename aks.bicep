param aksClusterName string
param location string
param privateSubnetId string
param appGatewayId string

// Reference existing App Gateway resource
resource appGateway 'Microsoft.Network/applicationGateways@2023-04-01' existing = {
  scope: resourceGroup()
  name: last(split(appGatewayId, '/'))
}

// AKS Cluster
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.30.2'
    dnsPrefix: aksClusterName
    agentPoolProfiles: [
      {
        name: 'defaultpool'
        osDiskSizeGB: 128
        count: 3
        vmSize: 'Standard_DS2_v2'
        vnetSubnetID: privateSubnetId
        osType: 'Linux'
        mode: 'System'
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'Standard'
    }
    addonProfiles: {
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: appGatewayId
        }
      }
    }
  }
}

// Role assignment for AGIC
resource agicRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(aksCluster.name, 'agic-contributor-role')
  scope: appGateway
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: aksCluster.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output aksPrincipalId string = aksCluster.identity.principalId
