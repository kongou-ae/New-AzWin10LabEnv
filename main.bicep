param rdpPermittedPrefixes array = [
  '0.0.0.0/0'
]

param numberOfVMs int // Max is 254

param passwords array

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

var vmParams  = [ for i in range(0,numberOfVMs): {
  adminUsername: 'evaluser${i}'
  vmName: 'vmuser${i}'
  adminPassword: '${passwords[i]}@user${i}Lab'
  nicName: 'user${i}-nic'
  publicIpName: 'user${i}-pip'
  dnsLabelPrefix: toLower('vmuser${i}-${uniqueString(resourceGroup().id, 'user${i}')}')
  networkSecurityGroupName: 'eval-user${i}-nsg'

}]

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = [ for i in range(0,numberOfVMs): {
  name: vmParams[i].publicIpName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmParams[i].dnsLabelPrefix
    }
  }
}]

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = [ for i in range(0,numberOfVMs): {
  name: vmParams[i].networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefixes: rdpPermittedPrefixes
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}]

resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'eval-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [ for i in range(0,numberOfVMs): {
      name: 'eval-subnet-user${i}'
      properties: {
        addressPrefix: '10.0.${string(i)}.0/24'
      }    
    }]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = [ for i in range(0,numberOfVMs): {
  name: vmParams[i].nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip[i].id
          }
          subnet: {
            id: '${resourceId('Microsoft.Network/virtualNetworks',vn.name)}/subnets/eval-subnet-user${i}'
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: securityGroup[i].id
    }
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = [ for i in range(0,numberOfVMs): {
  name: vmParams[i].vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmParams[i].vmName
      adminUsername: vmParams[i].adminUsername
      adminPassword: vmParams[i].adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '20h2-pro-g2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
    licenseType: 'Windows_Client'
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}]

output msg array = [ for i in range(0,numberOfVMs): {
  vmName: vmParams[i].vmName
  dnsLabelPrefix: pip[i].properties.dnsSettings.fqdn
  adminUsername: vmParams[i].adminUsername
  adminPassword: vmParams[i].adminPassword
}]
