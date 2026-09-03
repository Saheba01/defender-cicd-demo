@description('Name of the storage account')
param storageAccountName string = 'demopubsa${uniqueString(resourceGroup().id)}'

@description('Location for resources')
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource publicContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  parent: blobService
  name: 'public-demo-container'
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountName string = storageAccount.name
output containerUrl string = '${storageAccount.properties.primaryEndpoints.blob}${publicContainer.name}'
