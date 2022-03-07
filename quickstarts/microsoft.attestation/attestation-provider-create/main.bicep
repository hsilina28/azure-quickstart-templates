@description('Name of the Attestation provider. Must be between 3 and 24 characters in length and use numbers and lower-case letters only.')
param attestationProviderName string = uniqueString(resourceGroup().name, deployment().name)

@description('Location for all resources.')
param location string = resourceGroup().location
param tags object = {}
param policySigningCertificates string = ''

var PolicySigningCertificates_var = {
  PolicySigningCertificates: {
    keys: [
      {
        kty: 'RSA'
        use: 'sig'
        x5c: [
          policySigningCertificates
        ]
      }
    ]
  }
}

resource attestationProviderName_resource 'Microsoft.Attestation/attestationProviders@2021-06-01-preview' = {
  name: attestationProviderName
  location: location
  tags: tags
  properties: (empty(policySigningCertificates) ? json('{}') : PolicySigningCertificates_var)
}