// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/app-service-plan.bicep" --name ("bicep-appserviceplan-" + (Get-Date -Format 'yyyyMMddHHmmss')) --parameters environmentName='<YourEnv>'
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/app-service-plan.bicep" --name "bicep-appserviceplan-$(date '+%Y%m%d%H%M%S')" --parameters environmentName='<YourEnv>'

@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location

var abbrs = loadJsonContent('../abbreviations.json')

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${abbrs.webServerFarms}-mingz-${environmentName}'
  location: location
  sku: {
    name: 'P2v2'
    tier: 'PremiumV2'
    size: 'P2v2'
    family: 'Pv2'
    capacity: 1
  }
  kind: 'app'
  properties: {
    perSiteScaling: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}
