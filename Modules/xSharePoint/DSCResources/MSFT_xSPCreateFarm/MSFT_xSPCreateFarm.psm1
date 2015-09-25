function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $FarmConfigDatabaseName,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [System.String] $Passphrase,
        [parameter(Mandatory = $true)]  [System.String] $AdminContentDatabaseName,
        [parameter(Mandatory = $false)] [System.UInt32] $CentralAdministrationPort
    )

    Write-Verbose -Message "Checking for local SP Farm"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        try {
            $spFarm = Get-SPFarm
        } catch {
            Write-Verbose -Message "Unable to detect local farm."
        }
        
        if ($null -eq $spFarm) { return $null }

        $configDb = Get-SPDatabase | Where-Object { $_.Name -eq $spFarm.Name -and $_.Type -eq "Configuration Database" }
        $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration | Where-Object { $_.IsAdministrationWebApplication -eq $true }

        if ($params.FarmAccount.UserName -eq $spFarm.DefaultServiceAccount.Name) {
            $farmAccount = $params.FarmAccount
        } else {
            $farmAccount = $spFarm.DefaultServiceAccount.Name
        }

        $returnValue = @{
            FarmConfigDatabaseName = $spFarm.Name
            DatabaseServer = $configDb.Server.Name
            FarmAccount = $farmAccount
            InstallAccount = $params.InstallAccount
            Passphrase = $params.Passphrase
            AdminContentDatabaseName = $centralAdminSite.ContentDatabases[0].Name
            CentralAdministrationPort = (New-Object System.Uri $centralAdminSite.Url).Port
        }
        return $returnValue
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $FarmConfigDatabaseName,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [System.String] $Passphrase,
        [parameter(Mandatory = $true)]  [System.String] $AdminContentDatabaseName,
        [parameter(Mandatory = $false)] [System.UInt32] $CentralAdministrationPort
    )
    
    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationPort")) { $PSBoundParameters.Add("CentralAdministrationPort", 9999) }

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $newFarmArgs = @{
            DatabaseServer = $params.DatabaseServer
            DatabaseName = $params.FarmConfigDatabaseName
            FarmCredentials = $params.FarmAccount
            AdministrationContentDatabaseName = $params.AdminContentDatabaseName
            Passphrase = (ConvertTo-SecureString -String $params.Passphrase -AsPlainText -force)
            SkipRegisterAsDistributedCacheHost = $true
        }
        
        switch((Get-xSharePointInstalledProductVersion).FileMajorPart) {
            15 {
                Write-Verbose -Message "Detected Version: SharePoint 2013"
            }
            16 {
                Write-Verbose -Message "Detected Version: SharePoint 2016"
                $newFarmArgs.Add("LocalServerRole", "Custom")
            }
            Default {
                throw [Exception] "An unknown version of SharePoint (Major version $_) was detected. Only versions 15 (SharePoint 2013) or 16 (SharePoint 2016) are supported."
            }
        }

        New-SPConfigurationDatabase @newFarmArgs
        Install-SPHelpCollection -All
        Initialize-SPResourceSecurity
        Install-SPService
        Install-SPFeature -AllExistingFeatures -Force 
        New-SPCentralAdministration -Port $params.CentralAdministrationPort -WindowsAuthProvider "NTLM"
        Install-SPApplicationContent
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $FarmConfigDatabaseName,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [System.String] $Passphrase,
        [parameter(Mandatory = $true)]  [System.String] $AdminContentDatabaseName,
        [parameter(Mandatory = $false)] [System.UInt32] $CentralAdministrationPort
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose "Checking for local farm presence"
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("FarmConfigDatabaseName")
}

Export-ModuleMember -Function *-TargetResource
