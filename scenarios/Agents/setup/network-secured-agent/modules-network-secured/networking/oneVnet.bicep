/*
Virtual Network Module
---------------------
This module deploys the core network infrastructure with security controls:

1. Address Space:
   - VNet CIDR: 172.16.0.0/16
   - Hub Subnet: 172.16.0.0/24 (private endpoints)
   - Agents Subnet: 172.16.101.0/24 (container apps)

2. Security Features:
   - Service endpoints
   - Network isolation
   - Subnet delegation
*/

@description('Azure region for the deployment')
param location string

@description('Tags to apply to resources')
param tags object = {}

@description('Unique suffix for resource names')
param suffix string

@description('The name of the virtual network')
param hubVnetName string = 'hub-vnet-${suffix}'

@description('The name of Agents Subnet')
param agentsSubnetName string = 'agents-subnet-${suffix}'

@description('The name of Hub subnet')
param hubSubnetName string = 'hub-subnet-${suffix}'

@description('The name of the existing hub virtual network')
param existingHubVirtualNetworkName string = ''

@description('The name of the existing virtual network resource group')
param existingHubVirtualNetworkResourceGroup string = ''

var hubVnetRg = !empty(existingHubVirtualNetworkResourceGroup) ? existingHubVirtualNetworkResourceGroup : resourceGroup().name

var _agentsSubnetName = !empty(agentsSubnetName) ? agentsSubnetName : 'agents-subnet-${suffix}'
var _hubSubnetName = !empty(hubSubnetName) ? hubSubnetName : 'hub-subnet-${suffix}'

resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' existing = if (!empty(existingHubVirtualNetworkName)) {
  name: existingHubVirtualNetworkName
  scope: resourceGroup(hubVnetRg)

  resource hubSubnet 'subnets' existing = {
    name: _hubSubnetName
  }
  resource agentsSubnet 'subnets' existing = {
    name: _agentsSubnetName
  }
}

// Virtual Network with segregated subnets
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = if (empty(existingHubVirtualNetworkName)) {
  name: hubVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.16.0.0/16'
      ]
    }
    subnets: [
      {
        name: _hubSubnetName
        properties: {
          addressPrefix: '172.16.0.0/24'
        }
      }
      {
        name: _agentsSubnetName
        properties: {
          addressPrefix: '172.16.101.0/24'
          delegations: [
            {
              name: 'Microsoft.app/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
    ]
  }
}

var hubSubnetRef = !empty(existingHubVirtualNetworkName)
  ? existingVirtualNetwork::hubSubnet.id
  : '${virtualNetwork.id}/subnets/${hubSubnetName}'

var agentSubnetRef = !empty(existingHubVirtualNetworkName)
  ? existingVirtualNetwork::agentsSubnet.id
  : '${virtualNetwork.id}/subnets/${agentsSubnetName}'

// Output variables
output hubVirtualNetworkName string = !empty(existingHubVirtualNetworkName)
  ? existingHubVirtualNetworkName
  : virtualNetwork.name
output hubVirtualNetworkId string = !empty(existingHubVirtualNetworkName) ? existingVirtualNetwork.id : virtualNetwork.id
output agentsVirtualNetworkName string = !empty(existingHubVirtualNetworkName)
  ? existingHubVirtualNetworkName
  : virtualNetwork.name
output agentsVirtualNetworkId string = !empty(existingHubVirtualNetworkName)
  ? existingVirtualNetwork.id
  : virtualNetwork.id

output hubVirtualNetworkResourceGroupName string = hubVnetRg
output agentsVirtualNetworkResourceGroupName string = hubVnetRg
output hubSubnetName string = _hubSubnetName
output agentsSubnetName string = _agentsSubnetName
output agentsPeSubnetName string = ''
output hubSubnetId string = hubSubnetRef
output agentsSubnetId string = agentSubnetRef
output agentsPeSubnetId string = ''
