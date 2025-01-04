@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location
param tags object = {
  Application: 'myapp'
  Environment: environmentName
}

param funcAppName string
param appSettings array
param storageAccountName string
param dbConnectionString array
param functionsWorkerRuntime string = 'dotnet-isolated'

var abbrs = loadJsonContent('../abbreviations.json')
var base = 'mingz'

var appInsightsName = '${abbrs.insightsComponents}-${base}-${environmentName}'
var hybridConnectionName = 'hc-sql-dbname${environmentName}'
var hybridConnectionResourceId = resourceId('<shared-resources-group>', 'Microsoft.Relay/Namespaces/Hybridconnections', hybridConnectionServiceBusNamespace, hybridConnectionName)
var hybridConnectionServiceBusNamespace = 'sb-hc-mingz'
var storageAccountKey = listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2022-09-01').keys[0].value
var storageAccountUrl = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey}'

var basicAppSettings = [
  { name: 'APPINSIGHTS_INSTRUMENTATIONKEY', value: reference(resourceId('Microsoft.Insights/components', appInsightsName), '2020-02-02').InstrumentationKey }
  { name: 'AzureWebJobsDashboard', value: storageAccountUrl }
  { name: 'AzureWebJobsStorage', value: storageAccountUrl }
  { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
  { name: 'FUNCTIONS_WORKER_RUNTIME', value: functionsWorkerRuntime }
  { name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING', value: storageAccountUrl }
  { name: 'WEBSITE_CONTENTSHARE', value: toLower(funcAppName) }
  { name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE', value: 'true' }
  { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '1' }
  { name: 'WEBSITE_TIME_ZONE', value: 'Mountain Standard Time' }
]

var completeAppSettings = concat(basicAppSettings, appSettings)

resource azureFunctionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: funcAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    serverFarmId: resourceId('Microsoft.Web/serverfarms', '${abbrs.webServerFarms}-${base}-${environmentName}')
    siteConfig: {
      alwaysOn: true
      appSettings: completeAppSettings
      connectionStrings: dbConnectionString
    }
  }
}

resource FunctionAppRelay 'Microsoft.Web/sites/hybridConnectionNamespaces/relays@2022-09-01' = {
  name: '${funcAppName}/${hybridConnectionServiceBusNamespace}/${hybridConnectionName}'
  dependsOn: [azureFunctionApp]
  properties: {
    hostname: split(json(reference(hybridConnectionResourceId, '2017-04-01').userMetadata)[0].value, ':')[0]
    port: int(split(json(reference(hybridConnectionResourceId, '2017-04-01').userMetadata)[0].value, ':')[1])
    relayArmUri: hybridConnectionResourceId
    relayName: hybridConnectionName
    sendKeyName: 'defaultSender'
    sendKeyValue: listkeys('${hybridConnectionResourceId}/authorizationRules/defaultSender', '2017-04-01').primaryKey
    serviceBusNamespace: hybridConnectionServiceBusNamespace
  }
}
