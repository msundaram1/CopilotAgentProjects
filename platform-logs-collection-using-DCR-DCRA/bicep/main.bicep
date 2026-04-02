/*
  Main Bicep template – Platform Logs Collection using DCR and DCRA
  -----------------------------------------------------------------------
  This template deploys:
    - An Azure Monitor Data Collection Rule (DCR) that collects platform
      logs and sends them to a Log Analytics Workspace, Storage Account,
      and Event Hub.
    - Optionally, a Data Collection Rule Association (DCRA) linking the
      DCR to a target Azure resource (e.g., a Virtual Machine).
*/

@description('Name of the Data Collection Rule.')
param dcrName string = 'dcr-platform-logs'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Full resource ID of the Log Analytics Workspace destination.')
param logAnalyticsWorkspaceResourceId string

@description('Full resource ID of the Storage Account destination.')
param storageAccountResourceId string

@description('Full resource ID of the Event Hub Namespace destination.')
param eventHubNamespaceResourceId string

@description('Optional: specific Event Hub name within the namespace.')
param eventHubName string = ''

@description('Storage container name for platform logs.')
param storageContainerName string = 'platform-logs'

@description('Whether to collect Windows event logs.')
param collectWindowsEvents bool = true

@description('Whether to collect Linux Syslog.')
param collectSyslog bool = true

@description('Set to true to create a DCRA associating the DCR to a target resource.')
param createAssociation bool = false

@description('Name of the Data Collection Rule Association (used when createAssociation is true).')
param associationName string = 'dcra-platform-logs'

@description('Full resource ID of the target resource to associate with the DCR (used when createAssociation is true).')
param targetResourceId string = ''

@description('Resource tags to apply.')
param tags object = {
  purpose: 'platform-logs-collection'
  managedBy: 'azure-monitor'
}

// ──────────────────────────────────────────────────────────────────────────────
// Data Collection Rule
// ──────────────────────────────────────────────────────────────────────────────

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

// ──────────────────────────────────────────────────────────────────────────────
// Data Collection Rule Association (optional)
// ──────────────────────────────────────────────────────────────────────────────

// Note: DCRA must be scoped to the target resource. Because Bicep does not
// support dynamic resource scopes inline, use an extension resource pattern.
// When createAssociation = true and targetResourceId is provided, deploy the
// DCRA by referencing the existing target resource.

resource targetResource 'Microsoft.Compute/virtualMachines@2023-03-01' existing = if (createAssociation && !empty(targetResourceId)) {
  name: last(split(targetResourceId, '/'))
  scope: resourceGroup(
    split(targetResourceId, '/')[2],
    split(targetResourceId, '/')[4]
  )
}

resource dcra 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = if (createAssociation && !empty(targetResourceId)) {
  name: associationName
  scope: targetResource
  properties: {
    description: 'Association between target resource and platform logs DCR.'
    dataCollectionRuleId: dcr.id
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────────────────────────────────────

@description('Resource ID of the created Data Collection Rule.')
output dcrResourceId string = dcr.id

@description('Immutable ID of the Data Collection Rule.')
output dcrImmutableId string = dcr.properties.immutableId

@description('Name of the Data Collection Rule.')
output dcrName string = dcr.name
