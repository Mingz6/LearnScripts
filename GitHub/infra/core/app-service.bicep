// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/app-service.bicep" --parameters "./core/params/app-service-params.json" --name "bicep-appservice-$(Get-Date -Format 'yyyyMMddHHmmss')"
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/app-service.bicep" --parameters "./core/params/app-service-params.json" --name "bicep-appservice-$(date '+%Y%m%d%H%M%S')"

@secure()
@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location
param tags object = {
  Application: 'myapp'
  Environment: environmentName
}

@allowed([ 'firstWebApp', 'secondWebApp' ])
param targetWebAppName string
param webAppProfiles object
var webAppProfile = webAppProfiles[environmentName][targetWebAppName]

var isSecondApp = contains(webAppProfile.webAppName, 'second')

var abbrs = loadJsonContent('../abbreviations.json')
var base = 'mingz'

// appSettings
var firstCdnUrl = '${base}-${environmentName}.domain.ab.ca'
var secondCdnUrl = 'second.${base}-${environmentName}.domain.ab.ca'
var cdnUrl = isSecondApp ? secondCdnUrl : firstCdnUrl
var vaultName = '${abbrs.keyVaultVaults}-${base}-${environmentName}'
param myFirstParams object
param mySecondParams object

// hybridConnection
var hybridConnectionServiceBusNamespace = 'sb-hc-mingz'
var hybridConnectionName = 'hc-sql-dbname${environmentName}'
var hybridConnectionResourceId = resourceId('shared-resources', 'Microsoft.Relay/Namespaces/Hybridconnections', hybridConnectionServiceBusNamespace, hybridConnectionName)

var webAppSettings = [
  { name: 'App:ServerRootAddress', value: 'https://${webAppProfile.apiUrl}' }
  { name: 'App:ClientRootAddress', value: 'https://${cdnUrl}' }
  { name: 'App:CorsOrigins', value: 'https://${firstCdnUrl},https://${secondCdnUrl}' }
  { name: 'Demo1:myFirstParam', value: myFirstParams[environmentName] }
  { name: 'Demo2:Clients:0:RedirectUris:0', value: 'https://${secondCdnUrl}/' }
  { name: 'Demo3:Clients:2:RedirectUris:0', value: mySecondParams[environmentName] }
  // ... more common app settings
]

var moreAppSettings = [
  { name: 'App:MingZAppServerRootAddress', value: 'https://${webAppProfile.apiUrl}' }
  // ... more app settings
]

var appSettings = isSecondApp? concat(
  webAppSettings,
  moreAppSettings
) : webAppSettings

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' existing = {
  name: '${abbrs.webServerFarms}-${base}-${environmentName}'
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppProfile.webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  kind: 'app'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${webAppProfile.webAppName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${webAppProfile.webAppName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlan.id
    reserved: false
    isXenon: false
    hyperV: false
    siteConfig: {
      appSettings: webAppSettings
      connectionStrings: [
        { name: 'Default', type: 'Custom', connectionString: '@Microsoft.KeyVault(SecretUri=https://${vaultName}.vault.azure.net/secrets/DbConnectionString/)' }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    clientCertEnabled: false
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    redundancyMode: 'None'
  }
}

var slotAppSettingNames = isSecondApp? ['App:ServerRootAddress', 'App:MingZAppServerRootAddress'] : ['App:ServerRootAddress']

resource webAppName_slotconfignames 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: webApp
  name: 'slotConfigNames'
  properties: {
    appSettingNames: slotAppSettingNames
  }
}

var publishingUsername = isSecondApp? '$app-mingzapp-secondtest' : '$app-mingzapptest'

resource webAppName_web 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: webApp
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: publishingUsername
    azureStorageAccounts: {}
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    ftpsState: 'AllAllowed'
    preWarmedInstanceCount : 0
  }
}

resource webAppName_webAppName_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2022-09-01' = {
  parent: webApp
  name: '${webAppProfile.webAppName}.azurewebsites.net'
  properties: {
    siteName: webAppProfile.webAppName
    hostNameType: 'Verified'
  }
}

resource webAppName_hybridConnectionServiceBusNamespace_hybridConnection 'Microsoft.Web/sites/hybridConnectionNamespaces/relays@2022-09-01' = {
  name: '${webAppProfile.webAppName}/${hybridConnectionServiceBusNamespace}/${hybridConnectionName}'
  properties: {
    serviceBusNamespace: hybridConnectionServiceBusNamespace
    relayName: hybridConnectionName
    relayArmUri: hybridConnectionResourceId
    hostname: split(json(reference(hybridConnectionResourceId, '2017-04-01').userMetadata)[0].value, ':')[0]
    port: int(split(json(reference(hybridConnectionResourceId, '2017-04-01').userMetadata)[0].value, ':')[1])
    sendKeyName: 'defaultSender'
    sendKeyValue: listkeys('${hybridConnectionResourceId}/authorizationRules/defaultSender', '2017-04-01').primaryKey
  }
  dependsOn: [
    webApp
  ]
}

resource webAppName_staging 'Microsoft.Web/sites/slots@2022-09-01' = {
  parent: webApp
  name: 'staging'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  kind: 'app'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${webAppProfile.webAppName}-staging.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${webAppProfile.webAppName}-staging.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlan.id
    reserved: false
    isXenon: false
    hyperV: false
    siteConfig: {
      appSettings: appSettings
      connectionStrings: [
        { name: 'Default', type: 'Custom', connectionString: '@Microsoft.KeyVault(SecretUri=https://${vaultName}.vault.azure.net/secrets/DbConnectionString/)' }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    clientCertEnabled: false
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    redundancyMode: 'None'
  }
}

resource webAppName_staging_web 'Microsoft.Web/sites/slots/config@2022-09-01' = {
  parent: webAppName_staging
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2019'
    httpLoggingEnabled: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$app-mingzapptest__staging'
    azureStorageAccounts: {}
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    ftpsState: 'AllAllowed'
    preWarmedInstanceCount: 0
  }
}

resource webAppName_staging_webAppName_staging_azurewebsites_net 'Microsoft.Web/sites/slots/hostNameBindings@2022-09-01' = {
  parent: webAppName_staging
  name: '${webAppProfile.webAppName}-staging.azurewebsites.net'
  properties: {
    siteName: 'app-mingzapptest(staging)'
    hostNameType: 'Verified'
  }
}

resource webAppName_staging_hybridConnectionServiceBusNamespace_hybridConnection 'Microsoft.Web/sites/slots/hybridConnectionNamespaces/relays@2022-09-01' = {
  name: '${webAppProfile.webAppName}/staging/${hybridConnectionServiceBusNamespace}/${hybridConnectionName}'
  properties: {
    serviceBusNamespace: hybridConnectionServiceBusNamespace
    relayName: hybridConnectionName
    relayArmUri: hybridConnectionResourceId
    hostname: split(json(reference(hybridConnectionResourceId, '2017-04-01').userMetadata)[0].value, ':')[0]
    port: int(split(json(reference(hybridConnectionResourceId, '2017-04-01').userMetadata)[0].value, ':')[1])
    sendKeyName: 'defaultSender'
    sendKeyValue: listkeys('${hybridConnectionResourceId}/authorizationRules/defaultSender', '2017-04-01').primaryKey
  }
  dependsOn: [
    webAppName_staging
  ]
}
