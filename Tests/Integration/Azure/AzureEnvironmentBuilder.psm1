<#
.SYNOPSIS
The New-SPDscAzureLab cmdlet will create a new environment in Azure that can be used to develop
for SharePointDsc or to run integration tests against

.DESCRIPTION
The New-SPDscAzureLab cmdlet will deploy a new resource group in to your current Azure subscription
that will contain storage, network and virtual machines that are configured to be able to begin 
development. Appropriate development tools are also installed on the SharePoint server.

.PARAMETER ResourceGroupName
The name of the resource group to create and deploy assets in to. This cannot be an existing
resource group

.PARAMETER Location
The Azure location to deploy the assets and resource group to. To discover Azure locations run
Get-AzureRmLocation | Select-Object -Property Location

.PARAMETER StorageAccountName
This is the name of the storage account that will be created for the deployment. This will
contain VHD images, scripts and DSC configurations

.PARAMETER SoftwareStorageAccountName
This is the name of a storage account that will contain the binaries for SharePoint Server 
(either 2013 or 2016).

.PARAMETER SoftwareStorageAccountContainer
This is the name of the container in the software storage account that will contain the
binaries for the version of SharePoint you wish to deploy. This must be the full set of
files to install SharePoint (not an ISO or other compressed collection of the files)

.PARAMETER SharePointProductKey
A valid product key for the version of SharePoint you wish to install

.PARAMETER PublicDNSLabel
The name of the public DNS label to assign to the public IP address of the SharePoint server.
This will automatically be suffixed with the Azure location name and azure DNS suffix 

.PARAMETER AdminCredential
The username and password to use as the local administrator on all machines. The password
on this account will also be used for all service accounts

.EXAMPLE
New-SPDscAzureLab -ResourceGroupName "SPDSCTestLab" `
                  -Location southeastasia `
                  -StorageAccountName "spdsctestlab1" `
                  -SoftwareStorageAccountName "spdscsoftware1" `
                  -SoftwareStorageAccountContainer "sharepoint2016" `
                  -SharePointProductKey "AAAAA-AAAAA-AAAAA-AAAAA-AAAAA" `
                  -PublicDNSLabel "spdsctestlab1" `
                  -AdminCredential (Get-Credential -Message "Enter admin credential")

.NOTES
This cmdlet requires that the Azure PowerShell cmdlets are already installed, and that you
have already run Login-AzureRmAccount to log in to Azure

#>
function New-SPDscAzureLab
{
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]
        $Location,

        [Parameter(Mandatory = $true)]
        [string]
        $StorageAccountName,

        [Parameter(Mandatory = $true)]
        [string]
        $SoftwareStorageAccountName,

        [Parameter(Mandatory = $true)]
        [string]
        $SoftwareStorageAccountContainer,

        [Parameter(Mandatory = $true)]
        [string]
        $SharePointProductKey,

        [Parameter(Mandatory = $true)]
        [string]
        $PublicDNSLabel,

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $AdminCredential
    )   

    # Create the RG and storage account
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
    $storageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName `
                                                -Name $StorageAccountName `
                                                -SkuName Standard_LRS `
                                                -Location $Location

    # Publish the DSC configurations
    $dscConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "DscConfigs"
    Get-ChildItem -Path $dscConfigPath | ForEach-Object -Process {
        Publish-AzureRmVMDscConfiguration -ConfigurationPath $_.FullName `
                                          -ResourceGroupName $ResourceGroupName `
                                          -StorageAccountName $StorageAccountName
    }

    # Publish the scripts
    New-AzureStorageContainer -Name "scripts" -Context $storageAccount.Context
    $scriptsPath = Join-Path -Path $PSScriptRoot -ChildPath "CustomScripts"
    Get-ChildItem -Path $scriptsPath | ForEach-Object -Process {
        Set-AzureStorageBlobContent -File $_.FullName `
                                    -Container "scripts" `
                                    -Blob $_.Name `
                                    -Context $storageAccount.Context
    }

    # Get Sas token for DSC storage
    $mainKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName `
                                             -Name $StorageAccountName
    $mainStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName `
                                                  -StorageAccountKey $mainKeys[0].Value
    $mainSasToken = New-AzureStorageAccountSASToken -Service Blob `
                                                    -ResourceType Service,Container,Object `
                                                    -Permission "racwdlup" `
                                                    -Context $mainStorageContext

    # Get keys for software storage
    $storageAccount = Find-AzureRmResource -ResourceNameContains $SoftwareStorageAccountName
    $softwareKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName `
                                                 -Name $SoftwareStorageAccountName


    $parameters = @{}
    $parameters.Add("storageAccountName", $StorageAccountName)
    $parameters.Add("storageAccountKey", $mainKeys[0].Value)
    $parameters.Add("softwareStorageAccount", $SoftwareStorageAccountName)
    $parameters.Add("softwareStorageKey", $softwareKeys[0].Value)
    $parameters.Add("softwareStorageContainer", $SoftwareStorageAccountContainer)
    $parameters.Add("spProductKey", $SharePointProductKey)
    $parameters.Add("adminUserName", $AdminCredential.UserName)
    $parameters.Add("adminPassword", $AdminCredential.GetNetworkCredential().Password)
    $parameters.Add("mainStorageToken", $mainSasToken)
    $parameters.Add("publicDnsLabel", $PublicDNSLabel)

    # Start the ARM deployment
    $templatePath = Join-Path -Path $PSScriptRoot -ChildPath "template.json"
    New-AzureRmResourceGroupDeployment -Name "SPDscLab" `
                                       -TemplateFile $templatePath `
                                       -ResourceGroupName $ResourceGroupName `
                                       -TemplateParameterObject $parameters `
                                       -Verbose
}

Export-ModuleMember -Function *
