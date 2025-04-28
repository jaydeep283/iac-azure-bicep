param location string
param privateSubnetId string
param publicSubnetId string
param postgresSubnetId string
param publicSubnetName string
param publicSubnetPrefix string
param privateSubnetName string
param privateSubnetPrefix string
param postgresSubnetName string = 'postgres-subnet'
param postgresSubnetPrefix string
param publicIpAddress string
param vnetName string = split(publicSubnetId, '/')[8]

// Public subnet NSG
resource publicSubnetNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-${publicSubnetName}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAppGatewayManagement'
        properties: {
          priority: 105 
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: '*' // Allow from any source
          destinationAddressPrefix: '*' // Allow to any destination
        }
      }

      {
        name: 'AllowAppGwInbound'
        properties: {
          priority: 110
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
          priority: 120
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
          priority: 130
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
          priority: 140
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
        name: 'AllowAppGwV2InboundManagement'
        properties: {
          priority: 150
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'  
          destinationAddressPrefix: publicSubnetPrefix  
        }
      }

      {
        name: 'AllowAppGwV2InboundInternetManagement'
        properties: {
          priority: 155
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'Internet'
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
        name: 'AllowInternetOutbound'
        properties: {
          priority: 100 // High priority
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*' // Allow all protocols
          sourcePortRange: '*' // Allow all source ports
          destinationPortRange: '*' // Allow all destination ports
          destinationAddressPrefix: 'Internet' // Allow outbound to Internet Service Tag
          sourceAddressPrefix: publicSubnetPrefix
        }
      }
    ]
  }
}

// Private subnet NSG
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
          destinationPortRanges: [
            '443'
            '5432'
          ]
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
          destinationAddressPrefix: 'AzureContainerRegistry'
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
          destinationAddressPrefix: 'AzureKeyVault'
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
        name: 'AllowOutboundToPostgres'
        properties: {
          priority: 135
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5432'
          destinationAddressPrefix: postgresSubnetPrefix
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

// PostgreSQL subnet NSG
resource postgresSubnetNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-${postgresSubnetName}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowInboundFromAKS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5432'
          sourceAddressPrefix: privateSubnetPrefix
          destinationAddressPrefix: postgresSubnetPrefix
        }
      }
      {
        name: 'AllowPostgresInternalCommunication'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: postgresSubnetPrefix
          destinationAddressPrefix: postgresSubnetPrefix
        }
      }
      {
        name: 'AllowAzureServices'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureCloud'
          destinationAddressPrefix: postgresSubnetPrefix
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
          destinationAddressPrefix: postgresSubnetPrefix
        }
      }
      {
        name: 'AllowOutboundToAzureServices'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: 'AzureCloud'
          sourceAddressPrefix: postgresSubnetPrefix
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
          sourceAddressPrefix: postgresSubnetPrefix
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource publicSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  parent: vnet
  name: publicSubnetName
  properties: {
    addressPrefix: publicSubnetPrefix
    networkSecurityGroup: {
      id: publicSubnetNsg.id
    }
  }
}

resource privateSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  parent: vnet
  name: privateSubnetName
  properties: {
    addressPrefix: privateSubnetPrefix
    networkSecurityGroup: {
      id: privateSubnetNsg.id
    }
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
  dependsOn: [
    publicSubnet
  ]
}

resource postgresSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  parent: vnet
  name: postgresSubnetName
  properties: {
    addressPrefix: postgresSubnetPrefix
    networkSecurityGroup: {
      id: postgresSubnetNsg.id
    }
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
  dependsOn: [
    privateSubnet
  ]
}
