@description('Name of the L3 Isolation Domain')
param l3DomainName string

@description('Azure Region for deployment of the L3 Isolation Domain and associated resources')
param location string = resourceGroup().location

@description('Resource Id of the Network Fabric, is should be in the format of /subscriptions/<Sub ID>/resourceGroups/<Resource group name>/providers/Microsoft.ManagedNetworkFabric/networkFabrics/<networkFabric name>')
param networkFabricId string

@description('Switch configuration description')
param annotation string = ''

@description('Advertise Connected Subnets')
@allowed([
  'True'
  'False'
])
param redistributeConnectedSubnets string ='True'

@description('Advertise Static Routes')
@allowed([
  'True'
  'False'
])
param redistributeStaticRoutes string ='False'

@description('List of Ipv4 and Ipv6 route configurations')
param aggregateRouteConfiguration object

@description('Connected Subnet RoutePolicy')
param connectedSubnetRoutePolicy object

@description('Create L3 Isolation Domain  Resource')
resource l3IsolationDomains 'Microsoft.ManagedNetworkFabric/l3IsolationDomains@2023-06-15' = {
  name: l3DomainName
  location: location
  properties: {
    networkFabricId: networkFabricId
    annotation: !empty(annotation) ? annotation : null
    redistributeConnectedSubnets: redistributeConnectedSubnets
    redistributeStaticRoutes: redistributeStaticRoutes
    aggregateRouteConfiguration: !empty(aggregateRouteConfiguration) ? {
      ipv4Routes: contains(aggregateRouteConfiguration, 'ipv4Routes') ? aggregateRouteConfiguration.ipv4Routes : null
      ipv6Routes: contains(aggregateRouteConfiguration, 'ipv6Routes') ? aggregateRouteConfiguration.ipv6Routes : null
    } : null
    connectedSubnetRoutePolicy: !empty(connectedSubnetRoutePolicy) ? {
      exportRoutePolicy: contains(connectedSubnetRoutePolicy, 'exportRoutePolicy') ? connectedSubnetRoutePolicy.exportRoutePolicy : null
    } : null
  }
}

output resourceID string = l3IsolationDomains.id
