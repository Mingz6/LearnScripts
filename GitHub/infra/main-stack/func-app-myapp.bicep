// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./main-stack/func-app-myapp.bicep" --parameters "./main-stack/params/func-app-myapp-params.json" --name "bicep-myapp-$(Get-Date -Format 'yyyyMMddHHmmss')"
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./main-stack/func-app-myapp.bicep" --parameters "./main-stack/params/func-app-myapp-params.json" --name "bicep-myapp-$(date '+%Y%m%d%H%M%S')"

@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location
param tags object = {
  Application: 'myapp'
  Environment: environmentName
}
param currentDate string = utcNow('yyyyMMddHHmmss')

param myFirstParams object
param mySecondParams object

var abbrs = loadJsonContent('../abbreviations.json')
var base = 'mingz'
var vaultName = '${abbrs.keyVaultVaults}-${base}-${environmentName}'
var keyVaultDnsSuffix = environment().suffixes.keyvaultDns
var keyVaultUrl = 'https://${vaultName}${keyVaultDnsSuffix}/'
var dbnameDatabaseUrl = '${keyVaultUrl}DbConnectionString/)'
var storageAccountName = 'stmingz${environmentName}'

module myappAzureFunctions '../core/func-app.bicep' = {
  name: '${abbrs.webSitesFunctions}-${base}-myapp-${environmentName}-${currentDate}'
  params: {
    funcAppName:'${abbrs.webSitesFunctions}-${base}-myapp-${environmentName}'
    environmentName: environmentName
    location: location
    tags: tags
    storageAccountName: storageAccountName
    functionsWorkerRuntime: 'dotnet-isolated'
    appSettings: [
        { name: 'myApp:firstParams', value: myFirstParams[environmentName] }
        { name: 'myApp:secondParams', value: mySecondParams[environmentName] }
    ]
    dbConnectionString: [
        {
          name: 'dbnameDatabase'
          type: 'Custom'
          connectionString: '@Microsoft.KeyVault(SecretUri=${dbnameDatabaseUrl}'
        }
      ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccountName
}

resource mingzAppStorageQueues 'Microsoft.Storage/storageAccounts/queueServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource myQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01' = {
  name: 'myqueue-creation'
  parent: mingzAppStorageQueues
  properties: {}
}
