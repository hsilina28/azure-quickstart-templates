@description('Name of the CDN Profile')
param profileName string

@description('Name of the CDN Endpoint')
param endpointName string

@description('Url of the origin')
param originUrl string

@description('CDN SKU names')
@allowed([
  'Standard_Akamai'
  'Standard_Verizon'
  'Premium_Verizon'
  'Standard_Microsoft'
])
param CDNSku string = 'Standard_Microsoft'

@description('Location for all resources.')
param location string = resourceGroup().location

resource profile 'Microsoft.Cdn/profiles@2020-09-01' = {
  name: profileName
  location: location
  sku: {
    name: CDNSku
  }
}

resource endpoint 'Microsoft.Cdn/profiles/endpoints@2019-04-15' = {
  parent: profile
  location: location
  name: endpointName
  properties: {
    originHostHeader: originUrl
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'application/x-javascript'
      'text/javascript'
    ]
    isCompressionEnabled: true
    origins: [
      {
        name: 'origin1'
        properties: {
          hostName: originUrl
        }
      }
    ]
    deliveryPolicy: {
      description: 'Rewrite and Redirect'
      rules: [
        {
          name: 'PathRewriteBasedOnDeviceMatchCondition'
          order: 1
          conditions: [
            {
              name: 'IsDevice'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleIsDeviceConditionParameters'
                operator: 'Equal'
                matchValues: [
                  'Mobile'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'UrlRewrite'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlRewriteActionParameters'
                sourcePattern: '/standard'
                destination: '/mobile'
              }
            }
          ]
        }
        {
          name: 'HttpVersionBasedRedirect'
          order: 2
          conditions: [
            {
              name: 'RequestScheme'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleRequestSchemeConditionParameters'
                operator: 'Equal'
                matchValues: [
                  'HTTP'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'UrlRedirect'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlRedirectActionParameters'
                redirectType: 'Found'
                destinationProtocol: 'Https'
              }
            }
          ]
        }
      ]
    }
  }
}
