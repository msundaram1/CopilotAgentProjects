// Parameters file for main.bicep – Platform Logs Collection using DCR and DCRA
// Replace the placeholder values (marked with <...>) with your actual resource IDs.

using 'main.bicep'

param dcrName = 'dcr-platform-logs'
param location = 'eastus'

param logAnalyticsWorkspaceResourceId = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>'
param storageAccountResourceId = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>'
param eventHubNamespaceResourceId = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.EventHub/namespaces/<eventhub-namespace-name>'

param eventHubName = 'platform-logs-hub'
param storageContainerName = 'platform-logs'

param collectWindowsEvents = true
param collectSyslog = true

param createAssociation = false
param associationName = 'dcra-platform-logs'
param targetResourceId = ''

param tags = {
  purpose: 'platform-logs-collection'
  managedBy: 'azure-monitor'
  environment: 'production'
}
