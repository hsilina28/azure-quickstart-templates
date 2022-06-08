@description('The name of the Azure Application Gateway')
param agwName string = 'agw-${uniqueString(resourceGroup().id)}'

@description('The name of the Azure Application Gateway Managed Identity')
param agwIdName string = 'id-${agwName}'

@description('The name of the Azure Key Vault')
param akvName string

@secure()
@description('The URI of the frontend KeyVault Certificate Secret Id')
param frontEndCertificateSecretId string

param backendIpAddress string

@description('The location to deploy the resources to')
param location string = resourceGroup().location

var appgwSubnetAddress = '10.0.1.0/24'
var frontendAgwCertificateName = 'frontend'

var appgwResourceId = resourceId('Microsoft.Network/applicationGateways', '${agwName}')
var frontendAgwCertificateId = '${appgwResourceId}/sslCertificates/${frontendAgwCertificateName}'

resource akv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: akvName
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        appgwSubnetAddress
      ]
    }
    subnets: [
      {
        name: 'agw'
        properties: {
          addressPrefix: appgwSubnetAddress
        }
      }
    ]
  }
}

resource agwId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: agwIdName
  location: location
}

resource agw 'Microsoft.Network/applicationGateways@2021-08-01' = {
  name: agwName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${agwId.id}': {}
    }
  }
  properties: {
      sslCertificates: [
        {
          name: frontendAgwCertificateName
          properties: {
            keyVaultSecretId: frontEndCertificateSecretId
          }
        }
      ]
      sku: {
        capacity: 1
        tier: 'Standard_v2'
        name: 'Standard_v2'
      }
      gatewayIPConfigurations: [
        {
          name: 'besubnet'
          properties: {
            subnet: {
              id: vnet.properties.subnets[0].id
            }
          }
        }
      ]
      frontendIPConfigurations: array({
        properties: {
          publicIPAddress: {
            id: appgwpip.id
          }
        }
        name: 'appGatewayFrontendIP'
      })
      frontendPorts: [
        {
          name: 'appGatewayFrontendPort'
          properties: {
            port: 443
          }
        }
      ]
      backendAddressPools: [
        {
          name: 'defaultaddresspool'
          properties: {
            backendAddresses: [
              {
                ipAddress: backendIpAddress
              }
            ]
          }
        }
      ]
      backendHttpSettingsCollection: [
        {
          name: 'defaulthttpsetting'
          properties: {
            port: 80
            protocol: 'Http'
            cookieBasedAffinity: 'Disabled'
            requestTimeout: 30
            pickHostNameFromBackendAddress: true
          }
        }
      ]
      httpListeners: [
        {
          name: 'hlisten'
          properties: {
            frontendIPConfiguration: {
              id: '${appgwResourceId}/frontendIPConfigurations/appGatewayFrontendIP'
            }
            frontendPort: {
              id: '${appgwResourceId}/frontendPorts/appGatewayFrontendPort'
            }
            protocol: 'Https'
            sslCertificate: {
              id: frontendAgwCertificateId
            }
          }
        }
      ]
      requestRoutingRules: [
        {
          name: 'appGwRoutingRuleName'
          properties: {
            ruleType: 'Basic'
            priority: 100
            httpListener: {
              id: '${appgwResourceId}/httpListeners/hlisten'
            }
            backendAddressPool: {
              id: '${appgwResourceId}/backendAddressPools/defaultaddresspool'
            }
            backendHttpSettings: {
              id: '${appgwResourceId}/backendHttpSettingsCollection/defaulthttpsetting'
            }
          }
        }
      ]

  }
}
output agwId string = agw.id
output agwName string = agw.name

resource appgwpip 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: 'pip-${agwName}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
output agwPip string = appgwpip.properties.ipAddress

var keyVaultSecretsUserRole = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
resource kvAppGwSecretsUserRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: akv
  name: guid(resourceId('Microsoft.Network/applicationGateways',agwName), agwId.id, akv.id, keyVaultSecretsUserRole)
  properties: {
    roleDefinitionId: keyVaultSecretsUserRole
    principalType: 'ServicePrincipal'
    principalId: agwId.properties.principalId
  }
}
