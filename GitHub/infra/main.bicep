// To deploy this template, run the following command:
// az deployment group create --resource-group <resource-group> --subscription "<subscription-name>" --template-file "./main.bicep" --name "main-bicep"

@secure()
@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location
param currentDate string = utcNow('yyyyMMddHHmmss')

var abbrs = loadJsonContent('./abbreviations.json')

var base = 'mingz'

module appServicePlan './core/app-service-plan.bicep' = {
  name: '${abbrs.webServerFarms}-${base}-${environmentName}-${currentDate}'
  params: {
    environmentName: environmentName
    location: location
  }
}

module appInsights './core/application-insights.bicep' = {
  name: '${abbrs.insightsComponents}-${base}-${environmentName}-${currentDate}'
  params: {
    environmentName: environmentName
    location: location
  }
}

// TODO: need to fix this access policies issue, when executing kv update.
// Skipping keyvault deployment, because currently there's no good ways to not updating 
// access policies every time and cause interruptions to the resources.
// module keyVault './core/key-vault.bicep' = {
//   name: '${abbrs.keyVaultVaults}-{$base}-${environmentName}-${currentDate}'
//   params: {
//     environmentName: environmentName
//     location: location
//   }
// }

module storageAccount './core/storage-account.bicep' = {
  name: '${abbrs.storageStorageAccounts}-${base}-${environmentName}-${currentDate}'
  params: {
    environmentName: environmentName
    location: location
  }
}

module storageAccountSetStaticWeb './core/storage-account-setstaticweb.bicep' = {
  name: '${abbrs.storageStorageAccounts}-setstaticweb-${base}-${environmentName}-${currentDate}'
  params: {
    environmentName: environmentName
    location: location
  }
}

module actionGroup './core/action-group.bicep' = { name: '${abbrs.insightsActionGroups}-${base}-${environmentName}-${currentDate}' }

module scheduledQueryRules './core/scheduled-query-rules.bicep' = {
  name: 'Error-${base}-${environmentName}-${currentDate}'
    params: {
    environmentName: environmentName
    location: location
  }
}

var cdnParamsContent = loadTextContent('./core/params/cdn-profiles-params.json')
var cdnParamsObject = json(cdnParamsContent).parameters
module cdnProfiles './core/cdn-profiles.bicep' = {
  name: '${abbrs.cdnProfiles}-${base}-${environmentName}-${currentDate}'
    params: {
    environmentName: environmentName
    cdnProfilesParams: cdnParamsObject.cdnProfilesParams.value
  }
}

var paramsContent = loadTextContent('./core/params/app-service-params.json')
var paramsObject = json(paramsContent).parameters
module webApp './core/app-service.bicep' = {
  name: '${abbrs.webSitesAppService}-${base}-${environmentName}-${currentDate}'
  params: {
    targetWebAppName: 'firstWebApp'
    webAppProfiles: paramsObject.webAppProfiles.value
    location: location
    environmentName: environmentName
    myFirstParams: paramsObject.myFirstParams.value
    mySecondParams: paramsObject.mySecondParams.value
  }
}

module secondiceWebApp './core/app-service.bicep' = {
  name: '${abbrs.webSitesAppService}-secondice-${base}-${environmentName}-${currentDate}'
  params: {
    targetWebAppName: 'secondWebApp'
    webAppProfiles: paramsObject.webAppProfiles.value
    location: location
    environmentName: environmentName
    myFirstParams: paramsObject.myFirstParams.value
    mySecondParams: paramsObject.mySecondParams.value
  }
}

// Start of the function apps
var myappParamsContent = loadTextContent('./main-stack/params/func-app-myapp-params.json')
var myappParamsObject = json(myappParamsContent).parameters
module myappAzureFunctions './main-stack/func-app-myapp.bicep' = {
  name: '${abbrs.webSitesFunctions}-${base}-myapp-${environmentName}-${currentDate}'
  params: {
    environmentName: environmentName
    location: location
    myFirstParams: myappParamsObject.myFirstParams.value
    mySecondParams: myappParamsObject.mySecondParams.value
  }
}


// TODO: Add more func apps here.
// ......
// End of the function apps
