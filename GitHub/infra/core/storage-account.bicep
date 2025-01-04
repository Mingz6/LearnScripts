
// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription "<subscription-name>" --template-file './core/storage-account.bicep' --name "bicep-keyvault-$(Get-Date -Format 'yyyyMMddHHmmss')"
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription "<subscription-name>" --template-file './core/storage-account.bicep' --name "bicep-keyvault-$(date '+%Y%m%d%H%M%S')"

@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location
param tags object = {
  Application: 'myapp'
  Environment: environmentName
}

// Storage account name does not allow dash `-` in the name
// Add more storage account names here
param storageAccountNames array = [
  'stmingz${environmentName}'
  'stmingzsecond${environmentName}'
]

// Create storages
resource storageAccounts 'Microsoft.Storage/storageAccounts@2022-09-01' = [for stName in storageAccountNames: {
  name: stName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_RAGRS'
  }
  tags: tags
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}]

resource storageAccount_default 'Microsoft.Storage/storageAccounts/managementPolicies@2022-09-01' = [for i in range(0, length(storageAccountNames)): {
  parent: storageAccounts[i]
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'deletePicturesAfter30Days'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: [
                'trulioopictures'
              ]
            }
            actions: {
              baseBlob: {
                delete: {
                  daysAfterModificationGreaterThan: 30
                }
              }
            }
          }
        }
      ]
    }
  }
}]

// Create blob service
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = [for i in range(0, length(storageAccountNames)): {
  name: 'default'
  parent: storageAccounts[i]
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}]

// Create containers for stmingzenviroment
param stmingzenviromentContainerNames array = [
  '$web'
  'app-resources'
]
resource stmingzEnviromentcontainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for containerName in stmingzenviromentContainerNames: {
  name: containerName
  parent: blobServices[0]
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
    metadata: {}
  }
}]

// Create containers for stmingzsecondenviroment
param stmingzsecondEnviromentContainerNames array = [
  '$web'
  'app-resources'
  'handlebartemplates'
  'nurse-uploaded-files'
]
resource stmingzsecondEnviromentcontainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for containerName in stmingzsecondEnviromentContainerNames: {
  name: containerName
  parent: blobServices[1]
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
    metadata: {}
  }
}]

resource storageQueues 'Microsoft.Storage/storageAccounts/queueServices@2022-09-01' = [for i in range(0, length(storageAccountNames)): {
  name: 'default'
  parent: storageAccounts[i]
  properties: {
    cors: {
      corsRules: []
    }
  }
}]

// TODO: add more queue names here
// Create Queue for stmingzenviroment
param stmingzEnviromentQueueNames array = [
  'myfirstqueue'
  'mysecondqueue'
]
resource firstQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01' = [for queueName in stmingzEnviromentQueueNames: {
  name: queueName
  parent: storageQueues[0]
  properties: {
  }
}]

// Create Table for all storage accounts
resource stmingzEnviromentTables 'Microsoft.Storage/storageAccounts/tableServices@2022-09-01' = [for i in range(0, length(storageAccountNames)): {
  name: 'default'
  parent: storageAccounts[i]
  properties: {
    cors: {
      corsRules: []
    }
  }
}]
