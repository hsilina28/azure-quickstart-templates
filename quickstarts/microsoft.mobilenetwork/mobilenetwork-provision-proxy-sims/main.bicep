@description('Region where the SIM group will be deployed (must match the resource group region).')
param location string

@description('The name of the mobile network to which you are adding the SIM group.')
param existingMobileNetworkName string

@description('The name for the SIM group.')
param simGroupName string

@description('An array containing properties of the SIM(s) you wish to create. See [Provision proxy SIM(s)](https://docs.microsoft.com/en-gb/azure/private-5g-core/provision-sims-azure-portal) for a full description of the required properties and their format.')
param simResources array

resource existingMobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = {
  name: existingMobileNetworkName
}

resource exampleSimPolicyResources 'Microsoft.MobileNetwork/mobileNetworks/simPolicies@2022-04-01-preview' existing = [for item in simResources: {
  parent: existingMobileNetwork
  name: item.existingSimPolicyName
}]

resource exampleSimGroupResource 'Microsoft.MobileNetwork/simGroups@2022-04-01-preview' = {
  name: simGroupName
  location: location
  properties: {
    mobileNetwork: {
      id: existingMobileNetwork.id
    }
  }

  resource exampleSimResources 'sims@2022-04-01-preview' = [for (item, index) in simResources: {
    name: item.simName
    properties: {
      integratedCircuitCardIdentifier: item.integratedCircuitCardIdentifier
      internationalMobileSubscriberIdentity: item.internationalMobileSubscriberIdentity
      authenticationKey: item.authenticationKey
      operatorKeyCode: item.operatorKeyCode
      deviceType: item.deviceType
      simPolicy: {
        id: exampleSimPolicyResources[index].id
      }
    }
  }]
}
