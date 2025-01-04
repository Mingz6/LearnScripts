// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription "<subscription-name>" --template-file "./core/key-vault.bicep" --name "bicep-keyvault-$(Get-Date -Format 'yyyyMMddHHmmss')"
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription "<subscription-name>" --template-file "./core/key-vault.bicep" --name "bicep-keyvault-$(date '+%Y%m%d%H%M%S')"

@minLength(2)
@maxLength(60)

@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param location string = resourceGroup().location
param tags object = {
  Application: 'myapp'
  Environment: environmentName
}

var buildTeamObjectId = '08504c53-8cdb-4653-b596-0d3803960212'
var abbrs = loadJsonContent('../abbreviations.json')
var base = 'mingz'

// Add more func apps name here.
var myFuncAppName = '${abbrs.webSitesFunctions}-${base}-myfuncapp-${environmentName}'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${abbrs.keyVaultVaults}-${base}-${environmentName}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    accessPolicies: [ ]
  }
}

resource AuthAppKeyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: buildTeamObjectId
        permissions: {
          keys: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
          ]
          secrets: [
            'Get'
            'List'
            'Set'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
          ]
          certificates: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'ManageContacts'
            'ManageIssuers'
            'GetIssuers'
            'ListIssuers'
            'SetIssuers'
            'DeleteIssuers'
          ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: reference(resourceId('Microsoft.Web/Sites/', myFuncAppName), '2018-11-01', 'Full').identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

output resourceId string = keyVault.id
