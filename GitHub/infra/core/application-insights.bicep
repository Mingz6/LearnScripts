// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/application-insights.bicep" --name "bicep-appinsights-$(Get-Date -Format 'yyyyMMddHHmmss')"
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/application-insights.bicep" --name "bicep-appinsights--$(date '+%Y%m%d%H%M%S')"

@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location
param tags object = {
  Application: 'myapp'
  Environment: environmentName
}

var abbrs = loadJsonContent('../abbreviations.json')
var logAnalyticsWorkspaceName = environmentName == 'prod' ? 'log-mingz' : 'log-mingz-${environmentName}' 

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${abbrs.insightsComponents}-mingz-${environmentName}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: resourceId('<shared-resources-group>','Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName)
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaWebAppExtensionCreate'
    RetentionInDays: 90
  }
}

output applicationInsightsId string = applicationInsights.id
output instrumentationKey string = applicationInsights.properties.InstrumentationKey
