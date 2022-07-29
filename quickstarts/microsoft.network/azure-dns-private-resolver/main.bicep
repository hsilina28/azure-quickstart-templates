@description('name of the new virtual network where DNS resolver will be created')
param resolverVNETName string = 'dnsresolverVNET'

@description('the IP address space for the resolver virtual network')
param resolverVNETAddressSpace string = '10.7.0.0/24'

@description('name of the dns private resolver')
param dnsResolverName string = 'dnsResolver'

@allowed([
  'australiaeast'
  'uksouth'
  'northeurope'
  'southcentralus'
  'westus3'
  'eastus'
  'northcentralus'
  'centraluseuap'
  'eastus2euap'
  'westcentralus'
  'eastus2'
  'westeurope'
])

@description('the location for resolver VNET and dns private resolver')
param location string //resolver available in specific region, refer the documenation for more information https://docs.microsoft.com/en-us/azure/dns/dns-private-resolver-overview#regional-availability

@description('name of the subnet that will be used for private resolver inbound endpoint')
param inboundSubnet string = 'snet-inbound'

@description('the inbound endpoint subnet address space')
param inboundAddressPrefix string = '10.7.0.0/28'

@description('name of the subnet that will be used for private resolver outbound endpoint')
param outboundSubnet string = 'snet-outbound'

@description('the outbound endpoint subnet address space')
param outboundAddressPrefix string = '10.7.0.16/28'

@description('name of the vnet link that links outbound endpoint with forwarding rule set')
param resolvervnetlink string = 'vnetlink'

@description('name of the forwarding ruleset')
param forwardingRulesetName string = 'forwardingRule'

@description('name of the forwarding rule name')
param forwardingRuleName string = 'contosocom'

@description('the target domain name for the forwarding ruleset')
param DomainName string = 'contoso.com.'

@description('the list of target DNS servers ip address and the port number for conditional forwarding')
param targetDNS array = [
    {
      ipaddress: '10.0.0.4'
      port: 53
    }
    {
      ipaddress: '10.0.0.5'
      port: 53
    }
  ]

resource resolver 'Microsoft.Network/dnsResolvers@2020-04-01-preview' = {
  name: dnsResolverName
  location: location
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
  }
}

resource inEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2020-04-01-preview' = {
  parent: resolver
  name: inboundSubnet
  location: location
  properties: {
    ipConfigurations: [
      {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: '${resolverVnet.id}/subnets/${inboundSubnet}'
        }
      }
    ]
  }
}

resource outEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2020-04-01-preview' = {
  parent: resolver
  name: outboundSubnet
  location: location
  properties: {
    subnet: {
      id: '${resolverVnet.id}/subnets/${outboundSubnet}'
    }
  }
}

resource fwruleSet 'Microsoft.Network/dnsForwardingRulesets@2020-04-01-preview' = {
  name: forwardingRulesetName
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outEndpoint.id
      }
    ]
  }
}

resource resolverLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2020-04-01-preview' = {
  parent: fwruleSet
  name: resolvervnetlink
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
  }
}

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2020-04-01-preview' = {
  parent: fwruleSet
  name: forwardingRuleName
  properties: {
    domainName: DomainName
    targetDnsServers: targetDNS
  }
}

resource resolverVnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: resolverVNETName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        resolverVNETAddressSpace
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
    subnets: [
      {
        name: inboundSubnet
        properties: {
          addressPrefix: inboundAddressPrefix
        }
      }
      {
        name: outboundSubnet
        properties: {
          addressPrefix: outboundAddressPrefix
        }
      }
    ]
  }
}
