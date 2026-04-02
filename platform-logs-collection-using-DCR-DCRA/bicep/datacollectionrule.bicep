@description('Name of the Data Collection Rule.')
param dcrName string

@description('Azure region where the DCR will be deployed.')
param location string = resourceGroup().location

@description('Full resource ID of the Log Analytics Workspace destination.')
param logAnalyticsWorkspaceResourceId string

@description('Full resource ID of the Storage Account destination.')
param storageAccountResourceId string

@description('Full resource ID of the Event Hub Namespace destination.')
param eventHubNamespaceResourceId string

@description('Optional: specific Event Hub name within the namespace. Leave empty to use the default.')
param eventHubName string = ''

@description('Storage container name for platform logs.')
param storageContainerName string = 'platform-logs'

@description('Whether to collect Windows Security and System event logs.')
param collectWindowsEvents bool = true

@description('Whether to collect Linux Syslog data.')
param collectSyslog bool = true

@description('Resource tags to apply to the DCR.')
param tags object = {}

var logAnalyticsDestinationName = 'law-destination'
var storageDestinationName = 'storage-destination'
var eventHubDestinationName = 'eventhub-destination'

var windowsEventLogSource = [
  {
    streams: ['Microsoft-Event']
    xPathQueries: [
      'Security!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=5)]]'
      'System!*[System[(Level=1 or Level=2 or Level=3)]]'
      'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
    ]
    name: 'windows-event-logs'
  }
]

var syslogSource = [
  {
    streams: ['Microsoft-Syslog']
    facilityNames: ['auth', 'authpriv', 'cron', 'daemon', 'kern', 'syslog', 'user']
    logLevels: ['Error', 'Critical', 'Alert', 'Emergency', 'Warning']
    name: 'linux-syslog'
  }
]

resource dcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: dcrName
  location: location
  tags: tags
  properties: {
    description: 'Data Collection Rule for collecting platform logs and sending to Log Analytics, Storage Account, and Event Hub.'
    dataSources: {
      windowsEventLogs: collectWindowsEvents ? windowsEventLogSource : []
      syslog: collectSyslog ? syslogSource : []
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspaceResourceId
          name: logAnalyticsDestinationName
        }
      ]
      storageAccounts: [
        {
          storageAccountResourceId: storageAccountResourceId
          containerName: storageContainerName
          name: storageDestinationName
        }
      ]
      eventHubs: [
        {
          eventHubResourceId: eventHubNamespaceResourceId
          eventHubName: empty(eventHubName) ? null : eventHubName
          name: eventHubDestinationName
        }
      ]
    }
    dataFlows: [
      {
        streams: ['Microsoft-Event']
        destinations: [
          logAnalyticsDestinationName
          storageDestinationName
          eventHubDestinationName
        ]
        transformKql: 'source'
        outputStream: 'Microsoft-Event'
      }
      {
        streams: ['Microsoft-Syslog']
        destinations: [
          logAnalyticsDestinationName
          storageDestinationName
          eventHubDestinationName
        ]
        transformKql: 'source'
        outputStream: 'Microsoft-Syslog'
      }
    ]
  }
}

@description('Resource ID of the created Data Collection Rule.')
output dcrResourceId string = dcr.id

@description('Immutable ID of the Data Collection Rule.')
output dcrImmutableId string = dcr.properties.immutableId

@description('Name of the Data Collection Rule.')
output dcrName string = dcr.name
