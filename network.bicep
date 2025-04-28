param location string = resourceGroup().location
param vnetName string
param vnetAddressPrefixes array = ['10.0.0.0/16']
param publicSubnetName string
param publicSubnetPrefix string
param privateSubnetName string
param privateSubnetPrefix string
param postgresSubnetName string = 'postgres-subnet'
param postgresSubnetPrefix string = '10.0.3.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [
      {
        name: publicSubnetName
        properties: {
          addressPrefix: publicSubnetPrefix
        }
      }
      {
        name: privateSubnetName
        properties: {
          addressPrefix: privateSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: postgresSubnetName
        properties: {
          addressPrefix: postgresSubnetPrefix
          delegations: [
            {
              name: 'postgres-delegation'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// Output subnet IDs
output vnetId string = vnet.id
output publicSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, publicSubnetName)
output privateSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateSubnetName)
output postgresSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, postgresSubnetName)
