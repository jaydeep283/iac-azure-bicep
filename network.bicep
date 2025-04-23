param location string = resourceGroup().location
param vnetName string
param vnetAddressPrefixes array = ['10.0.0.0/16']
param publicSubnetName string
param publicSubnetPrefix string
param privateSubnetName string
param privateSubnetPrefix string

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
        }
      }
    ]
  }
}

// Output subnet IDs instead of resource references
output vnetId string = vnet.id
output publicSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, publicSubnetName)
output privateSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateSubnetName)
