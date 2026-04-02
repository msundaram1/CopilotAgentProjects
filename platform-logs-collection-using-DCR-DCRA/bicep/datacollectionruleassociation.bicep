@description('Name of the Data Collection Rule Association.')
param associationName string

@description('Full resource ID of the Data Collection Rule to associate.')
param dataCollectionRuleId string

@description('Description for the Data Collection Rule Association.')
param description string = 'Association between a resource and the platform logs Data Collection Rule.'

// The scope of this resource is set externally via the targetResourceId
// Use: module dcra 'datacollectionruleassociation.bicep' = { scope: resourceGroup(subscriptionId, resourceGroupName) ... }

resource dcra 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  // The scope must be set at call site using the 'scope' property on the module
  name: associationName
  properties: {
    description: description
    dataCollectionRuleId: dataCollectionRuleId
  }
}

@description('Resource ID of the Data Collection Rule Association.')
output associationResourceId string = dcra.id

@description('Name of the Data Collection Rule Association.')
output associationName string = dcra.name
