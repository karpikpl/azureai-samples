param location string = resourceGroup().location
param name string= ''
@description('Tags to apply to resources')
param tags object = {}
param addressPrefixes string
param subnets object[]

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

output id string = vnet.id
output name string = vnet.name
output subnetIds array = [for (subnet, id) in subnets: vnet.properties.subnets[id].id]
