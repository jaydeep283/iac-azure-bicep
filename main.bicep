param location string = 'northeurope'
param vnetName string = 'vnet-aks-infra'
param publicSubnetName string = 'public-subnet'
param privateSubnetName string = 'private-subnet'
param publicSubnetPrefix string = '10.0.1.0/24'
param privateSubnetPrefix string = '10.0.2.0/24'
param appGwName string = 'appgw-waf'
param publicIpName string = 'pip-appgw'
param aksClusterName string = 'aks-cluster'
param acrName string = 'acraks${uniqueString(resourceGroup().id)}'
param keyVaultName string = 'kv-az-aks${uniqueString(resourceGroup().id)}'
param postgresServerName string = 'postgres-aks'
param postgresAdminLogin string = 'pgadmin'
@secure()
param postgresAdminPassword string

// Module for Network
module networkModule 'network.bicep' = {
  name: 'networkDeployment'
  params: {
    location: location
    vnetName: vnetName
    publicSubnetName: publicSubnetName
    publicSubnetPrefix: publicSubnetPrefix
    privateSubnetName: privateSubnetName
    privateSubnetPrefix: privateSubnetPrefix
  }
}

// Module for Public IP
module publicIpModule 'publicip.bicep' = {
  name: 'publicIpDeployment'
  params: {
    location: location
    publicIpName: publicIpName
  }
}

// Module for Network Security Groups - MOVE THIS BEFORE APP GATEWAY
module nsgModule 'nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    privateSubnetId: networkModule.outputs.privateSubnetId
    publicSubnetId: networkModule.outputs.publicSubnetId
    postgresSubnetId: networkModule.outputs.postgresSubnetId
    publicSubnetName: publicSubnetName
    privateSubnetName: privateSubnetName
    postgresSubnetName: 'postgres-subnet'
    publicSubnetPrefix: publicSubnetPrefix
    privateSubnetPrefix: privateSubnetPrefix
    postgresSubnetPrefix: '10.0.3.0/24'
    publicIpAddress: publicIpModule.outputs.publicIpAddress
    vnetName: vnetName
  }
  dependsOn: [
    networkModule
    publicIpModule
  ]
}

// Module for Application Gateway
module appGwModule 'appgateway.bicep' = {
  name: 'appGwDeployment'
  params: {
    location: location
    appGwName: appGwName
    publicIpId: publicIpModule.outputs.publicIpId
    publicSubnetId: networkModule.outputs.publicSubnetId
    backendPoolName: 'aksBackendPool'
    httpSettingsName: 'httpSettings'
    httpListenerName: 'httpListener'
    httpRoutingRuleName: 'httpRoutingRule'
  }
  dependsOn: [
    nsgModule // Ensure NSG is created before the Application Gateway
    publicIpModule // Ensure public IP is created before the Application Gateway
    networkModule  // Ensure network module is deployed before app gateway
  ]
}

// Module for AKS
module aksModule 'aks.bicep' = {
  name: 'aksDeployment'
  params: {
    location: location
    aksClusterName: aksClusterName
    privateSubnetId: networkModule.outputs.privateSubnetId
    appGatewayId: appGwModule.outputs.appGwId
  }
  dependsOn: [
    appGwModule
    networkModule
  ]
}

// Module for ACR
module acrModule 'acr.bicep' = {
  name: 'acrDeployment'
  params: {
    location: location
    acrName: acrName
    aksPrincipalId: aksModule.outputs.aksPrincipalId
  }
  dependsOn: [
    aksModule
  ]
}

// Module for Key Vault
module keyVaultModule 'keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: keyVaultName
    aksPrincipalId: aksModule.outputs.aksPrincipalId
  }
  dependsOn: [
    aksModule
  ]
}

// Module for Flexible PostgreSQL Server
module postgresModule 'postgres.bicep' = {
  name: 'postgresDeployment'
  params: {
    location: location
    postgresServerName: '${postgresServerName}-${uniqueString(resourceGroup().id)}'  // Make name unique
    administratorLogin: postgresAdminLogin
    administratorPassword: postgresAdminPassword
    privateSubnetId: networkModule.outputs.postgresSubnetId  // Use the PostgreSQL subnet
    vnetId: networkModule.outputs.vnetId
  }
  dependsOn: [
    nsgModule  // Ensure NSG is created before PostgreSQL
    networkModule
  ]
}
