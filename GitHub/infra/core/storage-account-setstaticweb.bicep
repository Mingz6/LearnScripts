// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription "<subscription-name>" --template-file './core/storage-account-setstaticweb.bicep' --name "bicep-setstaticweb-$(Get-Date -Format 'yyyyMMddHHmmss')
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription "<subscription-name>" --template-file './core/storage-account-setstaticweb.bicep' --name "bicep-setstaticweb-$(date '+%Y%m%d%H%M%S')"

@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location
param tags object = {
  Application: 'myapp'
  Environment: environmentName
}

var abbrs = loadJsonContent('../abbreviations.json')

// Add more storage account names here
param storageAccountNames array = [
  'stmingz${environmentName}'
  'stmingzsecond${environmentName}'
]

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${abbrs.managedIdentityUserAssignedIdentities}-mingz-${environmentName}'
  location: location
}

// Managed ID need storage account contributor role to execute the following script.
resource staticWebsiteScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'configureStaticWebsite'
  location: location
  tags: tags
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.28.0'
      scriptContent: format('''
          storageAccounts="{0}"
          IFS=',' read -ra ADDR <<< "$storageAccounts"
          for accountName in "${{ADDR[@]}}"; do
            az storage blob service-properties update \
              --account-name "${{accountName}}" \
              --static-website \
              --index-document index.html \
              --404-document index.html \
              --auth-mode login
          done
        ''', join(storageAccountNames, ','))

    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/<my-subscription-id>/resourcegroups/myapp-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-mingz-${environmentName}': {}
    }
  }
  dependsOn: [
    managedIdentity
  ]
}
