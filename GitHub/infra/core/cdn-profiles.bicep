// To deploy this, run the following command:
// For Windows:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/cdn-profiles.bicep" --parameters "./core/params/cdn-profiles-params.json" --name "bicep-cdnprofiles-$(Get-Date -Format 'yyyyMMddHHmmss')"
// For MacOS:
// az deployment group create --resource-group <resource-group> --subscription '<subscription-name>' --template-file "./core/cdn-profiles.bicep" --parameters "./core/params/cdn-profiles-params.json" --name "bicep-cdnprofiles-$(date '+%Y%m%d%H%M%S')"

@secure()
@allowed([ 'dev', 'test', 'prod' ])
param environmentName string
param tags object = {
  Application: 'myapp'
  Environment: environmentName
}
var cdnWebApplicationFirewallPolicies_wafCdn_externalid = resourceId('<shared-resources-group>', 'Microsoft.Cdn/CdnWebApplicationFirewallPolicies', 'wafCdn')

param cdnProfilesParams object
param cdnProfiles array = cdnProfilesParams[environmentName]

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2022-09-01' existing =  [for (cdnProfile, index) in cdnProfiles: {
  name: cdnProfiles[index].cdnStorageAccountName
}]

// Create CND profiles serially. Change batchSize to a higher number to create them in parallel.
@batchSize(1)
resource cdnProfileResources 'Microsoft.Cdn/profiles@2022-11-01-preview' = [for (cdnProfile, index) in cdnProfiles: {
  name: cdnProfiles[index].cdnProfileName
  location: 'Global'
  tags: tags
  sku: {
    name: 'Standard_Microsoft'
  }
  properties: {}
}]

resource cdnProfileName_cdnEndpointResources 'Microsoft.Cdn/profiles/endpoints@2022-11-01-preview' = [for (cdnProfile, index) in cdnProfiles: {
  parent: cdnProfileResources[index]
  name: cdnProfiles[index].cdnEndpointName
  location: 'Global'
  tags: tags
  properties: {
    originHostHeader: replace(replace(storageAccountResource[index].properties.primaryEndpoints.web, 'https://', ''), '/', '')
    contentTypesToCompress: [
      'application/eot'
      'application/font'
      'application/font-sfnt'
      'application/javascript'
      'application/json'
      'application/opentype'
      'application/otf'
      'application/pkcs7-mime'
      'application/truetype'
      'application/ttf'
      'application/vnd.ms-fontobject'
      'application/xhtml+xml'
      'application/xml'
      'application/xml+rss'
      'application/x-font-opentype'
      'application/x-font-truetype'
      'application/x-font-ttf'
      'application/x-httpd-cgi'
      'application/x-javascript'
      'application/x-mpegurl'
      'application/x-opentype'
      'application/x-otf'
      'application/x-perl'
      'application/x-ttf'
      'font/eot'
      'font/ttf'
      'font/otf'
      'font/opentype'
      'image/svg+xml'
      'text/css'
      'text/csv'
      'text/html'
      'text/javascript'
      'text/js'
      'text/plain'
      'text/richtext'
      'text/tab-separated-values'
      'text/xml'
      'text/x-script'
      'text/x-component'
      'text/x-java-source'
    ]
    isCompressionEnabled: true
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    optimizationType: 'GeneralWebDelivery'
    origins: [
      {
        name: replace(replace(replace(storageAccountResource[index].properties.primaryEndpoints.web, 'https://', ''), '/', ''), '.', '-')
        properties: {
          hostName: replace(replace(storageAccountResource[index].properties.primaryEndpoints.web, 'https://', ''), '/', '')
          originHostHeader: replace(replace(storageAccountResource[index].properties.primaryEndpoints.web, 'https://', ''), '/', '')
          priority: 1
          weight: 1000
          enabled: true
        }
      }
    ]
    originGroups: []
    geoFilters: []
    urlSigningKeys: []
    webApplicationFirewallPolicyLink: {
      id: cdnWebApplicationFirewallPolicies_wafCdn_externalid
    }
  }
}]
