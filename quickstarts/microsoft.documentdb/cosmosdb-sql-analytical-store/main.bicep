@description('Cosmos DB account name')
param accountName string = 'cosmos${uniqueString(resourceGroup().id)}'

@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('The name for the database')
param databaseName string = 'database1'

@description('The name for the container')
param containerName string = 'container1'

@description('The partition key for the container')
param partitionKeyPath string = '/partitionKey'

@allowed([
  'Manual'
  'Autoscale'
])
@description('The throughput policy for the container')
param throughputPolicy string = 'Autoscale'

@minValue(400)
@maxValue(1000000)
@description('Throughput value when using Manual Throughput Policy for the container')
param manualProvisionedThroughput int = 400

@minValue(4000)
@maxValue(1000000)
@description('Maximum throughput when using Autoscale Throughput Policy for the container')
param autoscaleMaxThroughput int = 4000

@minValue(-1)
@description('Time to Live for data in analytical store. (-1 no expiry)')
param analyticalStoreTTL int = -1

var accountName_var = toLower(accountName)
var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]
var throughputPolicy_var = {
  Manual: {
    Throughput: manualProvisionedThroughput
  }
  Autoscale: {
    autoscaleSettings: {
      maxThroughput: autoscaleMaxThroughput
    }
  }
}

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: accountName_var
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    databaseAccountOfferType: 'Standard'
    locations: locations
    enableAnalyticalStorage: true
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-04-15' = {
  name: '${accountName_resource.name}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource accountName_databaseName_containerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-04-15' = {
  name: '${accountName_databaseName.name}/${containerName}'
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          partitionKeyPath
        ]
        kind: 'Hash'
      }
      analyticalStorageTtl: analyticalStoreTTL
    }
    options: throughputPolicy_var[throughputPolicy]
  }
}