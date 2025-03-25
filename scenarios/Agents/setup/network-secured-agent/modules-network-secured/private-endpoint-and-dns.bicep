/*
Private Endpoint and DNS Configuration Module
------------------------------------------
This module configures private network access for Azure services using:

1. Private Endpoints:
   - Creates network interfaces in the specified subnet
   - Establishes private connections to Azure services
   - Enables secure access without public internet exposure

2. Private DNS Zones:
   - privatelink.azureml.ms for AI Services
   - privatelink.search.windows.net for AI Search
   - privatelink.blob.core.windows.net for Storage
   - Enables custom DNS resolution for private endpoints

3. DNS Zone Links:
   - Links private DNS zones to the VNet
   - Enables name resolution for resources in the VNet
   - Prevents DNS resolution conflicts

Security Benefits:
- Eliminates public internet exposure
- Enables secure access from within VNet
- Prevents data exfiltration through network
*/

// Resource names and identifiers
@description('Name of the AI Services account')
param aiServicesName string
@description('Name of the AI Search service')
param aiSearchName string
@description('Name of the storage account')
param storageName string
@description('Name of the Vnet')
param vnetName string
@description('Name of the Vner Resource Group')
param vnetResourceGroupName string = resourceGroup().name
@description('Name of the Customer subnet')
param cxSubnetName string
@description('Suffix for unique resource names')
param suffix string
@description('Name of the AI Storage Account')
param aiStorageId string

@description('Specifies the resource id of the Azure Hub Workspace.')
param hubWorkspaceId string

@description('Name of the Customer Hub Workspace')
@secure()
param hubWorkspaceName string

@description('Name of the resource group for the AI dependent services')
param aiResourceGroupName string = resourceGroup().name

param createDnsZones bool = true

// Reference existing services that need private endpoints
resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiServicesName
  scope: resourceGroup(aiResourceGroupName)
}

resource aiSearch 'Microsoft.Search/searchServices@2023-11-01' existing = {
  name: aiSearchName
  scope: resourceGroup(aiResourceGroupName)
}

// Reference existing network resources
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}

resource cxSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: cxSubnetName
}

/* -------------------------------------------- AI Services Private Endpoint -------------------------------------------- */

// Private endpoint for AI Services
// - Creates network interface in customer hub subnet
// - Establishes private connection to AI Services account
resource aiServicesPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${aiServicesName}-${suffix}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: cxSubnet.id // Deploy in customer hub subnet
    }
    privateLinkServiceConnections: [
      {
        name: '${aiServicesName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: aiServices.id
          groupIds: [
            'account' // Target AI Services account
          ]
        }
      }
    ]
  }
}

resource aiServiceOpenAiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${aiServicesName}-${suffix}-openAi-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: cxSubnet.id // Deploy in customer hub subnet
    }
    privateLinkServiceConnections: [
      {
        name: '${aiServicesName}-openAi-private-link-service-connection'
        properties: {
          privateLinkServiceId: aiServices.id
          groupIds: [
            'account' // Target AI Services account
          ]
        }
      }
    ]
  }
}

/* -------------------------------------------- AI Search Private Endpoint -------------------------------------------- */

// Private endpoint for AI Search
// - Creates network interface in customer hub subnet
// - Establishes private connection to AI Search service
resource aiSearchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${aiSearchName}-${suffix}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: cxSubnet.id // Deploy in customer hub subnet
    }
    privateLinkServiceConnections: [
      {
        name: '${aiSearchName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: aiSearch.id
          groupIds: [
            'searchService' // Target search service
          ]
        }
      }
    ]
  }
}

/* -------------------------------------------- Storage Private Endpoint -------------------------------------------- */

// Private endpoint for Storage Account
// - Creates network interface in customer hub subnet
// - Establishes private connection to blob storage
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${storageName}-${suffix}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: cxSubnet.id // Deploy in customer hub subnet
    }
    privateLinkServiceConnections: [
      {
        name: '${storageName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: aiStorageId
          groupIds: [
            'blob' // Target blob storage
          ]
        }
      }
    ]
  }
}

/*----------------------------------------------Hub Workspace Kind---------------------------------------------*/
resource hubWorkspacePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${hubWorkspaceName}-${suffix}-private-endpoint'
  location: resourceGroup().location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${hubWorkspaceName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: hubWorkspaceId
          groupIds: [
            'amlworkspace'
          ]
        }
      }
    ]
    subnet: {
      id: cxSubnet.id
    }
  }
}

/* -------------------------------------------- Private DNS Zones -------------------------------------------- */

// Private DNS Zone for AI Services
// - Enables custom DNS resolution for AI Services private endpoint
resource aiServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createDnsZones) {
  name: 'privatelink.azureml.ms' // Standard DNS zone for AI Services
  location: 'global'
}

resource openAiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createDnsZones) {
  name: 'privatelink.openai.azure.com'
  location: 'global'
}

// DNS Zone Group for AI Services
resource aiServicesDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (createDnsZones) {
  parent: aiServicesPrivateEndpoint
  name: '${aiServicesName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${aiServicesName}-dns-config'
        properties: {
          privateDnsZoneId: aiServicesPrivateDnsZone.id
        }
      }
    ]
  }
}

// DNS Zone Group for Azure OpenAI
resource aiOpenAIDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (createDnsZones) {
  parent: aiServiceOpenAiPrivateEndpoint
  name: '${aiServicesName}-openAi-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${aiServicesName}-openAi-dns-config'
        properties: {
          privateDnsZoneId: openAiPrivateDnsZone.id
        }
      }
    ]
  }
}

// Private DNS Zone for AI Hub
// - Enables custom DNS resolution for AI Hub private endpoint
resource mlApiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createDnsZones) {
  name: 'privatelink.api.azureml.ms'
  location: 'global'
}

resource mlNotebooksPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createDnsZones) {
  name: 'privatelink.notebooksazureml.net'
  location: 'global'
}

resource hubWorkspacePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (createDnsZones) {
  parent: hubWorkspacePrivateEndpoint
  name: '${hubWorkspaceName}-mlApiNotebook-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${hubWorkspaceName}-mlApi-dns-config'
        properties: {
          privateDnsZoneId: mlApiPrivateDnsZone.id
        }
      }
      {
        name: '${hubWorkspaceName}-mlNotebook-dns-config'
        properties: {
          privateDnsZoneId: mlNotebooksPrivateDnsZone.id
        }
      }
    ]
  }
}

// Private DNS Zone for AI Search
// - Enables custom DNS resolution for AI Search private endpoint
resource aiSearchPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createDnsZones) {
  name: 'privatelink.search.windows.net' // Standard DNS zone for AI Search
  location: 'global'
}

// DNS Zone Group for AI Search
resource aiSearchDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (createDnsZones) {
  parent: aiSearchPrivateEndpoint
  name: '${aiSearchName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${aiSearchName}-dns-config'
        properties: {
          privateDnsZoneId: aiSearchPrivateDnsZone.id
        }
      }
    ]
  }
}

// Private DNS Zone for Storage
// - Enables custom DNS resolution for blob storage private endpoint
resource storagePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createDnsZones) {
  name: 'privatelink.blob.${environment().suffixes.storage}' // Dynamic DNS zone for storage
  location: 'global'
}

// DNS Zone Group for Storage
resource storageDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (createDnsZones) {
  parent: storagePrivateEndpoint
  name: '${storageName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storageName}-dns-config'
        properties: {
          privateDnsZoneId: storagePrivateDnsZone.id
        }
      }
    ]
  }
}

module dnsZoneLinks 'dns-zone-links.bicep' = if (createDnsZones) {
  name: 'dns-zone-links-for-${vnetName}'
  scope: resourceGroup(vnetResourceGroupName)
  params: {
    vnetName: vnetName
    vnetResourceGroupName: vnetResourceGroupName
    suffix: suffix
  }
  dependsOn: [
    aiServicesPrivateDnsZone
    openAiPrivateDnsZone
    mlApiPrivateDnsZone
    mlNotebooksPrivateDnsZone
    aiSearchPrivateDnsZone
    storagePrivateDnsZone
  ]
}
