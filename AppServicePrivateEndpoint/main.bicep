param webAppsName string = 'myWebApps230106'
param bastionVmName string = 'myVM'
param bastionHostName string = 'myBastion'
param vnetName string = 'myVNet'
param bastionVmNicName string = 'myvm601'
param bastionVmPipName string = 'myVM-ip'
param appServicePlanName  string = 'ASP-AppServicePE-b9c8'
param bastionVmNsgName string = 'myVM-nsg'
param bastionPipName string = 'mybastion_pip'
param appServiceSitePrivateEndpointName string = 'myPrivateEndpoint'
param appServiceSitePrivateEndpointNsgName string = 'myPrivateEndpoint-nsg'
param privateDnsZonesName string = 'privatelink.azurewebsites.net'
param location string = resourceGroup().location
param bationVmAdminUsername string
@secure()
param bationVmAdminPassword string


// VNet
resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
  }
}

resource default_subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: '${vnetName}/default'
  properties: {
    addressPrefix: '10.1.0.0/24'
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    vnet
  ]
}

resource bastion_subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: '${vnetName}/AzureBastionSubnet'
  properties: {
    addressPrefix: '10.1.1.0/24'
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    vnet
  ]
}


// VM
resource bastionVm_nic_pip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: bastionVmPipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionVm_nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: bastionVmNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastionVm_nic_pip.id
          }
          subnet: {
            id: default_subnet.id
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: bastionVm_nsg.id
    }
    nicType: 'Standard'
  }
}

resource bastionVm_nsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: bastionVmNsgName
  location: location
  properties: {
    securityRules: []
  }
}

resource bastionVm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: bastionVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile: {
      computerName: bastionVmName
      adminUsername: bationVmAdminUsername
      adminPassword: bationVmAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: bastionVm_nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Bastion
resource bastion_pip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: bastionPipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2022-05-01' = {
  name: bastionHostName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    dnsName: 'bst-748d90a3-a6dc-480e-9d71-af194954b7f9.bastion.azure.com'
    scaleUnits: 2
    enableTunneling: false
    enableIpConnect: false
    disableCopyPaste: false
    enableShareableLink: false
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastion_pip.id
          }
          subnet: {
            id: bastion_subnet.id
          }
        }
      }
    ]
  }
}

// DNS Zone
resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZonesName
  location: 'global'
}

resource privateDnsZones_a_web 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones
  name: 'mywebapps230106'
  properties: {
    metadata: {
      creator: 'created by private endpoint myPrivateEndpoint with resource guid ceda4211-f8ee-43ef-a5da-9a3f6122b9cb'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.1.0.5'
      }
    ]
  }
}

resource privateDnsZones_a_scm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones
  name: 'mywebapps230106.scm'
  properties: {
    metadata: {
      creator: 'created by private endpoint myPrivateEndpoint with resource guid ceda4211-f8ee-43ef-a5da-9a3f6122b9cb'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.1.0.5'
      }
    ]
  }
}

resource privateDnsZones_soa 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDnsZones
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource privateDnsZones_privatelink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZones
  name: 'da8f449a109f1'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Web Apps
resource appService_plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName 
  location: location
  sku: {
    name: 'B1'
  }
  kind: 'app'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource appService_site 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppsName
  location: location
  properties: {
    serverFarmId: appService_plan.id
  }
}

// Web Apps - Private Endpoint
resource appService_site_privateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: appServiceSitePrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: default_subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${appServiceSitePrivateEndpointName}-8b87'
        properties: {
          privateLinkServiceId: appService_site.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
    customNetworkInterfaceName: appServiceSitePrivateEndpointNsgName
  }
}

resource appService_site_privateEndpoint_nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: appServiceSitePrivateEndpointNsgName
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAddress: '10.1.0.5'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: default_subnet.id
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

resource appService_site_privateEndpoint_privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  name: '${appServiceSitePrivateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: privateDnsZones.id
        }
      }
    ]
  }
  dependsOn: [
    appService_site_privateEndpoint
  ]
}
