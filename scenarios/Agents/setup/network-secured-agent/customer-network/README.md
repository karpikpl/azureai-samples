# About

Bicep deployment to simulate real customer scenario.

1. DNS zones are centrally managed in the hub VNet and are not allowed in bicep deployments.
2. Virtual network for hub uses 10.x address space.
3. Virtual network for agents uses 172.x address space.
4. Vnet peering is used to connect the two networks.

Bicep creates the networking stack so that another deployment can use it for Foundry and Agent Service setup.

Since it's hard to replicate central DNS or express route, deployment creates 2 peered VNets and DNS Zones linked to both of them.

## Parameters for follow up deployment

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "defaultAiHubName": {
        "value": "hub-pka"
      },
      "resourceGroupName": {
        "value": "customer-secured-agent-rg"
      },
      "defaultAiHubFriendlyName": {
        "value": "Agents Secure Hub resource"
      },
      "defaultAiHubDescription": {
        "value": "This is an example AI resource for use in Azure AI Studio."
      },
      "defaultAiProjectName": {
        "value": "project-secure-demo"
      },
      "defaultAiProjectFriendlyName": {
        "value": "Agents Project resource"
      },
      "defaultAiProjectDescription": {
        "value": "This is an example AI Project resource for use in Azure AI Studio."
      },
      "tags": {
        "value": {}
      },
      "defaultAiSearchName": {
        "value": "agent-ai-search"
      },
      "defaultStorageName": {
        "value": "agentstorage"
      },
      "defaultAiServicesName": {
        "value": "agent-ai-services"
      },
      "modelName": {
        "value": "gpt-4o-mini"
      },
      "modelFormat": {
        "value": "OpenAI"
      },
      "modelVersion": {
        "value": "2024-07-18"
      },
      "modelSkuName": {
        "value": "GlobalStandard"
      },
      "modelCapacity": {
        "value": 1000
      },
      "modelLocation": {
        "value": "eastus2"
      },
      "resourceGroupLocation": {
        "value": "eastus2"
      },
      "createDnsZones": {
        "value": true
      },
      "usePeering": {
        "value": true
      },
      "uniqueSuffix": {
        "value": "pka"
      },
      "agentsSubnetName": {
        "value": "agents-subnet"
      },
      "hubSubnetName": {
        "value": "hub-pe-subnet"
      },
      "agentsPeSubnetName": {
        "value": "agents-pe-subnet"
      },
      "existingHubVirtualNetworkName": {
        "value": "hub-vnet"
      },
      "existingAgentsVirtualNetworkName": {
        "value": "existing-vnet"
      }
    }
}
```