To help speed up development with SharePointDsc, a set of scripts has been created that will deploy an environment that is ready to use for development purposes in to your own Azure subscription. This page outlines the requirements for using this script.

## Step One - Get an Azure subscription

If you do not currently have an Azure subscription, you can sign up for a free trial at [https://azure.microsoft.com/free](https://azure.microsoft.com/free)

## Step Two - Install the Azure PowerShell cmdlets

You can install the required Azure management PowerShell cmdlets by running the following script

    Install-Module Azure
    Install-Module AzureRm

## Step Three - Install required DSC modules

The script requires several PowerShell DSC modules to be installed on your local machine, which are published to the Azure Blob Storage together with the DSC scripts.

Module Name | Version
------------ | -------------
xActiveDirectory | 2.16.0.0
xCredSSP | 1.0.1
xDnsServer |1.7.0.0
xComputerManagement | 1.9.0.0
xNetworking | 3.2.0.0
SQLServerDsc | 10.0.0.0
xWebAdministration |
SharePointDsc |

To install the modules:

```PowerShell
Install-Module -Name xActiveDirectory -RequiredVersion 2.16.0.0 -SkipPublisherCheck -Force
Install-Module -Name xCredSSP -RequiredVersion 1.0.1 -SkipPublisherCheck -Force
Install-Module -Name xDnsServer -RequiredVersion 1.7.0.0 -SkipPublisherCheck -Force
Install-Module -Name xComputerManagement -RequiredVersion 1.9.0.0 -SkipPublisherCheck -Force
Install-Module -Name xNetworking -RequiredVersion 3.2.0.0 -SkipPublisherCheck -Force
Install-Module -Name SQLServerDsc -RequiredVersion 10.0.0.0 -SkipPublisherCheck -Force
Install-Module -Name xWebAdministration -SkipPublisherCheck -Force
Install-Module -Name SharePointDsc -SkipPublisherCheck -Force
```
## Step Four- Create a storage account that contains the binaries for SharePoint

You will need a storage account that will contain the installer for SharePoint so you can have the dev environments download them when needed. See "[Creating a storage account](https://docs.microsoft.com/en-us/azure/storage/storage-create-storage-account#create-a-storage-account)" for instructions on how to create a new storage account.

Once you have created the account you will need to create a container in it, and then copy the files for SharePoint in to this. This can be done through the portal (under the "blobs" or "containers" section), or via the [New-AzureStorageContainer](https://docs.microsoft.com/en-us/powershell/module/azure.storage/New-AzureStorageContainer?view=azurermps-4.2.0) PowerShell cmdlet.

There are a number of ways of copying files in to Azure storage - see "[moving data to and from Azure storage](https://docs.microsoft.com/en-us/azure/storage/storage-moving-data)" for specific methods. You will need to take the entire contents of the SharePoint 2013, 2016 or 2019 ISO and copy them in to the container you created above. You can also slipstream updates in to the "Updates" folder at this point to install SharePoint to a specific CU level.

## Step Five - Create a new dev environment

To create your development environment, run the following PowerShell commands (see the list below of changes to make to this before running)

    Import-Module C:\repos\SharePointDsc\Tests\Integration\Azure\AzureEnvironmentBuilder.psm1
    Login-AzureRmAccount
    New-SPDscAzureLab -ResourceGroupName "SPDSCTestLab" `
                      -Location southeastasia `
                      -StorageAccountName "spdsctestlab1" `
                      -SoftwareStorageAccountName "spdscsoftware1" `
                      -SoftwareStorageAccountContainer "sharepoint2016" `
                      -SharePointProductKey "AAAAA-AAAAA-AAAAA-AAAAA-AAAAA" `
                      -PublicDNSLabel "spdsctestlab1" `
                      -AdminCredential (Get-Credential -Message "Enter admin credential")

In this script you will need to set the following values

1. The Import-Module cmdlet needs to point to where ever you have a copy of the SharePointDsc source code to import the module from
2. Change the resource group name parameter, this can be anything to help you identify the development environment in your Azure subscription
3. Set the location to the Azure location you wish to deploy to
4. The SoftwareStorageAccountName parameter should be the name of the storage account you created earlier to upload SharePoint in to
5. The SoftwareStorageAccountContainer parameter should be the name of your container that was created earlier
6. The SharePointProductKey parameter should be your valid SharePoint product key
7. The PublicDNSLabel property is used to establish a DNS name for your server once it is created. This will be viewable in the Azure portal when the provisioning is complete

After these changes have been made you can run the script and you will be prompted first to sign in to Azure, and after that you will be prompted for the admin credentials for your environment (username and password - do not prefix a domain name on to the username).

# What is in the development environment

You will see a Domain controller server, a SQL server and a SharePoint server. The AD and SQL servers are both fully configured and ready to use. The SharePoint server will have the following software installed:

* SharePoint (version will be based on what you uploaded to blob storage)
* Git for Windows
* Visual Studio Code
* Nodejs
* Git Credential Helper for Windows
* PoshGit

This should be seen as a minimum to begin development with SharePointDsc - you can however install any other software on the servers you need as you have full control of them after they are provisioned from the template.
