targetScope = 'subscription'
/*
Virtual Network Module
---------------------
This module deploys the core network infrastructure with security controls:

- **Hub Virtual Network (10.23.0.0/22)**
  - Customer Hub Subnet (10.23.0.0/24): Hosts private endpoints

- **Agents Virtual Network (172.17.0.0/23)**
  - Agents Subnet (172.17.0.0/24): For azure ai agent workloads
  - PE Subnet (172.16.0.0/24): Hosts private endpoints
*/
@description('Resource group name for main vnet - where AI Foundry is deployed')
param resourceGroupName string

@description('Azure region for the deployment')
param location string

@description('Tags to apply to resources')
param tags object = {}

@description('Unique suffix for resource names')
param suffix string

@description('The name of the hub virtual network')
param hubVnetName string = 'hub-vnet-${suffix}'

@description('The name of the agent virtual network')
param agentsVnetName string = 'agents-vnet-${suffix}'

@description('The name of Agents Subnet')
param agentsSubnetName string = 'agents-subnet-${suffix}'

@description('The name of PE Agents Subnet')
param agentsPeSubnetName string = 'agents-pe-subnet-${suffix}'

@description('The name of Hub subnet')
param hubSubnetName string = 'hub-subnet-${suffix}'

@description('The name of the existing hub virtual network')
param existingHubVirtualNetworkName string = ''

@description('The name of the existing virtual network resource group')
param existingHubVirtualNetworkResourceGroup string = ''

@description('The name of the existing hub virtual network')
param existingAgentsVirtualNetworkName string = ''

@description('The name of the existing agents virtual network resource group')
param existingAgentsVirtualNetworkResourceGroup string = ''

@description('Set to true to peer the agents vnet with the hub vnet')
param usePeering bool = false

var hubVnetRg = !empty(existingHubVirtualNetworkResourceGroup)
  ? existingHubVirtualNetworkResourceGroup
  : resourceGroupName
var agentsVnetRg = !empty(existingAgentsVirtualNetworkResourceGroup)
  ? existingAgentsVirtualNetworkResourceGroup
  : resourceGroupName

var _agentsSubnetName = !empty(agentsSubnetName) ? agentsSubnetName : 'agents-subnet-${suffix}'
var _agentsPeSubnetName = !empty(agentsPeSubnetName) ? agentsPeSubnetName : 'agents-pe-subnet-${suffix}'
var _hubSubnetName = !empty(hubSubnetName) ? hubSubnetName : 'hub-subnet-${suffix}'

resource existingHubVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' existing = if (!empty(existingHubVirtualNetworkName)) {
  name: existingHubVirtualNetworkName
  scope: resourceGroup(hubVnetRg)

  resource hubSubnet 'subnets' existing = {
    name: _hubSubnetName
  }
}

resource existingAgentVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' existing = if (!empty(existingAgentsVirtualNetworkName)) {
  name: existingAgentsVirtualNetworkName
  scope: resourceGroup(agentsVnetRg)

  resource agentsSubnet 'subnets' existing = {
    name: _agentsSubnetName
  }

  resource agentsPeSubnet 'subnets' existing = {
    name: _agentsPeSubnetName
  }
}

// Virtual Network with segregated subnets
module hubVirtualNetwork 'internalVnet.bicep' = if (empty(existingHubVirtualNetworkName)) {
  name: hubVnetName
  scope: resourceGroup(hubVnetRg)
  params: {
    location: location
    name: hubVnetName
    tags: tags
    addressPrefixes: '10.23.0.0/22'
    subnets: [
      {
        name: _hubSubnetName
        properties: {
          addressPrefix: '10.23.0.0/24'
        }
      }
    ]
  }
}

module agentsVirtualNetwork 'internalVnet.bicep' = if (empty(existingAgentsVirtualNetworkName)) {
  name: agentsVnetName
  scope: resourceGroup(agentsVnetRg)
  params: {
    location: location
    name: agentsVnetName
    tags: tags
    peerToNetworkName: usePeering ? hubVirtualNetwork.outputs.name : ''
    addressPrefixes: '172.17.0.0/23'
    subnets: [
      {
        name: _agentsSubnetName
        properties: {
          addressPrefix: '172.17.0.0/24'
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
      {
        name: _agentsPeSubnetName
        properties: {
          addressPrefix: '172.17.1.0/27'
        }
      }
    ]
  }
}


var hubSubnetRef = !empty(existingHubVirtualNetworkName)
  ? existingHubVirtualNetwork::hubSubnet.id
  : hubVirtualNetwork.outputs.subnetIds[0]

var agentSubnetRef = !empty(existingAgentsVirtualNetworkName)
  ? existingAgentVirtualNetwork::agentsSubnet.id
  : agentsVirtualNetwork.outputs.subnetIds[0]

var agentsPeSubnetRef = !empty(existingAgentsVirtualNetworkName)
  ? existingAgentVirtualNetwork::agentsPeSubnet.id
  : agentsVirtualNetwork.outputs.subnetIds[1]

// Output variables
output hubVirtualNetworkName string = !empty(existingHubVirtualNetworkName)
  ? existingHubVirtualNetworkName
  : hubVirtualNetwork.name
output hubVirtualNetworkId string = !empty(existingHubVirtualNetworkName)
  ? existingHubVirtualNetwork.id
  : hubVirtualNetwork.outputs.id
output agentsVirtualNetworkName string = !empty(existingAgentsVirtualNetworkName)
  ? existingAgentsVirtualNetworkName
  : agentsVirtualNetwork.name
output agentsVirtualNetworkId string = !empty(existingAgentsVirtualNetworkName)
  ? existingAgentVirtualNetwork.id
  : agentsVirtualNetwork.outputs.id

output hubVirtualNetworkResourceGroupName string = hubVnetRg
output agentsVirtualNetworkResourceGroupName string = agentsVnetRg
output hubSubnetName string = _hubSubnetName
output agentsSubnetName string = _agentsSubnetName
output agentsPeSubnetName string = _agentsPeSubnetName
output hubSubnetId string = hubSubnetRef
output agentsSubnetId string = agentSubnetRef
output agentsPeSubnetId string = agentsPeSubnetRef
