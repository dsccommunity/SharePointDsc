function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $FarmConfigDatabaseName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseServer,

        [parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $FarmAccount,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

        [parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $Passphrase,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $AdminContentDatabaseName,

        [parameter(Mandatory = $false)] 
        [System.UInt32] 
        $CentralAdministrationPort,

        [parameter(Mandatory = $false)] 
        [System.String] 
        [ValidateSet("NTLM","Kerberos")]
        $CentralAdministrationAuth,

        [parameter(Mandatory = $false)] 
        [System.String] 
        [ValidateSet("Application",
                     "ApplicationWithSearch",
                     "Custom",
                     "DistributedCache",
                     "Search",
                     "SingleServer",
                     "SingleServerFarm",
                     "WebFrontEnd",
                     "WebFrontEndWithDistributedCache")] 
        $ServerRole
    )

    Write-Verbose -Message ("WARNING! SPCreateFarm is deprecated and will be removed in " + `
                            "SharePointDsc v2.0. Swap to use the new SPFarm resource as " + `
                            "an alternative. See http://aka.ms/SPDsc-SPFarm for details.")

    Write-Verbose -Message "Getting local SP Farm settings"

    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) `
        -and (Get-SPDSCInstalledProductVersion).FileMajorPart -ne 16) 
    {
        throw [Exception] "Server role is only supported in SharePoint 2016."
    }

    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) `
        -and (Get-SPDSCInstalledProductVersion).FileMajorPart -eq 16 `
        -and (Get-SPDSCInstalledProductVersion).FileBuildPart -lt 4456 `
        -and ($ServerRole -eq "ApplicationWithSearch" `
             -or $ServerRole -eq "WebFrontEndWithDistributedCache")) 
    {
        throw [Exception] ("ServerRole values of 'ApplicationWithSearch' or " + `
                           "'WebFrontEndWithDistributedCache' require the SharePoint 2016 " + `
                           "Feature Pack 1 to be installed. See " + `
                           "https://support.microsoft.com/en-au/kb/3127940")
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        try 
        {
            $spFarm = Get-SPFarm
        } 
        catch 
        {
            Write-Verbose -Message "Unable to detect local farm."
        }
        
        if ($null -eq $spFarm) { return $null }

        $configDb = Get-SPDatabase | Where-Object -FilterScript { 
            $_.Name -eq $spFarm.Name -and $_.Type -eq "Configuration Database" 
        }
        $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                            | Where-Object -FilterScript { 
            $_.IsAdministrationWebApplication -eq $true 
        }

        if ($params.FarmAccount.UserName -eq $spFarm.DefaultServiceAccount.Name) 
        {
            $farmAccount = $params.FarmAccount
        } 
        else 
        {
            $farmAccount = $spFarm.DefaultServiceAccount.Name
        }

        $returnValue = @{
            FarmConfigDatabaseName = $spFarm.Name
            DatabaseServer = $configDb.Server.Name
            FarmAccount = $farmAccount
            InstallAccount = $params.InstallAccount
            Passphrase = $params.Passphrase.password 
            AdminContentDatabaseName = $centralAdminSite.ContentDatabases[0].Name
            CentralAdministrationPort = (New-Object -TypeName System.Uri $centralAdminSite.Url).Port
            CentralAdministrationAuth = $params.CentralAdministrationAuth
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $FarmConfigDatabaseName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseServer,

        [parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $FarmAccount,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

        [parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $Passphrase,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $AdminContentDatabaseName,

        [parameter(Mandatory = $false)] 
        [System.UInt32] 
        $CentralAdministrationPort,

        [parameter(Mandatory = $false)] 
        [System.String] 
        [ValidateSet("NTLM","Kerberos")]
        $CentralAdministrationAuth,

        [parameter(Mandatory = $false)] 
        [System.String] 
        [ValidateSet("Application",
                     "ApplicationWithSearch",
                     "Custom",
                     "DistributedCache",
                     "Search",
                     "SingleServer",
                     "SingleServerFarm",
                     "WebFrontEnd",
                     "WebFrontEndWithDistributedCache")] 
        $ServerRole
    )
    
    Write-Verbose -Message ("WARNING! SPCreateFarm is deprecated and will be removed in " + `
                            "SharePointDsc v2.0. Swap to use the new SPFarm resource as " + `
                            "an alternative. See http://aka.ms/SPDsc-SPFarm for details.")

    Write-Verbose -Message "Setting local SP Farm settings"

    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) `
        -and (Get-SPDSCInstalledProductVersion).FileMajorPart -ne 16) 
    {
        throw [Exception] "Server role is only supported in SharePoint 2016."
    }

    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) `
        -and (Get-SPDSCInstalledProductVersion).FileMajorPart -eq 16 `
        -and (Get-SPDSCInstalledProductVersion).FileBuildPart -lt 4456 `
        -and ($ServerRole -eq "ApplicationWithSearch" `
             -or $ServerRole -eq "WebFrontEndWithDistributedCache")) 
    {
        throw [Exception] ("ServerRole values of 'ApplicationWithSearch' or " + `
                           "'WebFrontEndWithDistributedCache' require the SharePoint 2016 " + `
                           "Feature Pack 1 to be installed. See " + `
                           "https://support.microsoft.com/en-au/kb/3127940")
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ([string]::IsNullOrEmpty($CurrentValues.FarmConfigDatabaseName) -eq $false) 
    {
        throw ("This server is already connected to a farm " + `
               "($($CurrentValues.FarmConfigDatabaseName)). Please manually remove it " + `
               "to apply this change.")
    }

    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationPort")) 
    { 
        $PSBoundParameters.Add("CentralAdministrationPort", 9999) 
    }
    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationAuth")) 
    { 
        $PSBoundParameters.Add("CentralAdministrationAuth", "NTLM") 
    }
    
    Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $newFarmArgs = @{
            DatabaseServer = $params.DatabaseServer
            DatabaseName = $params.FarmConfigDatabaseName
            FarmCredentials = $params.FarmAccount
            AdministrationContentDatabaseName = $params.AdminContentDatabaseName
            Passphrase = ($params.Passphrase).Password
            SkipRegisterAsDistributedCacheHost = $true
        }
        
        switch((Get-SPDSCInstalledProductVersion).FileMajorPart) 
        {
            15 {
                Write-Verbose -Message "Detected Version: SharePoint 2013"
            }
            16 {
                if ($params.ContainsKey("ServerRole") -eq $true) 
                {
                    Write-Verbose -Message ("Detected Version: SharePoint 2016 - " + `
                                            "configuring server as $($params.ServerRole)")
                    $newFarmArgs.Add("LocalServerRole", $params.ServerRole)
                } 
                else 
                {
                    Write-Verbose -Message ("Detected Version: SharePoint 2016 - no " + `
                                            "server role provided, configuring server " + `
                                            "without a specific role")
                    $newFarmArgs.Add("ServerRoleOptional", $true)
                }
            }
            Default {
                throw [Exception] ("An unknown version of SharePoint (Major version $_) was " + `
                                   "detected. Only versions 15 (SharePoint 2013) or 16 " + `
                                   "(SharePoint 2016) are supported.")
            }
        }

        New-SPConfigurationDatabase @newFarmArgs
        Install-SPHelpCollection -All
        Initialize-SPResourceSecurity
        Install-SPService
        Install-SPFeature -AllExistingFeatures -Force 
        New-SPCentralAdministration -Port $params.CentralAdministrationPort `
                                    -WindowsAuthProvider $params.CentralAdministrationAuth
        Install-SPApplicationContent
    } | Out-Null
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $FarmConfigDatabaseName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseServer,

        [parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $FarmAccount,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

        [parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $Passphrase,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $AdminContentDatabaseName,

        [parameter(Mandatory = $false)] 
        [System.UInt32] 
        $CentralAdministrationPort,

        [parameter(Mandatory = $false)] 
        [System.String] 
        [ValidateSet("NTLM","Kerberos")]
        $CentralAdministrationAuth,

        [parameter(Mandatory = $false)] 
        [System.String] 
        [ValidateSet("Application",
                     "ApplicationWithSearch",
                     "Custom",
                     "DistributedCache",
                     "Search",
                     "SingleServer",
                     "SingleServerFarm",
                     "WebFrontEnd",
                     "WebFrontEndWithDistributedCache")] 
        $ServerRole
    )

    Write-Verbose -Message "Testing local SP Farm settings"

    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) `
        -and (Get-SPDSCInstalledProductVersion).FileMajorPart -ne 16) 
    {
        throw [Exception] "Server role is only supported in SharePoint 2016."
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues)
    {
        return $false
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("FarmConfigDatabaseName")
}

Export-ModuleMember -Function *-TargetResource
