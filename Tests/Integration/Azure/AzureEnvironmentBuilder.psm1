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
    Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "DscConfigs") | ForEach-Object -Process {
        Publish-AzureRmVMDscConfiguration -ConfigurationPath $_.FullName `
                                          -ResourceGroupName $ResourceGroupName `
                                          -StorageAccountName $StorageAccountName
    }

    # Publish the scripts
    New-AzureStorageContainer -Name "scripts" -Context $storageAccount.Context
    Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "CustomScripts") | ForEach-Object -Process {
        Set-AzureStorageBlobContent -File $_.FullName `
                                    -Container "scripts" `
                                    -Blob $_.Name `
                                    -Context $storageAccount.Context
    }

    # Get Sas token for DSC storage
    $mainKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $mainStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $mainKeys[0].Value
    $mainSasToken = New-AzureStorageAccountSASToken -Service Blob -ResourceType Service,Container,Object -Permission "racwdlup" -Context $mainStorageContext

    # Get keys for software storage
    $storageAccount = Find-AzureRmResource -ResourceNameContains $SoftwareStorageAccountName
    $softwareKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $SoftwareStorageAccountName


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
    New-AzureRmResourceGroupDeployment -Name "SPDscLab" `
                                       -TemplateFile (Join-Path -Path $PSScriptRoot -ChildPath "template.json") `
                                       -ResourceGroupName $ResourceGroupName `
                                       -TemplateParameterObject $parameters `
                                       -Verbose
}

Export-ModuleMember -Function *
