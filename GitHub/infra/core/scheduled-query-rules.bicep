// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/scheduled-query-rules.bicep"  --name "bicep-scheduledqueryrules-$(Get-Date -Format 'yyyyMMddHHmmss')"
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/scheduled-query-rules.bicep"  --name "bicep-scheduledqueryrules-$(date '+%Y%m%d%H%M%S')"

@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location

var scheduledQueryRulesCustomErrorName = 'errors'
var scheduleQueryRulesCustomErrorQuery = 'requests\n| where resultCode == 500\n    and url has_any ("apiUrl1", "apiUrl2", "apiUrl3")'
var actionGroupName = 'Notify Email Group'
var actionGroupNotifyEmailId = resourceId('Microsoft.Insights/actionGroups', actionGroupName)

var abbrs = loadJsonContent('../abbreviations.json')

var appInsightsName = '${abbrs.insightsComponents}-mingz-${environmentName}'
var appInsightsId = resourceId('Microsoft.Insights/components', appInsightsName)

resource scheduledQueryRulesCustomError 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  location: location
  name: scheduledQueryRulesCustomErrorName
  properties: {
    actions: {
      actionGroups: [
        actionGroupNotifyEmailId
      ]
      customProperties: {}
    }
    autoMitigate: false
    criteria: {
      allOf: [
        {
          dimensions: []
          failingPeriods: {
            minFailingPeriodsToAlert: 1
            numberOfEvaluationPeriods: 1
          }
          operator: 'GreaterThan'
          query: scheduleQueryRulesCustomErrorQuery
          threshold: 0
          timeAggregation: 'Count'
        }
      ]
    }
    description: 'Alert when an error occurs during a Custom operation'
    displayName: scheduledQueryRulesCustomErrorName
    enabled: true
    evaluationFrequency: 'PT1H'
    scopes: [
      appInsightsId
    ]
    severity: 1
    targetResourceTypes: [
      'microsoft.insights/components'
    ]
    windowSize: 'PT1H'
  }
}
