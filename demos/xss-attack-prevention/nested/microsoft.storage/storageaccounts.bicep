param storageAccountName string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param sku string = 'Standard_LRS'
param location string
param tags object

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: storageAccountName
  sku: {
    name: sku
  }
  kind: 'Storage'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
  }
}

output storageAccountName string = storageAccountName