targetScope = 'subscription'

/*
Network-Secured Agent Architecture Overview
-----------------------------------------
This template deploys an AI agent infrastructure in a network-secured configuration:

1. Network Security:
   - All services are deployed with private endpoints
   - Access is restricted through VNet integration
   - Private DNS zones manage internal name resolution

2. Key Network Components:
   - Virtual Network: Isolated network environment for all resources
   - Subnets: Segregated network spaces for different service types
   - Private Endpoints: Secure access points for Azure services
   - Private DNS Zones: Internal name resolution for private endpoints

3. Security Design:
   - No public internet exposure for core services
   - Network isolation between components
   - Managed identity for secure authentication
*/

// Existing Resource Overrides - Used when connecting to pre-existing resources
var keyVaultOverride = ''       // Override for existing Key Vault
var userAssignedIdentityOverride = '' // Override for existing managed identity

/* ---------------------------------- Deployment Identifiers ---------------------------------- */

param name string = 'network-secured-agent'

// Create a short, unique suffix, that will be unique to each resource group
param deploymentTimestamp string = utcNow('yyyyMMddHHmmss')
param uniqueSuffix string = substring(uniqueString('${subscription().id}-${deploymentTimestamp}'), 0, 4)

/* ---------------------------------- Default Parameters if Overrides Not Set ---------------------------------- */
param rgGroupName string = '${name}-rg'


// Parameters
@minLength(2)
@maxLength(12)
@description('Name for the AI resource and used to derive name of dependent resources.')
param defaultAiHubName string = 'hub-demo'

@description('Friendly name for your Hub resource')
param defaultAiHubFriendlyName string = 'Agents Hub resource'

@description('Description of your Azure AI resource displayed in AI studio')
param defaultAiHubDescription string = 'This is an example AI resource for use in Azure AI Studio.'

@description('Name for the AI project resources.')
param defaultAiProjectName string = 'project-demo'

@description('Friendly name for your Azure AI resource')
param defaultAiProjectFriendlyName string = 'Agents Project resource'

@description('Specifies the public network access for the Azure AI Hub workspace.')
@allowed([
  'Disabled'
  'Enabled'
])
param hubPublicNetworkAccess string = 'Disabled'

@description('Specifies the public network access for the Azure AI Project workspace.Note: Please ensure that if you are setting this to Enabled, the AI Hub workspace is also set to Enabled.')
@allowed([
  'Disabled'
  'Enabled'
])
param projectPublicNetworkAccess string = hubPublicNetworkAccess


@description('Description of your Azure AI resource displayed in AI studio')
param defaultAiProjectDescription string = 'This is an example AI Project resource for use in Azure AI Studio.'

@description('Resource group location')
param resourceGroupLocation string = 'eastus2'

@allowed([
  'australiaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'japaneast'
  'norwayeast'
  'southindia'
  'swedencentral'
  'uaenorth'
  'uksouth'
  'westus'
  'westus3'
])
@description('Location for all resources.')
param location string = resourceGroupLocation

@description('Set of tags to apply to all resources.')
param tags object = {}

@description('Name of the Azure AI Search account')
param defaultAiSearchName string = 'agent-ai-search'

@description('Name for capabilityHost.')
param defaultCapabilityHostName string = 'caphost1'

@description('Name of the storage account')
param defaultStorageName string = 'agentstorage'

@description('Name of the Azure AI Services account')
param defaultAiServicesName string = 'agent-ai-service'

@description('Model name for deployment')
param modelName string = 'gpt-4o-mini'

@description('Model format for deployment')
param modelFormat string = 'OpenAI'

@description('Model version for deployment')
param modelVersion string = '2024-07-18'

@description('Model deployment SKU name')
param modelSkuName string = 'GlobalStandard'

@description('Model deployment capacity')
param modelCapacity int = 50

@description('Model deployment location. If you want to deploy an Azure AI resource/model in different location than the rest of the resources created.')
param modelLocation string = resourceGroupLocation

@description('AI service kind, values can be "OpenAI" or "AIService"')
param aisKind string = 'AIServices'

@description('The AI Service Account name. This is an optional field, and if not provided, the resource will be created. The resource should exist in same resource group')
param aiServiceAccountName string = ''

@description('The AI Search Service name. This is an optional field, and if not provided, the resource will be created.The resource should exist in same resource group must be Public Network Disabled')
param aiSearchServiceName string = ''

// VNET
@description('If you provide this is will be used instead of creating a new VNET')
param existingVnetName string = ''
@description('The name of the resource group where the existing VNET is located. As of 3/13/2025 the resource group has to match the hub resource group.')
param existingVnetResourceGroup string = ''
@description('The name of Agents Subnet. As of 3/13/2025 the address space of the subnet has to be either 172 or 192.')
param agentsSubnetName string = ''
@description('The name of Customer Hub subnet.')
param hubSubnetName string = ''

@description('When true, the module will create private DNS zones and link them to the VNet. When false, it will not create any DNS zones.')
param createDnsZones bool = true

var vnetResourceGroupName = !empty(existingVnetResourceGroup) ? existingVnetResourceGroup : rgGroupName

// @description('The Ai Storage Account name. This is an optional field, and if not provided, the resource will be created.The resource should exist in same resource group')
// param aiStorageAccountName string = ''

/* ---------------------------------- Create User Assigned Identity ---------------------------------- */

@description('The name of User Assigned Identity')
param userAssignedIdentityDefaultName string = 'secured-agents-identity-${uniqueSuffix}'
var uaiName = (userAssignedIdentityOverride == '') ? userAssignedIdentityDefaultName : userAssignedIdentityOverride

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgGroupName
  location: resourceGroupLocation
}

module identity 'modules-network-secured/network-secured-identity.bicep' = {
  name: '${name}-${uniqueSuffix}--identity'
  scope: rg
  params: {
    location: location
    userAssignedIdentityName: uaiName
    uaiExists: userAssignedIdentityOverride != ''
  }
}

/* ---------------------------------- Create AI Assistant Dependent Resources ---------------------------------- */

// var storageName = empty(aiStorageAccountName) ? '${defaultStorageName}${uniqueSuffix}' : aiStorageAccountName
var keyVaultName = empty(keyVaultOverride) ? 'kv-${defaultAiHubName}-${uniqueSuffix}' : keyVaultOverride
var aiServiceName = empty(aiServiceAccountName) ? '${defaultAiServicesName}${uniqueSuffix}' : aiServiceAccountName
var aiSearchName = empty(aiSearchServiceName) ? '${defaultAiSearchName}${uniqueSuffix}' : aiSearchServiceName

var storageNameClean = '${defaultStorageName}${uniqueSuffix}'

// Create Virtual Network and Subnets
module vnet 'modules-network-secured/networking/vnet.bicep' = {
  name: '${name}-${uniqueSuffix}--vnet'
  scope: rg
  params: {
    existingVirtualNetworkName: existingVnetName
    existingVirtualNetworkResourceGroup: existingVnetResourceGroup
    hubSubnetName: hubSubnetName
    agentsSubnetName: agentsSubnetName
    location: location
    tags: tags
    suffix: uniqueSuffix
  }
  dependsOn: [
    identity
  ]
}

// Dependent resources for the Azure Machine Learning workspace
module aiDependencies 'modules-network-secured/network-secured-dependent-resources.bicep' = {
  name: '${name}-${uniqueSuffix}--dependencies'
  scope: rg
  params: {
    suffix: uniqueSuffix
    storageName: storageNameClean
    keyvaultName: keyVaultName
    aiServicesName: aiServiceName
    aiSearchName: aiSearchName
    tags: tags
    location: location
    aisKind: aisKind

    aiServicesExists: !empty(aiServiceAccountName)
    aiSearchExists: !empty(aiSearchServiceName)

     // Model deployment parameters
     modelName: modelName
     modelFormat: modelFormat
     modelVersion: modelVersion
     modelSkuName: modelSkuName
     modelCapacity: modelCapacity
     modelLocation: modelLocation
     // User-assigned managed identity
     userAssignedIdentityName: identity.outputs.uaiName
    }
}



module aiHub 'modules-network-secured/network-secured-ai-hub.bicep' = {
  name: '${name}-${uniqueSuffix}--hub'
  scope: rg
  params: {
    // workspace organization
    aiHubName: '${defaultAiHubName}-${uniqueSuffix}'
    aiHubFriendlyName: defaultAiHubFriendlyName
    aiHubDescription: defaultAiHubDescription
    location: location
    tags: tags

    aiSearchName: aiDependencies.outputs.aiSearchName
    aiSearchId: aiDependencies.outputs.aisearchID
    aiSearchServiceResourceGroupName: aiDependencies.outputs.aiSearchServiceResourceGroupName
    aiSearchServiceSubscriptionId: aiDependencies.outputs.aiSearchServiceSubscriptionId

    aiServicesName: aiDependencies.outputs.aiServicesName
    aiServicesId: aiDependencies.outputs.aiservicesID
    aiServicesTarget: aiDependencies.outputs.aiservicesTarget
    aiServiceAccountResourceGroupName:aiDependencies.outputs.aiServiceAccountResourceGroupName
    aiServiceAccountSubscriptionId:aiDependencies.outputs.aiServiceAccountSubscriptionId

    keyVaultId: aiDependencies.outputs.keyvaultId
    storageAccountId: aiDependencies.outputs.storageId

    uaiName: identity.outputs.uaiName
    publicNetworkAccess: hubPublicNetworkAccess // Public network access for the workspace
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: aiDependencies.outputs.storageAccountName
  scope: rg
}

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiDependencies.outputs.aiServicesName
  scope: resourceGroup(aiDependencies.outputs.aiServiceAccountSubscriptionId, aiDependencies.outputs.aiServiceAccountResourceGroupName)
}

resource aiSearch 'Microsoft.Search/searchServices@2023-11-01' existing = {
  name: aiDependencies.outputs.aiSearchName
  scope: resourceGroup(aiDependencies.outputs.aiSearchServiceSubscriptionId, aiDependencies.outputs.aiSearchServiceResourceGroupName)
}

// Private Endpoint and DNS Configuration
// This module sets up private network access for all Azure services:
// 1. Creates private endpoints in the specified subnet
// 2. Sets up private DNS zones for each service:
//    - privatelink.search.windows.net for AI Search
//    - privatelink.cognitiveservices.azure.com for AI Services
//    - privatelink.blob.core.windows.net for Storage
// 3. Links private DNS zones to the VNet for name resolution
// 4. Configures network policies to restrict access to private endpoints only
module privateEndpointAndDNS 'modules-network-secured/private-endpoint-and-dns.bicep' = {
  name: '${name}-${uniqueSuffix}--private-endpoint'
  scope: rg
  params: {
    aiServicesName: aiDependencies.outputs.aiServicesName    // AI Services to secure
    aiSearchName: aiDependencies.outputs.aiSearchName        // AI Search to secure
    aiStorageId: aiDependencies.outputs.storageId           // Storage to secure
    storageName: storageNameClean                           // Clean storage name for DNS
    vnetName: vnet.outputs.virtualNetworkName    // VNet containing subnets
    vnetResourceGroupName: vnetResourceGroupName // Resource group for VNet
    cxSubnetName: vnet.outputs.hubSubnetName        // Subnet for private endpoints
    suffix: uniqueSuffix                                    // Unique identifier
    hubWorkspaceId: aiHub.outputs.aiHubID                   // AI Hub workspace ID
    hubWorkspaceName: aiHub.outputs.aiHubName               // AI Hub workspace name
    createDnsZones: createDnsZones // Flag to create DNS zones
  }
  dependsOn: [
    aiServices    // Ensure AI Services exist
    aiSearch      // Ensure AI Search exists
    storage       // Ensure Storage exists
  ]
}

module aiProject 'modules-network-secured/network-secured-ai-project.bicep' = {
  name: '${name}-${uniqueSuffix}--project'
  scope: rg
  params: {
    // workspace organization
    aiProjectName: '${defaultAiProjectName}-${uniqueSuffix}'
    aiProjectFriendlyName: defaultAiProjectFriendlyName
    aiProjectDescription: defaultAiProjectDescription
    location: location
    tags: tags
    aiHubId: aiHub.outputs.aiHubID
    uaiName: identity.outputs.uaiName
    publicNetworkAccess: projectPublicNetworkAccess // Public network access for the workspace
  }
  dependsOn: [
    privateEndpointAndDNS
  ]
}

module aiServiceRoleAssignments 'modules-network-secured/ai-service-role-assignments.bicep' = {
  name: '${name}-${uniqueSuffix}--AiServices-RA'
  scope: rg
  params: {
    aiServicesName: aiDependencies.outputs.aiServicesName
    aiProjectPrincipalId: identity.outputs.uaiPrincipalId
    aiProjectId: aiProject.outputs.aiProjectResourceId
  }
}

module aiSearchRoleAssignments 'modules-network-secured/ai-search-role-assignments.bicep' = {
  name: '${name}-${uniqueSuffix}--AiSearch-RA'
  scope: rg
  params: {
    aiSearchName: aiDependencies.outputs.aiSearchName
    aiProjectPrincipalId: identity.outputs.uaiPrincipalId
    aiProjectId: aiProject.outputs.aiProjectResourceId
  }
}

module addCapabilityHost 'modules-network-secured/network-capability-host.bicep' = {
  name: '${name}-${uniqueSuffix}--capability-host'
  scope: rg
  params: {
    capabilityHostName: '${uniqueSuffix}-${defaultCapabilityHostName}'
    aiHubName: aiHub.outputs.aiHubName
    aiProjectName: aiProject.outputs.aiProjectName
    acsConnectionName: aiHub.outputs.acsConnectionName
    aoaiConnectionName: aiHub.outputs.aoaiConnectionName
    customerSubnetId: vnet.outputs.agentsSubnetId
  }
  dependsOn: [
    aiSearchRoleAssignments, aiServiceRoleAssignments
  ]
}

var projectConnectionString =  aiProject.outputs.projectConnectionString
var parts = split(projectConnectionString, ';')
var projectHost = parts[0]
var subscriptionId = parts[1]
var resourceGroupName = parts[2]
var projectName = parts[3]
var privateProjectHost = '${aiProject.outputs.aiProjectWorkspaceId}.workspace.${projectHost}'
output PROJECT_CONNECTION_STRING string =  hubPublicNetworkAccess == 'Enabled' ? aiProject.outputs.projectConnectionString : '${privateProjectHost};${subscriptionId};${rgGroupName};${projectName}'
