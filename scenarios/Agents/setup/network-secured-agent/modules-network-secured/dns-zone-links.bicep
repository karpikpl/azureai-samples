/*
Only DNS to VNET links are created in this module.
*/

// Resource names and identifiers
@description('Name of the Vnet')
param vnetName string
@description('Name of the Vner Resource Group')
param vnetResourceGroupName string = resourceGroup().name
@description('Suffix for unique resource names')
param suffix string

param createDnsZones bool = true

// Reference existing network resources
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}



/* -------------------------------------------- Private DNS Zones -------------------------------------------- */

// Private DNS Zone for AI Services
// - Enables custom DNS resolution for AI Services private endpoint
resource aiServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (createDnsZones) {
  name: 'privatelink.azureml.ms'         // Standard DNS zone for AI Services
}

resource openAiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (createDnsZones) {
  name: 'privatelink.openai.azure.com'
}

// Link AI Services DNS Zone to VNet
resource aiServicesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (createDnsZones) {
  parent: aiServicesPrivateDnsZone
  location: 'global'
  name: 'aiServices-${suffix}-link-to-${vnetName}'
  properties: {
    virtualNetwork: {
      id: vnet.id                        // Link to specified VNet
    }
    registrationEnabled: false           // Don't auto-register VNet resources
  }
}

resource aiOpenAILink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (createDnsZones) {
  parent: openAiPrivateDnsZone
  location: 'global'
  name: 'aiServicesOpenAI-${suffix}-link-to-${vnetName}'
  properties: {
    virtualNetwork: {
      id: vnet.id                        // Link to specified VNet
    }
    registrationEnabled: false           // Don't auto-register VNet resources
  }
}

// Private DNS Zone for AI Hub
// - Enables custom DNS resolution for AI Hub private endpoint
resource mlApiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (createDnsZones) {
  name: 'privatelink.api.azureml.ms'
}

resource mlNotebooksPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (createDnsZones)  {
  name: 'privatelink.notebooksazureml.net'
}

// Link AI Hub DNS Zone to VNet
resource mlApiPrivateDnsZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (createDnsZones)  {
  parent: mlApiPrivateDnsZone
  name: 'mlApi-${suffix}-link-to-${vnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource mlNotebooksPrivateDnsZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (createDnsZones) {
  parent: mlNotebooksPrivateDnsZone
  name: 'mlNotebook-${suffix}-link-to-${vnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Private DNS Zone for AI Search
// - Enables custom DNS resolution for AI Search private endpoint
resource aiSearchPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (createDnsZones) {
  name: 'privatelink.search.windows.net'  // Standard DNS zone for AI Search
}

// Link AI Search DNS Zone to VNet
resource aiSearchLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' =if (createDnsZones)  {
  parent: aiSearchPrivateDnsZone
  location: 'global'
  name: 'aiSearch-${suffix}-link-to-${vnetName}'
  properties: {
    virtualNetwork: {
      id: vnet.id                        // Link to specified VNet
    }
    registrationEnabled: false           // Don't auto-register VNet resources
  }
}

// Private DNS Zone for Storage
// - Enables custom DNS resolution for blob storage private endpoint
resource storagePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (createDnsZones) {
  name: 'privatelink.blob.${environment().suffixes.storage}'  // Dynamic DNS zone for storage
}

// Link Storage DNS Zone to VNet
resource storageLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (createDnsZones) {
  parent: storagePrivateDnsZone
  location: 'global'
  name: 'storage-${suffix}-link-to-${vnetName}'
  properties: {
    virtualNetwork: {
      id: vnet.id                        // Link to specified VNet
    }
    registrationEnabled: false           // Don't auto-register VNet resources
  }
}

