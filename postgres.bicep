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

// Create a Private DNS Zone for PostgreSQL
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.postgres.database.azure.com'
  location: 'global'
  tags: {
    displayName: 'PostgreSQL Private DNS Zone'
  }
}

// Link the Private DNS Zone to your VNet
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-to-vnet'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// PostgreSQL Flexible Server with explicit DNS zone reference
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: postgresServerName
  location: location
  sku: {
    name: skuName
    tier: 'Burstable' 
  }
  properties: {
    version: postgresVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: storageSizeGB
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: privateSubnetId
      privateDnsZoneArmResourceId: privateDnsZone.id
    }
  }
  dependsOn: [
    privateDnsZone
    vnetLink
  ]
}

output postgresServerId string = postgresServer.id
output postgresFullyQualifiedDomainName string = postgresServer.properties.fullyQualifiedDomainName
