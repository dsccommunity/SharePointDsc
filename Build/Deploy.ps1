param(
    [Parameter()]
    [String]
    $ResourceGroupName,

    [Parameter()]
    [String]
    $Region,

    [Parameter()]
    [String]
    $ConfigurationName = "PublicPreview"
)

$catch = Import-Module AzureRM -EA SilentlyContinue
try
{
    $catch = Import-Module AzureRM
    $currentModule = Get-Module AzureRM
    $galleryModule = Find-Module AzureRM

    if($currentModule.Version.ToString() -ne $galleryModule.Version.ToString())
    {
        Write-Host "Installing the latest AzureRM Module..." -NoNewline -ForegroundColor Yellow
        $catch = Install-Module AzureRM -Force
        Write-Host "Done" -ForegroundColor Green
    }
}
catch
{
    Write-Host "Installing the AzureRM Module..." -NoNewline -ForegroundColor Yellow
    $catch = Install-Module AzureRM -Force
    Write-Host "Done" -ForegroundColor Green
}

if(!$ResourceGroupName)
{
    do
    {
        if($ResourceGroupName -and $ResourceGroupName.Length -gt 7)
        {
            Write-Host "Please select a resource name that is 7 characters long or less" -ForegroundColor Yellow
        }
        $ResourceGroupName = Read-Host "SP Farm Resource Group Name"
    }
    while($ResourceGroupName -and $ResourceGroupName.Length -gt 7)
}

$locObj = Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Automation  | ?{$_.ResourceTypes.ResourceTypeName -eq "automationAccounts"} | Select Locations | Sort -Property Locations
$azureLocations = $locObj.Locations | sort-object
if(!$Region -or $Region -notin $azureLocations)
{
    do
    {
        Write-Host "Please select a Azure location" -ForegroundColor Yellow
        $i = 1;
        foreach($loc in $azureLocations)
        {
            Write-Host $i "-" $loc
            $i++
        }
        $id = Read-Host "Select a location"
        
        if ($locationId -le $azureLocations.Count)
        {
            $Region = $azureLocations[$id-1]
        }
    }
    while(!$Region)
}

$GuidPart = (New-Guid).ToString().ToLower().Replace("-","").Substring(0,10)
#region Variables
$AutomationAccountName = "DSCAutomation" + $GuidPart
$StorageAccountName = "dscstorage" + $GuidPart
$BlobContainerName = "dscmodules"
#endregion

# Nik20180518 - Connect to Azure Account, and ask to select subscription if multiple ones exist;
# Brian20180628 - Only prompt for Azure creds if we're not already logged in
$loginSucceeded = $false
try
{
    # Run a simple command to check if we are logged in
    (Get-AzureRmResource -ErrorAction Stop -WarningAction SilentlyContinue) | Out-Null
    if ($? -eq $false)
    {
        throw
    }
    else
    {
        Write-Host -ForegroundColor White " - You are already logged in to Azure."
        $loginSucceeded = $true
    }
}
catch
{
    if ($_.Exception -like "*-AzureRmAccount to *" -or $_.Exception -like "*Your Azure credentials have not been set up or have expired*")
    {
        try
        {
            Write-Host -ForegroundColor Cyan " - Prompting for Azure Resource Manager credentials..."
            $catch = Add-AzureRmAccount
            if ($? -eq $false)
            {
                throw $Error
            }
            else
            {
                $loginSucceeded = $true
            }
        }
        catch
        {
            Write-Verbose -Message $Error
            if ($Error[2] -like "*User canceled authentication*")
            {
                throw "User canceled authentication"
            }
            else
            {
                throw "No credentials were provided, or another error occurred logging on to Azure."
            }
        }
    }
    elseif ($_.Exception -like "*Unable to acquire token for tenant*")
    {
        Write-Host $_.Exception
    }
    elseif ($_.Exception -like "*null array*")
    {
        # Do nothing
    }
    else
    {
        Write-Host $_.Exception
    }
}
finally
{
    if ($loginSucceeded)
    {
        $subscriptions = Get-AzureRmSubscription
        if($subscriptions.Length -gt 1)
        {
            $i = 1;
            foreach($sub in $subscriptions)
            {
                Write-Host $i "-" $sub.Name
                $i++
            }
            $id = Read-Host "Select a Subscription"

            $catch = Select-AzureRMSubscription -subscriptionId $subscriptions[$id-1].Id
        }
    }
}

cls

#region Deploy IaaS VMs
Write-Host "Deploying the SharePoint Farm (this can take up to 1h)..." -NoNewline -ForegroundColor Yellow
$Command = {
    $catch = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Region
    $catch = New-AzureRmResourceGroupDeployment -Name "spvms" -ResourceGroupName $ResourceGroupName -TemplateUri "https://raw.githubusercontent.com/NikCharlebois/SharePointFarms/BlankSPVMs/sharepoint-non-ha/azuredeploy.json" -TemplateParameterUri "https://raw.githubusercontent.com/NikCharlebois/SharePointFarms/BlankSPVMs/sharepoint-non-ha/azuredeploy.parameters.json"
}
$time = Measure-Command $Command
$message = "Done in {0:N0} minutes" -f $time.TotalMinutes
Write-Host $message -ForegroundColor Green
#endregion

#region Create Azure Piping
# Nik20180517 - Checks to see if the DSCSupport Resource Group Exists
Write-Host "Creating DSCSupport Resource Group..." -NoNewline -ForegroundColor Yellow
$Command = {
    try
    {
        Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    }
    catch
    {
        New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Region
    }
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} seconds" -f $time.TotalSeconds
Write-Host $message -ForegroundColor Green

# Nik20180517 - Checks to see if the Automation Account exists;
Write-Host "Creating DSCAutomation Automation Account..." -NoNewline -ForegroundColor Yellow
$Command = {
    try
    {
        Get-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -ErrorAction Stop
    }
    catch
    {
        New-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -Location $Region
    }
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} seconds" -f $time.TotalSeconds
Write-Host $message -ForegroundColor Green

# Nik20180517 - Create a new Storage Account
Write-Host "Creating Storage Account..." -NoNewline -ForegroundColor Yellow
$Command = {
    $storageAccount = $null
    try
    {
        $storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction Stop
    }
    catch
    {
        $storageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Region -SkuName "Standard_GRS" -Kind "BlobStorage" -AccessTier Hot
    }
    Set-AzureRmCurrentStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $ctx = $storageAccount.Context
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} seconds" -f $time.TotalSeconds
Write-Host $message -ForegroundColor Green

# Nik20180517 - Create the Blob Container
Write-Host "Creating Blob Container..." -NoNewline -ForegroundColor Yellow
$Command = {
    try
    {
        Get-AzureStorageContainer -Name $BlobContainerName -Context $ctx -ErrorAction Stop
    }
    catch
    {
        New-AzureStorageContainer -Name $BlobContainerName -Context $ctx -Permission blob
    }
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} milliseconds" -f $time.TotalMilliseconds
Write-Host $message -ForegroundColor Green
#endregion

#region Uploading/Importing DSC Modules
# Nik20180517 - Upload the xDownloadFile module
Write-Host "Upload the xDownloadFile module to Blob Storage..." -NoNewline -ForegroundColor Yellow
$Command = {
    $xDownloadFileUrl = $null
    $xDownloadFilePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "Modules/xDownloadFile.zip"))
    $blob = Set-AzureStorageBlobContent –Container $BlobContainerName -File $xDownloadFilePath -Blob "xDownloadFile.zip" -Force
    $xDownloadFileUrl = $blob.ICloudBlob.Uri.AbsoluteUri
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} milliseconds" -f $time.TotalMilliseconds
Write-Host $message -ForegroundColor Green

# Nik20180517 - Upload the xdownloadISO module
Write-Host "Upload the xDownloadISO module to Blob Storage..." -NoNewline -ForegroundColor Yellow
$Command = {
    $xdownloadISOUrl = $null
    $xdownloadISOPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "Modules/xdownloadISO.zip"))
    $blob = Set-AzureStorageBlobContent –Container $BlobContainerName -File $xdownloadISOPath -Blob "xdownloadISO.zip" -Force
    $xdownloadISOUrl = $blob.ICloudBlob.Uri.AbsoluteUri
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} milliseconds" -f $time.TotalMilliseconds
Write-Host $message -ForegroundColor Green

# Nik20180516 - Zip the new Module on the Build Agent using the download source;
Write-Host "Package the new SharePointDSC module from source code..." -NoNewline -ForegroundColor Yellow
$Command = {
    $SPDSCRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "../Modules/SharePointDSC"))
    $zipPath = $SPDSCRoot + "/SharePointDSC.zip"
    Compress-Archive -Path ($SPDSCRoot + "/*") -DestinationPath $zipPath -Force
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} seconds" -f $time.TotalSeconds
Write-Host $message -ForegroundColor Green

# Nik20180516 - Upload the newly zipped module into a Blob Storage Account;
Write-Host "Upload new SharePointDSC module to Blob Storage..." -NoNewline -ForegroundColor Yellow
$Command = {
    $blob = Set-AzureStorageBlobContent –Container $BlobContainerName -File $zipPath -Blob "SharePointDSC.zip" -Force
    $blobURL = $blob.ICloudBlob.Uri.AbsoluteUri
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} milliseconds" -f $time.TotalMilliseconds
Write-Host $message -ForegroundColor Green

# Nik20180516 - Remove the Module if it already exists;
Write-Host "Import all DSC modules into Automation Account..." -NoNewline -ForegroundColor Yellow
$Command = {
    try
    {
        Remove-AzureRmAutomationModule -Name "SharePointDSC" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force -ErrorAction Stop
    }
    catch{}

    # Nik20180516 - Import the Modules into the Automation Account from the Blob;
    New-AzureRmAutomationModule -Name "SharePointDSC" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ContentLinkUri $blobURL
    New-AzureRmAutomationModule -Name "xDownloadFile" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ContentLinkUri $xDownloadFileURL
    New-AzureRmAutomationModule -Name "xDownloadISO" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ContentLinkUri $xDownloadISOURL
    New-AzureRmAutomationModule -Name "xPendingReboot" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/xPendingReboot/0.4.0.0"

    do
    {
        Start-Sleep 5
    }while((Get-AzureRmAutomationModule -Name "SharePointDSC" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).ProvisioningState -ne "Succeeded")
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} seconds" -f $time.TotalSeconds
Write-Host $message -ForegroundColor Green
#endregion

#region Credential Assets
Write-Host "Creating Credential Assets into Automation Account..." -NoNewline -ForegroundColor Yellow
$Command = {
    $pw = ConvertTo-SecureString "Pass@word!123" -AsPlainText -Force

    try
    {
        Get-AzureRMAutomationCredential -Name "DomainAdmin" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -EA Stop
    }
    catch
    {
        $user = "contoso\lcladmin"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pw
        New-AzureRMAutomationCredential -AutomationAccountName $AutomationAccountName -Name "DomainAdmin" -Value $cred -ResourceGroupName $ResourceGroupName
    }

    try
    {
        Get-AzureRMAutomationCredential -Name "FarmAccount" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -EA Stop
    }
    catch
    {
        $user = "contoso\sp_farm"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pw
        New-AzureRMAutomationCredential -AutomationAccountName $AutomationAccountName -Name "FarmAccount" -Value $cred -ResourceGroupName $ResourceGroupName
    }

    try
    {
        Get-AzureRMAutomationCredential -Name "SetupAccount" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -EA Stop
    }
    catch
    {
        $user = "contoso\sp_setup"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pw
        New-AzureRMAutomationCredential -AutomationAccountName $AutomationAccountName -Name "SetupAccount" -Value $cred -ResourceGroupName $ResourceGroupName
    }

    try
    {
        Get-AzureRMAutomationCredential -Name "ServicesAccount" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -EA Stop
    }
    catch
    {
        $user = "contoso\sp_services"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pw
        New-AzureRMAutomationCredential -AutomationAccountName $AutomationAccountName -Name "ServicesAccount" -Value $cred -ResourceGroupName $ResourceGroupName
    }

    try
    {
        Get-AzureRMAutomationCredential -Name "SearchAccount" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -EA Stop
    }
    catch
    {
        $user = "contoso\sp_search"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pw
        New-AzureRMAutomationCredential -AutomationAccountName $AutomationAccountName -Name "SearchAccount" -Value $cred -ResourceGroupName $ResourceGroupName
    }

    try
    {
        Get-AzureRMAutomationCredential -Name "LocalAdmin" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -EA Stop
    }
    catch
    {
        $user = "lcladmin"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pw
        New-AzureRMAutomationCredential -AutomationAccountName $AutomationAccountName -Name "LocalAdmin" -Value $cred -ResourceGroupName $ResourceGroupName
    }

    try
    {
        Get-AzureRMAutomationCredential -Name "SPServices" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -EA Stop
    }
    catch
    {
        $user = "contoso\sp_services"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pw
        New-AzureRMAutomationCredential -AutomationAccountName $AutomationAccountName -Name "SPServices" -Value $cred -ResourceGroupName $ResourceGroupName
    }

    try
    {
        Get-AzureRMAutomationCredential -Name "SPSearch" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -EA Stop
    }
    catch
    {
        $user = "contoso\sp_search"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pw
        New-AzureRMAutomationCredential -AutomationAccountName $AutomationAccountName -Name "SPSearch" -Value $cred -ResourceGroupName $ResourceGroupName
    }

    try
    {
        Get-AzureRMAutomationCredential -Name "SharePointAdmin" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -EA Stop
    }
    catch
    {
        $user = "contoso\sharepointadmin"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pw
        New-AzureRMAutomationCredential -AutomationAccountName $AutomationAccountName -Name "SharePointAdmin" -Value $cred -ResourceGroupName $ResourceGroupName
    }
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} seconds" -f $time.TotalSeconds
Write-Host $message -ForegroundColor Green
#endregion

#region DSC Configuration
$ConfigData = @{
    AllNodes = @(
        @{
            NodeName        = "SPWFE" + $ResourceGroupName + ".contoso.com"
            RunCentralAdmin = $false
            ServerRole      = "WebFrontEnd"
        },
        @{
            NodeName        = "SPApp" + $ResourceGroupName + ".contoso.com"
            RunCentralAdmin = $true
            ServerRole      = "Application"
        },
        @{
            NodeName        = "SPSearch" + $ResourceGroupName + ".contoso.com"
            RunCentralAdmin = $false
            ServerRole      = "Search"
        },
        @{
            NodeName = "*"
            PSDSCAllowPlainTextPassword = $true
            PSDSCAllowDomainUser        = $true
        }
    )
    SharePoint = @{
        Settings = @{
            DatabaseServer = "SPSQL" + $ResourceGroupName
            BinaryPath     = "C:\SP2019\"
            ProductKey     = "M692G-8N2JP-GG8B2-2W2P7-YY7J6"
        }
    }
}

Write-Host "Upload SP DSC Configuration into Automation Account..." -NoNewline -ForegroundColor Yellow
$Command = {
    $ConfigPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ConfigurationName + ".ps1"))
    Import-AzureRmAutomationDscConfiguration -SourcePath $ConfigPath -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Published -Force
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} seconds" -f $time.TotalSeconds
Write-Host $message -ForegroundColor Green

Write-Host "Removing the Azure VM DSC Extensions..." -NoNewline -ForegroundColor Yellow
$Command = {
    try
    {
        Remove-AzureRmVMExtension -Name "ConfigureSPServer" -ResourceGroupName $ResourceGroupName -VMName ("SPWFE" + $ResourceGroupName) -Force -EA Stop
    }
    catch
    {
        try
        {
            Remove-AzureRmVMExtension -Name "Microsoft.Powershell.DSC" -ResourceGroupName $ResourceGroupName -VMName ("SPWFE" + $ResourceGroupName) -Force -EA Stop
        }
        catch{}
    }
    try
    {
        Remove-AzureRmVMExtension -Name "ConfigureSPServer" -ResourceGroupName $ResourceGroupName -VMName ("SPApp" + $ResourceGroupName) -Force -EA Stop
    }
    catch
    {
        try
        {
            Remove-AzureRmVMExtension -Name "Microsoft.Powershell.DSC" -ResourceGroupName $ResourceGroupName -VMName ("SPApp" + $ResourceGroupName) -Force -EA Stop
        }
        catch{}
    }
    try
    {
        Remove-AzureRmVMExtension -Name "ConfigureSPServer" -ResourceGroupName $ResourceGroupName -VMName ("SPSearch" + $ResourceGroupName) -Force -EA Stop
    }
    catch
    {
        try
        {
            Remove-AzureRmVMExtension -Name "Microsoft.Powershell.DSC" -ResourceGroupName $ResourceGroupName -VMName ("SPSearch" + $ResourceGroupName) -Force -EA Stop
        }
        catch{}
    }

    $spwfeExt1 = Get-AzureRMVMExtension -VMName ("SPWFE" + $ResourceGroupName) -ResourceGroupName $ResourceGroupName -Name "ConfigSPServer" -EA SilentlyContinue
    $spwfeExt2 = Get-AzureRMVMExtension -VMName ("SPWFE" + $ResourceGroupName) -ResourceGroupName $ResourceGroupName -Name "Microsoft.Powershell.DSC" -EA SilentlyContinue

    $spappExt1 = Get-AzureRMVMExtension -VMName ("SPApp" + $ResourceGroupName) -ResourceGroupName $ResourceGroupName -Name "ConfigSPServer" -EA SilentlyContinue
    $spappExt1 = Get-AzureRMVMExtension -VMName ("SPApp" + $ResourceGroupName) -ResourceGroupName $ResourceGroupName -Name "Microsoft.Powershell.DSC" -EA SilentlyContinue

    $spsearchExt1 = Get-AzureRMVMExtension -VMName ("SPSearch" + $ResourceGroupName) -ResourceGroupName $ResourceGroupName -Name "ConfigSPServer" -EA SilentlyContinue
    $spsearchExt1 = Get-AzureRMVMExtension -VMName ("SPSearch" + $ResourceGroupName) -ResourceGroupName $ResourceGroupName -Name "Microsoft.Powershell.DSC" -EA SilentlyContinue

    while($spwfeExt1 -or $spwfeExt2 -or $spappExt1 -or $spappExt2 -or $spsearchExt1 -or $spsearchExt2)
    {
        Start-Sleep 20
    }
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} minutes" -f $time.TotalMinutes
Write-Host $message -ForegroundColor Green

Write-Host "Compiling Configuration..." -NoNewline -ForegroundColor Yellow
$Command = {
    Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ConfigurationName $ConfigurationName -ConfigurationData $ConfigData
    do
    {
        Start-Sleep 5
    }
    while ((Get-AzureRmAutomationDscCompilationJob -ConfigurationName $ConfigurationName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | Sort-Object -Property LastModifiedTime -Descending | Select-Object -First 1).Status -ne "Completed")
}
$time = Measure-Command $Command
$message = "Completed in {0:N0} seconds" -f $time.TotalSeconds
Write-Host $message -ForegroundColor Green

Write-Host "Assigning Application Server Configuration..." -NoNewline -ForegroundColor Yellow
Register-AzureRmAutomationDscNode -AzureVMResourceGroup $ResourceGroupName -AzureVMName ("SPApp" + $ResourceGroupName) -AzureVMLocation $Region -NodeConfigurationName ($ConfigurationName + ".SPAPP" + $ResourceGroupName + ".contoso.com") -ActionAfterReboot ContinueConfiguration -RebootNodeIfNeeded $true -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -AllowModuleOverwrite $true -Verbose
$message = "Completed"
Write-Host $message -ForegroundColor Green

Write-Host "Assigning WFE Server Configuration..." -NoNewline -ForegroundColor Yellow
Register-AzureRmAutomationDscNode -AzureVMResourceGroup $ResourceGroupName -AzureVMName ("SPWFE" + $ResourceGroupName) -AzureVMLocation $Region -NodeConfigurationName ($ConfigurationName + ".SPWFE" + $ResourceGroupName + ".contoso.com") -ActionAfterReboot ContinueConfiguration -RebootNodeIfNeeded $true -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -AllowModuleOverwrite $true -Verbose
$message = "Completed"
Write-Host $message -ForegroundColor Green

Write-Host "Assigning Search Server Configuration..." -NoNewline -ForegroundColor Yellow
Register-AzureRmAutomationDscNode -AzureVMResourceGroup $ResourceGroupName -AzureVMName ("SPSearch" + $ResourceGroupName) -AzureVMLocation $Region -NodeConfigurationName ($ConfigurationName + ".SPSEARCH" + $ResourceGroupName + ".contoso.com") -ActionAfterReboot ContinueConfiguration -RebootNodeIfNeeded $true -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -AllowModuleOverwrite $true -Verbose
$message = "Completed"
Write-Host $message -ForegroundColor Green
#endregion
