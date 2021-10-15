param vmssname string = 'myVmssFlex'
param region string = resourceGroup().location
param zones array = []

param vmSize string = 'Standard_DS1_v2'
@allowed([
  1
  2
  3
  5
])
param platformFaultDomainCount int = 1
@minValue(0)
@maxValue(1000)
param vmCount int = 3

@allowed([
  'ubuntulinux'
  'windowsserver'
])
param os string = 'ubuntulinux'

param subnetId string
param lbBackendPoolArray array = []

param adminUsername string = 'azureuser'
@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string = 'password'

@secure()
param adminPasswordOrKey string = newGuid()

var networkApiVersion = '2020-11-01'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  provisionVMAgent: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

var linuxImageReference = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '18_04-LTS-Gen2'
  version: 'latest'
}
var windowsImageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}
var windowsConfiguration =  {
  timeZone: 'Pacific Standard Time'
}

var imageReference = (os == 'ubuntulinux' ? linuxImageReference : windowsImageReference)

resource vmssflex 'Microsoft.Compute/virtualMachineScaleSets@2021-04-01' = {
  name: vmssname
  location: region
  zones: zones
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: vmCount
  }
  properties: {
    orchestrationMode: 'Flexible'
    singlePlacementGroup: false
    platformFaultDomainCount: platformFaultDomainCount

    virtualMachineProfile: {
 
      osProfile: {
        computerNamePrefix: 'myVm'
        adminUsername: adminUsername
        adminPassword: (authenticationType== 'password' ? adminPasswordOrKey: null)
        linuxConfiguration: (os=='ubuntulinux' && authenticationType == 'sshPublicKey'? linuxConfiguration : null)
        windowsConfiguration: (os=='windowsserver' ? windowsConfiguration : null)
      }
      networkProfile: {
        networkApiVersion: networkApiVersion
        networkInterfaceConfigurations: [
            {
            name: '${vmssname}NicConfig01'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              ipConfigurations: [
                {
                  name: '${vmssname}IpConfig'
                  properties: {
                    // Uncomment to enable public IP address per instance
                    // publicIPAddressConfiguration: {
                    //   name: '${vmssname}PipConfig'
                    //   properties:{
                    //     publicIPAddressVersion: 'IPv4'
                    //     idleTimeoutInMinutes: 5
                    //   }
                    // }
                    privateIPAddressVersion: 'IPv4'
                    subnet: {
                      id: subnetId
                    }
                    loadBalancerBackendAddressPools: lbBackendPoolArray
                  }
                }
              ]
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: 'AppHealthExtension'
            properties: {
              publisher: 'Microsoft.ManagedServices'
              type: 'ApplicationHealthLinux'
              autoUpgradeMinorVersion: true
              typeHandlerVersion: '1.0'
              settings: {
                protocol: 'http'
                port: 80
                requestPath: '/health'
              }
            }
          }
        ]
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        imageReference: imageReference
      }
      // Enable Terminate notification
      scheduledEventsProfile: {
        terminateNotificationProfile: {
          notBeforeTimeout: 'PT5M'
          enable: true
        }
      }
      // Uncomment to use Azure Spot instances for significant cost savings. https://docs.microsoft.com/en-us/azure/virtual-machines/spot-vms
      // priority: 'Spot'
      // evictionPolicy: 'Delete'
      // billingProfile: {
      //   maxPrice: -1
      // }
    }
    automaticRepairsPolicy: {
      enabled: true
      gracePeriod: 'PT30M'
    } 
  }
}

output vmssid string = vmssflex.id
output vmssAdminUsername string = adminUsername
