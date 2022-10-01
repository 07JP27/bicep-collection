param appServiceAppName string = 'toylaunch-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location

@allowed([
  'nonprod'
  'prod'
])
param environmentType string

var appServicePlanName = 'toylaunch-${uniqueString(resourceGroup().id)}-plan'
var appServicePlanSkuName = (environmentType == 'prod') ? 'P2v3' : 'F1'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  location: location
  name:appServicePlanName
  sku:{
    name: appServicePlanSkuName
  }
}

resource appServiceApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceAppName
  location: location
  properties:{
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}
