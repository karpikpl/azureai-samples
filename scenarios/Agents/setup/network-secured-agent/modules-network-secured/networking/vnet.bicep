targetScope= 'subscription'
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
param agentsVnetName string = ''

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

var useTwoVnetsSolution = !empty(agentsVnetName) || !empty(existingAgentsVirtualNetworkName)

module vnets 'twoVnets.bicep' = if (useTwoVnetsSolution) {
  name: 'agents-${suffix}--vnets'
  params: {
    resourceGroupName: resourceGroupName
    hubVnetName: hubVnetName
    existingHubVirtualNetworkName: existingHubVirtualNetworkName
    existingHubVirtualNetworkResourceGroup: existingHubVirtualNetworkResourceGroup
    agentsVnetName: agentsVnetName
    existingAgentsVirtualNetworkName: existingAgentsVirtualNetworkName
    existingAgentsVirtualNetworkResourceGroup: existingAgentsVirtualNetworkResourceGroup
    hubSubnetName: hubSubnetName
    agentsSubnetName: agentsSubnetName
    agentsPeSubnetName: agentsPeSubnetName
    location: location
    tags: tags
    suffix: suffix
  }
}

module vnet 'oneVnet.bicep' = if (!useTwoVnetsSolution) {
  name: 'one-${suffix}--vnet'
  scope: resourceGroup(resourceGroupName)
  params: {
    hubVnetName: hubVnetName
    existingHubVirtualNetworkName: existingHubVirtualNetworkName
    existingHubVirtualNetworkResourceGroup: existingHubVirtualNetworkResourceGroup
    hubSubnetName: hubSubnetName
    agentsSubnetName: agentsSubnetName
    location: location
    tags: tags
    suffix: suffix
  }
}

// Output variables
output hubVirtualNetworkName string = !useTwoVnetsSolution
  ? vnet.outputs.hubVirtualNetworkName
  : vnets.outputs.hubVirtualNetworkName
output hubVirtualNetworkId string = !useTwoVnetsSolution
  ? vnet.outputs.hubVirtualNetworkId
  : vnets.outputs.hubVirtualNetworkId
output agentsVirtualNetworkName string = !useTwoVnetsSolution
  ? vnet.outputs.agentsVirtualNetworkName
  : vnets.outputs.agentsVirtualNetworkName
output agentsVirtualNetworkId string = !useTwoVnetsSolution
  ? vnet.outputs.agentsVirtualNetworkId
  : vnets.outputs.agentsVirtualNetworkId

output hubVirtualNetworkResourceGroupName string = !useTwoVnetsSolution
  ? vnet.outputs.hubVirtualNetworkResourceGroupName
  : vnets.outputs.hubVirtualNetworkResourceGroupName
output agentsVirtualNetworkResourceGroupName string = !useTwoVnetsSolution
  ? vnet.outputs.agentsVirtualNetworkResourceGroupName
  : vnets.outputs.agentsVirtualNetworkResourceGroupName
output hubSubnetName string = !useTwoVnetsSolution ? vnet.outputs.hubSubnetName : vnets.outputs.hubSubnetName
output agentsSubnetName string = !useTwoVnetsSolution ? vnet.outputs.agentsSubnetName : vnets.outputs.agentsSubnetName
output agentsPeSubnetName string = !useTwoVnetsSolution ? vnet.outputs.agentsPeSubnetName : vnets.outputs.agentsPeSubnetName
output hubSubnetId string = !useTwoVnetsSolution ? vnet.outputs.hubSubnetId : vnets.outputs.hubSubnetId
output agentsSubnetId string = !useTwoVnetsSolution ? vnet.outputs.agentsSubnetId : vnets.outputs.agentsSubnetId
output agentsPeSubnetId string = !useTwoVnetsSolution ? vnet.outputs.agentsPeSubnetId : vnets.outputs.agentsPeSubnetId
output useTwoVnetsSolution bool = useTwoVnetsSolution
