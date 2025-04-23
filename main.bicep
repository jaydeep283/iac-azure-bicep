param location string = 'westus'
param vnetName string = 'vnet-aks-infra'
param publicSubnetName string = 'public-subnet'
param privateSubnetName string = 'private-subnet'
param publicSubnetPrefix string = '10.0.1.0/24'
param privateSubnetPrefix string = '10.0.2.0/24'
param appGwName string = 'appgw-waf'
param publicIpName string = 'pip-appgw'
param aksClusterName string = 'aks-cluster'
param acrName string = 'acraks${uniqueString(resourceGroup().id)}'
param keyVaultName string = 'kv-aks${uniqueString(resourceGroup().id)}'
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

// Module for ACR
module acrModule 'acr.bicep' = {
  name: 'acrDeployment'
  params: {
    location: location
    acrName: acrName
    aksPrincipalId: aksModule.outputs.aksPrincipalId
  }
}

// Module for Key Vault
module keyVaultModule 'keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: keyVaultName
    aksPrincipalId: aksModule.outputs.aksPrincipalId
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
}

// Module for Network Security Groups
module nsgModule 'nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    privateSubnetId: networkModule.outputs.privateSubnetId  // private subnet ID from VNet module
    publicSubnetId: networkModule.outputs.publicSubnetId   // public subnet ID from VNet module
    publicSubnetName: publicSubnetName
    privateSubnetName: privateSubnetName
    publicSubnetPrefix: publicSubnetPrefix
    privateSubnetPrefix: privateSubnetPrefix
    publicIpAddress: publicIpModule.outputs.publicIpAddress
    acrLoginServer: acrModule.outputs.acrLoginServer
    keyVaultUri: keyVaultModule.outputs.keyVaultUri
    // vnetId: networkModule.outputs.vnetId
  }
}

// Module for Flexible PostgreSQL Server
module postgresModule 'postgres.bicep' = {
  name: 'postgresDeployment'
  params: {
    location: location
    postgresServerName: postgresServerName
    administratorLogin: postgresAdminLogin
    administratorPassword: postgresAdminPassword
    privateSubnetId: networkModule.outputs.privateSubnetId
    vnetId: networkModule.outputs.vnetId
  }
}
