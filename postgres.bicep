param location string = resourceGroup().location
param postgresServerName string
param administratorLogin string
@secure()
param administratorPassword string
param skuName string = 'Standard_B1ms'
param storageSizeGB int = 32
param postgresVersion string = '15'
param privateSubnetId string
param vnetId string 

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: postgresServerName
  location: location
  sku: {
    name: skuName
    tier: 'Burstable' 
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    version: postgresVersion
    storage: {
      storageSizeGB: storageSizeGB
    }
    network: {
      delegatedSubnetResourceId: privateSubnetId
      privateDnsZoneArmId: '' 
    }
  }
}

//Create a Private Endpoint for more secure access (recommended)
resource postgresPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${postgresServerName}'
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'postgresConnection'
        properties: {
          privateLinkServiceId: postgresServer.id
          groupIds: [
            'postgresqlServer'
          ]
        }
      }
    ]
  }
}

// Create Private DNS Zone Group to associate with the VNet
resource privateDnsZoneGroup 'Microsoft.DBforPostgreSQL/flexibleServers/privateDnsZoneGroups@2023-06-01-preview' = {
  parent: postgresServer
  name: 'default'
  properties: {
    privateDnsZoneId: postgresServer.properties.network.privateDnsZoneArmId
  }
}

output postgresServerId string = postgresServer.id
output postgresFullyQualifiedDomainName string = postgresServer.properties.fullyQualifiedDomainName
output postgresPrivateEndpointId string = postgresPrivateEndpoint.id
