function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure,
        
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

    Write-Verbose -Message "Getting teh settings of the current local SharePoint Farm (if any)"

    $installedVersion = Get-SPDSCInstalledProductVersion
    switch ($installedVersion.FileMajorPart)
    {
        15 {
            Write-Verbose -Message "Detected installation of SharePoint 2013"
        }
        16 {
            Write-Verbose -Message "Detected installation of SharePoint 2013"
        }
        default {
            throw ("Detected an unsupported major version of SharePoint. SharePointDsc only " + `
                   "supports SharePoint 2013 or 2016.")
        }
    }


    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) `
        -and $installedVersion.FileMajorPart -ne 16) 
    {
        throw [Exception] "Server role is only supported in SharePoint 2016."
    }

    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) `
        -and $installedVersion.FileMajorPart -eq 16 `
        -and $installedVersion.FileBuildPart -lt 4456 `
        -and ($ServerRole -eq "ApplicationWithSearch" `
             -or $ServerRole -eq "WebFrontEndWithDistributedCache")) 
    {
        throw [Exception] ("ServerRole values of 'ApplicationWithSearch' or " + `
                           "'WebFrontEndWithDistributedCache' require the SharePoint 2016 " + `
                           "Feature Pack 1 to be installed. See " + `
                           "https://support.microsoft.com/en-au/kb/3127940")
    }


    # Determine if a connection to a farm already exists
    $majorVersion = $installedVersion.FileMajorPart
    $regPath = "hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\$majorVersion.0\Secure\ConfigDB"
    $dsnValue = Get-SPDSCRegistryKey -Key $regPath -Value "dsn"

    if ($null -ne $dsnValue)
    {
        # This node has already been connected to a farm
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
                return $null
            }
            
            if ($null -eq $spFarm) 
            { 
                return $null 
            }

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

        if ($null -eq $result)
        {
            # The node is currently connected to a farm but was unable to retrieve the values
            # of current farm settings, most likely due to connectivity issues with the SQL box
            Write-Verbose -Message ("This server appears to be connected to a farm already, " + `
                                    "but the configuration database is currently unable to be " + `
                                    "accessed. Values returned from the get method will be " + `
                                    "incomplete, however the 'Ensure' property should be " + `
                                    "considered correct")
            return @{
                FarmConfigDatabaseName = $null
                DatabaseServer = $null
                FarmAccount = $null
                InstallAccount = $null
                Passphrase = $null 
                AdminContentDatabaseName = $null
                CentralAdministrationPort = $null
                CentralAdministrationAuth = $null
                Ensure = "Present"
            }
        }
        else
        {
            $result.Add("Ensure", "Present")
            return $result
        }
    }
    else 
    {
        # This node has never been connected to a farm, return the null return object
        return @{
            FarmConfigDatabaseName = $null
            DatabaseServer = $null
            FarmAccount = $null
            InstallAccount = $null
            Passphrase = $null 
            AdminContentDatabaseName = $null
            CentralAdministrationPort = $null
            CentralAdministrationAuth = $null
            Ensure = "Absent"
        }
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure,
        
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
    
    Write-Verbose -Message "Setting local SP Farm settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($CurrentValues.Ensure -eq "Present")
    {
        throw ("This server is already connected to a farm. " + `
               "Please manually remove it to apply this change.")
    }
    

    # Set default values to ensure they are passed to Invoke-SPDSCCommand
    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationPort")) 
    { 
        $PSBoundParameters.Add("CentralAdministrationPort", 9999) 
    }
    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationAuth")) 
    { 
        $PSBoundParameters.Add("CentralAdministrationAuth", "NTLM") 
    }
    
    $actionResult = Invoke-SPDSCCommand -Credential $InstallAccount `
                                        -Arguments $PSBoundParameters `
                                        -ScriptBlock {
        $params = $args[0]

        $modulePath = "..\..\Modules\SharePointDsc.SPFarm\SPFarm.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)
        $dbStatus = Get-SPDSCConfigDBStatus -SQLServer $params.DatabaseServer -Database $params.FarmConfigDatabaseName

        if ($dbStatus.ValidPermissions -eq $false)
        {
            throw "The current user does not have sufficient permissions to SQL Server"
            return
        }

        if ($dbStatus.DatabaseExists)
        {
            # The database exists, so attempt to join the farm to the server
            $joinFarmArgs = @{
                DatabaseServer = $params.DatabaseServer
                DatabaseName = $params.FarmConfigDatabaseName
                Passphrase = $params.Passphrase.password
                SkipRegisterAsDistributedCacheHost = $true
            }
            
            switch((Get-SPDSCInstalledProductVersion).FileMajorPart) {
                15 {
                    Write-Verbose -Message "Detected Version: SharePoint 2013"
                }
                16 {
                    if ($params.ContainsKey("ServerRole") -eq $true) {
                        Write-Verbose -Message ("Detected Version: SharePoint 2016 - " + `
                                                "configuring server as $($params.ServerRole)")
                        $joinFarmArgs.Add("LocalServerRole", $params.ServerRole)
                    } else {
                        Write-Verbose -Message ("Detected Version: SharePoint 2016 - no server " + `
                                                "role provided, configuring server without a " + `
                                                "specific role")
                    }
                }
                Default {
                    throw [Exception] ("An unknown version of SharePoint (Major version $_) " + `
                                       "was detected. Only versions 15 (SharePoint 2013) or " + `
                                       "16 (SharePoint 2016) are supported.")
                }
            }

            Connect-SPConfigurationDatabase @joinFarmArgs
            Install-SPHelpCollection -All
            Initialize-SPResourceSecurity
            Install-SPService
            Install-SPFeature -AllExistingFeatures -Force  | Out-Null 
            Install-SPApplicationContent

            return "JoinedFarm"
        }
        else
        {
            # The database does not exist, so create the farm
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

            #TODO: Handle which servers will get central admin 
            New-SPCentralAdministration -Port $params.CentralAdministrationPort `
                                        -WindowsAuthProvider $params.CentralAdministrationAuth
            Install-SPApplicationContent

            return "CreatedFarm"
        }
    }

    if ($actionResult -eq "JoinedFarm")
    {
        Write-Verbose -Message "Starting timer service"
        Start-Service -Name sptimerv4

        Write-Verbose -Message ("Pausing for 5 minutes to allow the timer service to " + `
                                "fully provision the server")
        Start-Sleep -Seconds 300
        Write-Verbose -Message ("Join farm complete. Restarting computer to allow " + `
                                "configuration to continue")

        $global:DSCMachineStatus = 1
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure,
        
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

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
