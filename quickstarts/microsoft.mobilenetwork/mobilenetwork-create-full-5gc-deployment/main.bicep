@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param mobileNetworkName string

@description('The mobile country code for the private mobile network')
param mobileCountryCode string = '001'

@description('The mobile network code for the private mobile network')
param mobileNetworkCode string = '01'

@description('The name for the site')
param siteName string = 'myExampleSite'

@description('The name of the service')
param serviceName string = 'Allow_all_traffic'

@description('The name of the SIM policy')
param simPolicyName string = 'Default-policy'

@description('The name of the slice')
param sliceName string = 'slice-1'

@description('The name for the SIM group.')
param simGroupName string

@description('An array containing properties of the SIM(s) you wish to create. See [Provision proxy SIM(s)](https://docs.microsoft.com/en-gb/azure/private-5g-core/provision-sims-azure-portal) for a full description of the required properties and their format.')
param simResources array

@description('The name of the control plane interface on the access network. In 5G networks this is called the N2 interface whereas in 4G networks this is called the S1-MME interface. This should match one of the interfaces configured on your Azure Stack Edge machine.')
param controlPlaneAccessInterfaceName string = ''

@description('The IP address of the control plane interface on the access network. In 5G networks this is called the N2 interface whereas in 4G networks this is called the S1-MME interface.')
param controlPlaneAccessIpAddress string

@description('The logical name of the user plane interface on the access network. In 5G networks this is called the N3 interface whereas in 4G networks this is called the S1-U interface. This should match one of the interfaces configured on your Azure Stack Edge machine.')
param userPlaneAccessInterfaceName string = ''

@description('The IP address of the user plane interface on the access network. In 5G networks this is called the N3 interface whereas in 4G networks this is called the S1-U interface.')
param userPlaneAccessInterfaceIpAddress string

@description('The network address of the access subnet in CIDR notation')
param accessSubnet string

@description('The access subnet default gateway')
param accessGateway string

@description('The logical name of the user plane interface on the data network. In 5G networks this is called the N6 interface whereas in 4G networks this is called the SGi interface. This should match one of the interfaces configured on your Azure Stack Edge machine.')
param userPlaneDataInterfaceName string = ''

@description('The IP address of the user plane interface on the data network. In 5G networks this is called the N6 interface whereas in 4G networks this is called the SGi interface.')
param userPlaneDataInterfaceIpAddress string

@description('The network address of the data subnet in CIDR notation')
param userPlaneDataInterfaceSubnet string

@description('The data subnet default gateway')
param userPlaneDataInterfaceGateway string

@description('The network address of the subnet from which dynamic IP addresses must be allocated to UEs, given in CIDR notation. Optional if userEquipmentStaticAddressPoolPrefix is specified. If both are specified, they must be the same size and not overlap.')
param userEquipmentAddressPoolPrefix string = ''

@description('The network address of the subnet from which static IP addresses must be allocated to UEs, given in CIDR notation. Optional if userEquipmentAddressPoolPrefix is specified. If both are specified, they must be the same size and not overlap.')
param userEquipmentStaticAddressPoolPrefix string = ''

@description('The name of the data network')
param dataNetworkName string = 'internet'

@description('The mode in which the packet core instance will run')
param coreNetworkTechnology string = '5GC'

@description('Whether or not Network Address and Port Translation (NAPT) should be enabled for this data network')
@allowed([
  'Enabled'
  'Disabled'
])
param naptEnabled string

@description('The resource ID of the customLocation representing the ASE device where the packet core will be deployed. If this parameter is not specified then the 5G core will be created but will not be deployed to an ASE. [Collect custom location information](https://docs.microsoft.com/en-gb/azure/private-5g-core/collect-required-information-for-a-site#collect-custom-location-information) explains which value to specify here.')
param customLocation string = ''

resource exampleMobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' = {
  name: mobileNetworkName
  location: location
  properties: {
    publicLandMobileNetworkIdentifier: {
      mcc: mobileCountryCode
      mnc: mobileNetworkCode
    }
  }

  resource exampleSite 'sites@2022-04-01-preview' = {
    name: siteName
    location: location
    properties: {
      networkFunctions: [
        {
          id: examplePacketCoreControlPlane.id
        }
        {
          id: examplePacketCoreControlPlane::examplePacketCoreDataPlane.id
        }
      ]
    }
  }
}

resource exampleDataNetwork 'Microsoft.MobileNetwork/mobileNetworks/dataNetworks@2022-04-01-preview' = {
  parent: exampleMobileNetwork
  name: dataNetworkName
  location: location
  properties: {}
}

resource exampleSlice 'Microsoft.MobileNetwork/mobileNetworks/slices@2022-04-01-preview' = {
  parent: exampleMobileNetwork
  name: sliceName
  location: location
  properties: {
    snssai: {
      sst: 1
    }
  }
}

resource exampleService 'Microsoft.MobileNetwork/mobileNetworks/services@2022-04-01-preview' = {
  parent: exampleMobileNetwork
  name: serviceName
  location: location
  properties: {
    servicePrecedence: 253
    pccRules: [
      {
        ruleName: 'All_traffic'
        rulePrecedence: 253
        trafficControl: 'Enabled'
        serviceDataFlowTemplates: [
          {
            templateName: 'Any-traffic'
            protocol: [
              'ip'
            ]
            direction: 'Bidirectional'
            remoteIpList: [
              'any'
            ]
          }
        ]
      }
    ]
  }
}

resource exampleSimPolicy 'Microsoft.MobileNetwork/mobileNetworks/simPolicies@2022-04-01-preview' = {
  parent: exampleMobileNetwork
  name: simPolicyName
  location: location
  properties: {
    ueAmbr: {
      uplink: '2 Gbps'
      downlink: '2 Gbps'
    }
    defaultSlice: {
      id: exampleSlice.id
    }
    sliceConfigurations: [
      {
        slice: {
          id: exampleSlice.id
        }
        defaultDataNetwork: {
          id: exampleDataNetwork.id
        }
        dataNetworkConfigurations: [
          {
            dataNetwork: {
              id: exampleDataNetwork.id
            }
            sessionAmbr: {
              uplink: '2 Gbps'
              downlink: '2 Gbps'
            }
            allowedServices: [
              {
                id: exampleService.id
              }
            ]
          }
        ]
      }
    ]
  }
}

resource exampleSimGroupResource 'Microsoft.MobileNetwork/simGroups@2022-04-01-preview' = {
  name: simGroupName
  location: location
  properties: {
    mobileNetwork: {
      id: exampleMobileNetwork.id
    }
  }

  resource exampleSimResources 'sims@2022-04-01-preview' = [for item in simResources: {
    name: item.simName
    properties: {
      integratedCircuitCardIdentifier: item.integratedCircuitCardIdentifier
      internationalMobileSubscriberIdentity: item.internationalMobileSubscriberIdentity
      authenticationKey: item.authenticationKey
      operatorKeyCode: item.operatorKeyCode
      deviceType: item.deviceType
      simPolicy: {
        id: exampleSimPolicy.id
      }
    }
  }]
}

resource examplePacketCoreControlPlane 'Microsoft.MobileNetwork/packetCoreControlPlanes@2022-04-01-preview' = {
  name: siteName
  location: location
  properties: {
    mobileNetwork: {
      id: exampleMobileNetwork.id
    }
    sku: 'EvaluationPackage'
    coreNetworkTechnology: coreNetworkTechnology
    platform: {
      type: 'AKS-HCI'
      customLocation: empty(customLocation) ? null : {
        id: customLocation
      }
    }
    controlPlaneAccessInterface: {
      ipv4Address: controlPlaneAccessIpAddress
      ipv4Subnet: accessSubnet
      ipv4Gateway: accessGateway
      name: controlPlaneAccessInterfaceName
    }
  }

  resource examplePacketCoreDataPlane 'packetCoreDataPlanes@2022-04-01-preview' = {
    name: siteName
    location: location
    properties: {
      userPlaneAccessInterface: {
        ipv4Address: userPlaneAccessInterfaceIpAddress
        ipv4Subnet: accessSubnet
        ipv4Gateway: accessGateway
        name: userPlaneAccessInterfaceName
      }
    }

    resource exampleAttachedDataNetwork 'attachedDataNetworks@2022-04-01-preview' = {
      name: dataNetworkName
      location: location
      properties: {
        userPlaneDataInterface: {
          ipv4Address: userPlaneDataInterfaceIpAddress
          ipv4Subnet: userPlaneDataInterfaceSubnet
          ipv4Gateway: userPlaneDataInterfaceGateway
          name: userPlaneDataInterfaceName
        }
        userEquipmentAddressPoolPrefix: empty(userEquipmentAddressPoolPrefix) ? null : [
          userEquipmentAddressPoolPrefix
        ]
        userEquipmentStaticAddressPoolPrefix: empty(userEquipmentStaticAddressPoolPrefix) ? null : [
          userEquipmentStaticAddressPoolPrefix
        ]
        naptConfiguration: {
          enabled: naptEnabled
        }
      }
    }
  }
}
