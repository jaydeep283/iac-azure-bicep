param location string
param privateSubnetId string
param publicSubnetId string
param publicSubnetName string
param publicSubnetPrefix string
param publicIpAddress string
param privateSubnetName string
param privateSubnetPrefix string
// param privateIpAddress string
param acrLoginServer string
param keyVaultUri string

resource publicSubnetNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-${publicSubnetName}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAppGwInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: publicIpAddress
          destinationAddressPrefix: publicSubnetPrefix
        }
      }
      {
        name: 'AllowInternetHTTPS'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: publicSubnetPrefix
        }
      }
      {
        name: 'AllowInternetHTTP'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: publicSubnetPrefix
        }
      }
      {
        name: 'AllowAzureLoadBalancerHealthChecks'
        properties: {
          priority: 130
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: publicSubnetPrefix
        }
      }
      {
        name: 'DenyAllInboundOther'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: publicSubnetPrefix
        }
      }
      {
        name: 'AllowOutboundInternet'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: 'Internet'
          sourceAddressPrefix: publicSubnetPrefix
        }
      }
      {
        name: 'DenyAllOutboundOther'
        properties: {
          priority: 4000
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          sourceAddressPrefix: publicSubnetPrefix
        }
      }
    ]
  }
}

resource privateSubnetNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-${privateSubnetName}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAKSInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: privateSubnetPrefix
        }
      }
      {
        name: 'AllowOutboundToAzureServices'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443,5432'
          destinationAddressPrefix: '*'
          sourceAddressPrefix: privateSubnetPrefix
        }
      }
      {
        name: 'AllowOutboundToACR'
        properties: {
          priority: 120
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: acrLoginServer
          sourceAddressPrefix: privateSubnetPrefix
        }
      }
      {
        name: 'AllowOutboundToKeyVault'
        properties: {
          priority: 130
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: keyVaultUri
          sourceAddressPrefix: privateSubnetPrefix
        }
      }
      {
        name: 'AllowInternalAKS'
        properties: {
          priority: 140
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: privateSubnetPrefix
          sourceAddressPrefix: privateSubnetPrefix
        }
      }
      {
        name: 'DenyAllInboundOther'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: privateSubnetPrefix
        }
      }
      {
        name: 'DenyAllOutboundOther'
        properties: {
          priority: 4000
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          sourceAddressPrefix: privateSubnetPrefix
        }
      }
    ]
  }
}

resource publicSubnetNsgAssociation 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: '${split(publicSubnetId, '/')[8]}/${split(publicSubnetId, '/')[10]}'
}

resource publicAssociation 'Microsoft.Network/virtualNetworks/subnets/networkSecurityGroup@2023-04-01' = {
  parent: publicSubnetNsgAssociation
  name: 'default'
  properties: {
    id: publicSubnetNsg.id
  }
}

resource privateSubnetNsgAssociation 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: '${split(privateSubnetId, '/')[8]}/${split(privateSubnetId, '/')[10]}'
}

resource privateAssociation 'Microsoft.Network/virtualNetworks/subnets/networkSecurityGroup@2023-04-01' = {
  parent: privateSubnetNsgAssociation
  name: 'default'
  properties: {
    id: privateSubnetNsg.id
  }
}
