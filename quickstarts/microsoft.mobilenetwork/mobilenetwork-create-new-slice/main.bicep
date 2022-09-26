@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string

@description('Name of the Mobile Network to add a Slice to')
param existingMobileNetworkName string

@description('The name of the Slice')
param sliceName string

@description('The SST value for the slice being deployed.')
@maxValue(255)
@minValue(0)
param sst int

@description('The SD value for the slice being deployed.')
param sd string=''

#disable-next-line BCP081
resource existingMobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = {
  name: existingMobileNetworkName

  #disable-next-line BCP081
  resource exampleSlice 'slices@2022-04-01-preview' = {
    name: sliceName
    location: location
    properties:!empty(sd) ?{
      snssai: {       
        sst: sst
        sd:sd
      }     
    }:{
      snssai: {       
        sst: sst        
      }     
    }
  }
}
