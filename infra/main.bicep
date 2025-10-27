param location string = 'australiaeast'
param namePrefix string = 'demo' 
param queueName string = 'work-items'
param sku string = 'F1'
param sbSku string = 'Standard' // Service Bus: Basic|Standard|Premium

var rgName = resourceGroup().name
var sbNamespaceName = '${namePrefix}-servicebusnamespace'
var planName = '${namePrefix}-plan'
var webAppName = '${namePrefix}-api'

resource sbNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: sbNamespaceName
  location: location
  sku: {
    name: sbSku
    tier: sbSku
  }
}

resource sbQueue 'Microsoft.ServiceBus/namespaces/queues@2024-01-01' = {
  parent: sbNamespace
  name: queueName
  properties: {
    enablePartitioning: true
    lockDuration: 'PT30S'
    maxDeliveryCount: 10
  }
}

resource sbAuth 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2024-01-01' = {
  parent: sbNamespace
  name: 'SendListen'
  properties: {
    rights: [
      'Send'
      'Listen'
    ]
  }
}

var sbConn = listKeys(resourceId('Microsoft.ServiceBus/namespaces/AuthorizationRules', sbNamespace.name, sbAuth.name), '2024-01-01').primaryConnectionString

resource plan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: planName
  location: location
  sku: {
    name: sku
    tier: 'Free'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource web 'Microsoft.Web/sites@2024-11-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      appSettings: [
        { name: 'ServiceBus__ConnectionString', value: sbConn }
        { name: 'ServiceBus__QueueName', value: queueName }
        { name: 'ASPNETCORE_URLS', value: 'http://0.0.0.0:8080' }
      ]
    }
    httpsOnly: true
  }
}

output webAppName string = web.name
output webAppUrl string = 'https://${web.name}.azurewebsites.net'
output serviceBusNamespace string = sbNamespace.name
output queue string = queueName
