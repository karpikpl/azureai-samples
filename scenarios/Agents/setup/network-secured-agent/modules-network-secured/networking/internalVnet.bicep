param location string = resourceGroup().location
param name string= ''
@description('Tags to apply to resources')
param tags object = {}
param addressPrefixes string
param subnets object[]
param peerToNetworkName string = ''

// Virtual Network with segregated subnets
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' =  {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefixes
      ]
    }
    subnets: subnets
  }
}

resource otherVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = if (!empty(peerToNetworkName)) {
  name: peerToNetworkName
}

resource toVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = if (!empty(peerToNetworkName)) {
  parent: vnet
  name: '${vnet.name}-to-${otherVnet.name}'
  properties: {
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: otherVnet.id
    }
  }
}

resource fromVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = if (!empty(peerToNetworkName)) {
  parent: otherVnet
  name: '${otherVnet.name}-to-${vnet.name}'
  properties: {
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: vnet.id
    }
  }
}


output id string = vnet.id
output name string = vnet.name
output subnetIds array = [for (subnet, id) in subnets: vnet.properties.subnets[id].id]
