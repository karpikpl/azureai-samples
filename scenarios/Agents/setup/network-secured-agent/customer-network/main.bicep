targetScope = 'subscription'

/*
Bicep that simulates typical customer setup:
1. DNS zones are centrally managed in the hub VNet
2. Virtual network for hub uses 10.x address space
3. Virtual network for agents uses 172.x address space
4. Vnet peering is used to connect the two networks

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

/* ---------------------------------- Deployment Identifiers ---------------------------------- */

param name string = 'customer-secured-agent'

// Create a short, unique suffix, that will be unique to each resource group
param resourceGroupName string = '${name}-rg'
param uniqueSuffix string = substring(uniqueString('${subscription().id}-${resourceGroupName}'), 0, 4)

/* ---------------------------------- Default Parameters if Overrides Not Set ---------------------------------- */

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

// VNET
@description('The name of the agents virtual network to create. As of 3/13/2025 the address space of the subnet has to be either 172 or 192.')
param agentsVnetName string = 'agents-vnet'
param hubVnetName string = 'hub-vnet'
@description('The name of Agents Subnet. As of 3/13/2025 the address space of the subnet has to be either 172 or 192.')
param agentsSubnetName string = 'agents-subnet'
@description('The name of Customer Hub subnet.')
param hubSubnetName string = 'hub-pe-subnet'
@description('The name of PE Agents Subnet')
param agentsPeSubnetName string = 'agents-pe-subnet'

// @description('The Ai Storage Account name. This is an optional field, and if not provided, the resource will be created.The resource should exist in same resource group')
// param aiStorageAccountName string = ''

/* ---------------------------------- Create User Assigned Identity ---------------------------------- */

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

/* ---------------------------------- Create AI Assistant Dependent Resources ---------------------------------- */

// Create Virtual Network and Subnets
module vnet '../modules-network-secured/networking/vnet.bicep' = {
  name: '${name}-${uniqueSuffix}--vnets'
  params: {
    resourceGroupName: resourceGroupName
    existingHubVirtualNetworkName: ''
    existingHubVirtualNetworkResourceGroup: ''
    existingAgentsVirtualNetworkName: ''
    existingAgentsVirtualNetworkResourceGroup: ''
    agentsVnetName: agentsVnetName
    hubVnetName: hubVnetName
    hubSubnetName: hubSubnetName
    agentsSubnetName: agentsSubnetName
    agentsPeSubnetName: agentsPeSubnetName
    location: location
    tags: tags
    suffix: uniqueSuffix
    usePeering: true
  }
}

module dnsZoneLinksAgents '../modules-network-secured/dns-zone-links.bicep' = {
  name: 'dns-zone-links-for-${agentsVnetName}'
  scope: rg
  params: {
    vnetName: vnet.outputs.agentsVirtualNetworkName
    vnetResourceGroupName: vnet.outputs.agentsVirtualNetworkResourceGroupName
    suffix: uniqueSuffix
  }
}

module dnsZoneLinksHub '../modules-network-secured/dns-zone-links.bicep' = {
  name: 'dns-zone-links-for-${hubVnetName}'
  scope: rg
  params: {
    vnetName: vnet.outputs.hubVirtualNetworkName
    vnetResourceGroupName: vnet.outputs.hubVirtualNetworkResourceGroupName
    suffix: uniqueSuffix
  }
  dependsOn: [
    dnsZoneLinksAgents
  ]
}
