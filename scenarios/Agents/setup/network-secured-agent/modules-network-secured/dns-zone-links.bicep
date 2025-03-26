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

// Reference existing network resources
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}

/* -------------------------------------------- Private DNS Zones -------------------------------------------- */

// Private DNS Zone for AI Services
// - Enables custom DNS resolution for AI Services private endpoint
resource aiServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azureml.ms' // Standard DNS zone for AI Services
  location: 'global'
}

resource openAiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.openai.azure.com'
  location: 'global'
}

// Private DNS Zone for AI Hub
// - Enables custom DNS resolution for AI Hub private endpoint
resource mlApiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.api.azureml.ms'
  location: 'global'
}

resource mlNotebooksPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.notebooksazureml.net'
  location: 'global'
}

// Private DNS Zone for AI Search
// - Enables custom DNS resolution for AI Search private endpoint
resource aiSearchPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.search.windows.net' // Standard DNS zone for AI Search
  location: 'global'
}

// Private DNS Zone for Storage
// - Enables custom DNS resolution for blob storage private endpoint
resource storagePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}' // Dynamic DNS zone for storage
  location: 'global'
}

// - Enables custom DNS resolution for blob storage private endpoint
resource storageFilePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${environment().suffixes.storage}' // Dynamic DNS zone for storage
  location: 'global'
}

// Links -----------------------------------------------------------------------------------

// Link AI Services DNS Zone to VNet
resource aiServicesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: aiServicesPrivateDnsZone
  location: 'global'
  name: 'aiServices-${suffix}-link-to-${vnetName}'
  properties: {
    virtualNetwork: {
      id: vnet.id // Link to specified VNet
    }
    registrationEnabled: false // Don't auto-register VNet resources
  }
}

resource aiOpenAILink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: openAiPrivateDnsZone
  location: 'global'
  name: 'aiServicesOpenAI-${suffix}-link-to-${vnetName}'
  properties: {
    virtualNetwork: {
      id: vnet.id // Link to specified VNet
    }
    registrationEnabled: false // Don't auto-register VNet resources
  }
}

// Link AI Hub DNS Zone to VNet
resource mlApiPrivateDnsZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
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

resource mlNotebooksPrivateDnsZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
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

// Link AI Search DNS Zone to VNet
resource aiSearchLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: aiSearchPrivateDnsZone
  location: 'global'
  name: 'aiSearch-${suffix}-link-to-${vnetName}'
  properties: {
    virtualNetwork: {
      id: vnet.id // Link to specified VNet
    }
    registrationEnabled: false // Don't auto-register VNet resources
  }
}

// Link Storage DNS Zone to VNet
resource storageLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: storagePrivateDnsZone
  location: 'global'
  name: 'storage-${suffix}-link-to-${vnetName}'
  properties: {
    virtualNetwork: {
      id: vnet.id // Link to specified VNet
    }
    registrationEnabled: false // Don't auto-register VNet resources
  }
}

// Link Storage DNS Zone to VNet
resource storageFileLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: storageFilePrivateDnsZone
  location: 'global'
  name: 'storage-file-${suffix}-link-to-${vnetName}'
  properties: {
    virtualNetwork: {
      id: vnet.id // Link to specified VNet
    }
    registrationEnabled: false // Don't auto-register VNet resources
  }
}
