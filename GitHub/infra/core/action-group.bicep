// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/action-group.bicep"  --name "bicep-actiongroup-$(Get-Date -Format 'yyyyMMddHHmmss')"
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/action-group.bicep"  --name "bicep-actiongroup-$(date '+%Y%m%d%H%M%S')"

var actionGroupNotifyEmailName = 'Notify Email'
var actionGroupNotifyEmailEmail = 'dev-alert-notifications@domain.ab.ca'

resource actionGroupNotifyEmail 'Microsoft.Insights/actionGroups@2023-01-01' = {
  location: 'Global'
  name: actionGroupNotifyEmailName
  properties: {
    armRoleReceivers: []
    automationRunbookReceivers: []
    azureAppPushReceivers: []
    azureFunctionReceivers: []
    emailReceivers: [
      {
        emailAddress: actionGroupNotifyEmailEmail
        name: 'Email _-EmailAction-'
        useCommonAlertSchema: false
      }
    ]
    enabled: true
    eventHubReceivers: []
    groupShortName: actionGroupNotifyEmailName
    itsmReceivers: []
    logicAppReceivers: []
    smsReceivers: []
    voiceReceivers: []
    webhookReceivers: []
  }
}
