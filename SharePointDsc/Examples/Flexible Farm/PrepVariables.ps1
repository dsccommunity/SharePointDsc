#Requires -Version 5.1

##### GENERIC VARIABLES #####
$defaultFolder = $PSScriptRoot
$buildingBlockVersion = [System.Version]'1.0.0'

##### SUPPORTING FUNCTIONS #####
function Test-Credential
{
    [OutputType([Bool])]
    Param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias(
            'PSCredential'
        )]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [String]
        $Domain = $Credential.GetNetworkCredential().Domain
    )
    begin
    {
        Add-Type -assemblyname system.DirectoryServices.accountmanagement
        $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain)
    }
    process
    {
        $account = Split-Path -Path $credential.UserName -Leaf
        return $DS.ValidateCredentials($account, $credential.GetNetworkCredential().password)
    }
}

function Get-Accounts
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Account,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Description
    )

    if ($null -eq $global:credentials.UserName -or
        -not $global:credentials.UserName.Contains($Account))
    {
        $credential = Get-Credential $Account -Message $Description
        if (Test-Credential -Credential $credential)
        {
            $global:credentials += $credential
        }
        else
        {
            Write-Error "Incorrect credential"
        }
    }
}

##### SCRIPT START #####

Clear-Host
Write-Host 'Preparing variables for SharePoint deployment' -ForegroundColor Green

# Dialog for selecting PSD input file
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory = $defaultFolder
$dialog.Title = "Please select the DSC data file"
$dialog.Filter = "DSC Config (*.psd1) | *.psd1"
$result = $dialog.ShowDialog()

if ($result -eq "OK")
{
    Write-Host "Processing file: $($dialog.FileName)" -ForegroundColor DarkGray
    $global:ConfigPathFolder = Split-Path $dialog.FileName
    $ConfigFileName = $dialog.SafeFileName
    $ConfigFileName = $ConfigFileName -replace "\..+"
    $global:ConfigPathFull = $dialog.FileName
    $global:DataFile = Import-PowerShellDataFile $ConfigPathFull

    Write-Host 'Checking Building Block versions:' -ForegroundColor DarkGray
    $dataFileVersion = [System.Version]$DataFile.NonNodeData.BuildingBlock.Version
    Write-Host "  - Data file version : $($dataFileVersion.ToString())" -ForegroundColor DarkGray
    Write-Host "  - Script version    : $($buildingBlockVersion.ToString())" -ForegroundColor DarkGray
    if ($dataFileVersion -eq $buildingBlockVersion)
    {
        Write-Host 'Versions equal, proceeding...' -ForegroundColor DarkGray
    }
    else
    {
        Write-Host 'Versions do not match, please check the building block versions. Quiting!' -ForegroundColor Red
        break
    }

    # Initialize Credentials variable if it does not exist
    if ($null -eq $global:credentials)
    {
        $global:credentials = @()
    }

    # Initialize InstallAccount variable if it does not exist
    if ($null -eq $InstallAccount)
    {
        Write-Host 'Retrieving InstallAccount credentials' -ForegroundColor DarkGray
        $global:InstallAccount = Get-Credential -UserName (&whoami) -Message "Please provide your password"
        if ($null -eq $global:credentials.UserName -or
            -not $global:credentials.UserName.Contains($InstallAccount.UserName))
        {
            $global:credentials += $InstallAccount
        }
    }

    # Initialize PassPhrase variable if it does not exist
    if ($null -eq $PassPhrase)
    {
        Write-Host 'Retrieving Farm Pass Phrase' -ForegroundColor DarkGray
        $global:PassPhrase = Get-Credential "Farm Pass Phrase" -Message "Enter the SharePoint Farm PassPhrase"
    }

    # Initialize CertPassword variable if it does not exist
    if ($null -eq $CertPassword)
    {
        Write-Host 'Retrieving Certificate password' -ForegroundColor DarkGray
        $global:CertPassword = Get-Credential "Certificate Password" -Message "Enter the Certificate Password"
    }

    Write-Host 'Retrieving Service Account credentials' -ForegroundColor DarkGray
    Get-Accounts -Account $DataFile.NonNodeData.ManagedAccounts.Farm -Description "Farm Account"
    Get-Accounts -Account $DataFile.NonNodeData.ManagedAccounts.Services -Description "Generic Services Account"
    Get-Accounts -Account $DataFile.NonNodeData.ManagedAccounts.Search -Description "Generic Windows Search Service Account"
    Get-Accounts -Account $DataFile.NonNodeData.ManagedAccounts.UpsSync -Description "Generic User Profile Service Account"
    Get-Accounts -Account $DataFile.NonNodeData.ManagedAccounts.AppPool -Description "AppPool Account"
    Get-Accounts -Account $DataFile.NonNodeData.ServiceAccounts.ContentAccess -Description "Content Access Account"
    Get-Accounts -Account $DataFile.NonNodeData.ServiceAccounts.SuperReader -Description "Super Reader Account"
    Get-Accounts -Account $DataFile.NonNodeData.ServiceAccounts.SuperUser -Description "Super User Account"

    #Unblock files
    Write-Host 'Unblocking setup files in InstallFolder' -ForegroundColor DarkGray
    $path = 'C:\SPSources'
    if (Test-Path -Path $path)
    {
        Get-ChildItem -Path $path -Recurse | Unblock-File
    }
    else
    {
        Write-Host "Cannot unblock path: $path" -ForegroundColor Red
    }

    Write-Host "Completed processing!" -ForegroundColor DarkGray
}
else
{
    Write-Host "Operation Canceled!" -ForegroundColor Red
}
