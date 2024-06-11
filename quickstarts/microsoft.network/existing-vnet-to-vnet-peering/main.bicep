@description('Set the local VNet name')
param existingLocalVirtualNetworkName string

@description('Set the remote VNet name')
param existingRemoteVirtualNetworkName string

@description('Sets the remote VNet Resource group')
param existingRemoteVirtualNetworkResourceGroupName string

@description('Sets the local VNet Resource group')
param existingLocalVirtualNetworkResourceGroupName string

resource existingLocalVirtualNetworkName_peering_to_remote_vnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${existingLocalVirtualNetworkName}/peering-to-remote-vnet'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(
        existingRemoteVirtualNetworkResourceGroupName,
        'Microsoft.Network/virtualNetworks',
        existingRemoteVirtualNetworkName
      )
    }
  }
}

resource existingRemoteVirtualNetworkName_peering_to_local_vnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${existingRemoteVirtualNetworkName}/peering-to-local-vnet'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(
        existingLocalVirtualNetworkResourceGroupName,
        'Microsoft.Network/virtualNetworks',
        existingLocalVirtualNetworkName
      )
    }
  }
}
