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

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $RunCentralAdmin,

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

    Write-Verbose -Message "Getting the settings of the current local SharePoint Farm (if any)"

    if ($Ensure -eq "Absent")
    {
        throw ("SharePointDsc does not support removing a server from a farm, please set the " + `
               "ensure property to 'present'")
    }

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
    $dsnValue = Get-SPDSCRegistryKey -Key $regPath -Value "dsn" -ErrorAction SilentlyContinue

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
                FarmAccount = $farmAccount # Need to return this as a credential to match the type expected
                InstallAccount = $null
                Passphrase = $null 
                AdminContentDatabaseName = $centralAdminSite.ContentDatabases[0].Name
                CentralAdministrationPort = (New-Object -TypeName System.Uri $centralAdminSite.Url).Port
                CentralAdministrationAuth = $params.CentralAdministrationAuth #TODO: Need to return this as the current value
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
    # Supressing the global variable use to allow passing DSC the reboot message
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
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

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $RunCentralAdmin,

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

    if ($Ensure -eq "Absent")
    {
        throw ("SharePointDsc does not support removing a server from a farm, please set the " + `
               "ensure property to 'present'")
    }

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
                                        -Arguments @($PSBoundParameters, $PSScriptRoot) `
                                        -ScriptBlock {
        $params = $args[0]
        $scriptRoot = $args[1]

        $modulePath = "..\..\Modules\SharePointDsc.Farm\SPFarm.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)
        $dbStatus = Get-SPDSCConfigDBStatus -SQLServer $params.DatabaseServer `
                                            -Database $params.FarmConfigDatabaseName

        while ($dbStatus.Locked -eq $true)
        {
            Write-Verbose -Message ("[$([DateTime]::Now.ToShortTimeString())] The configuration " + `
                                    "database is currently being provisioned by a remote " + `
                                    "server, this server will wait for this to complete")
            Start-Sleep -Seconds 30
            $dbStatus = Get-SPDSCConfigDBStatus -SQLServer $params.DatabaseServer `
                                                -Database $params.FarmConfigDatabaseName
        }

        if ($dbStatus.ValidPermissions -eq $false)
        {
            throw "The current user does not have sufficient permissions to SQL Server"
            return
        }

        $executeArgs = @{
            DatabaseServer = $params.DatabaseServer
            DatabaseName = $params.FarmConfigDatabaseName
            Passphrase = $params.Passphrase.Password
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
                    $executeArgs.Add("LocalServerRole", $params.ServerRole)
                } else {
                    Write-Verbose -Message ("Detected Version: SharePoint 2016 - no server " + `
                                            "role provided, configuring server without a " + `
                                            "specific role")
                    $executeArgs.Add("ServerRoleOptional", $true)
                }
            }
            Default {
                throw [Exception] ("An unknown version of SharePoint (Major version $_) " + `
                                    "was detected. Only versions 15 (SharePoint 2013) or " + `
                                    "16 (SharePoint 2016) are supported.")
            }
        }

        if ($dbStatus.DatabaseExists -eq $true) 
        {
            Write-Verbose -Message ("The SharePoint config database " + `
                                    "'$($params.FarmConfigDatabaseName)' already exists, so " + `
                                    "this server will join the farm.")
            $createFarm = $false
        }
        elseif ($dbStatus.DatabaseExists -eq $false -and $params.RunCentralAdmin -eq $false)
        {
            # Only allow the farm to be created by a server that will run central admin
            # to avoid a ghost CA site appearing on this server and causing issues
            Write-Verbose -Message ("The SharePoint config database " + `
                                    "'$($params.FarmConfigDatabaseName)' does not exist, but " + `
                                    "this server will not be running the central admin " + `
                                    "website, so it will wait to join the farm rather than " + `
                                    "create one.")
            $createFarm = $false
        }
        else 
        {
            Write-Verbose -Message ("The SharePoint config database " + `
                                    "'$($params.FarmConfigDatabaseName)' does not exist, so " + `
                                    "this server will create the farm.")
            $createFarm = $true
        }

        $farmAction = ""
        if ($createFarm -eq $false)
        {            
            # The database exists, so attempt to join the farm to the server
            

            # Remove the server role optional attribute as it is only used when creating
            # a new farm
            if ($executeArgs.ContainsKey("ServerRoleOptional") -eq $true)
            {
                $executeArgs.Remove("ServerRoleOptional") 
            }
            
            Write-Verbose -Message ("The server will attempt to join the farm now once every " + `
                                    "60 seconds for the next 15 minutes.")
            $loopCount = 0
            $connectedToFarm = $false
            $lastException = $null
            while ($connectedToFarm -eq $false -and $loopCount -lt 15)
            {
                try 
                {
                    $joinObject = Connect-SPConfigurationDatabase @executeArgs
                    $connectedToFarm = $true
                }
                catch 
                {
                    $lastException = $_.Exception
                    Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - An error " + `
                                            "occured joining config database " + `
                                            "'$($params.FarmConfigDatabaseName)' on " + `
                                            "'$($params.DatabaseServer)'. This resource will " + `
                                            "wait and retry automatically for up to 15 minutes. " + `
                                            "(waited $loopCount of 15 minutes)")
                    $loopCount++
                    Start-Sleep -Seconds 60
                }
            }

            if ($connectedToFarm -eq $false)
            {
                Write-Verbose -Message ("Unable to join config database. Throwing exception.")
                throw $lastException
                return
            }
            $farmAction = "JoinedFarm"
        }
        else
        {
            Add-SPDscConfigDBLock -SQLServer $params.DatabaseServer `
                                  -Database $params.FarmConfigDatabaseName

            try 
            {
                $executeArgs += @{
                    FarmCredentials = $params.FarmAccount
                    AdministrationContentDatabaseName = $params.AdminContentDatabaseName
                }

                New-SPConfigurationDatabase @executeArgs

                $farmAction = "CreatedFarm"
            }
            finally
            {
                Remove-SPDscConfigDBLock -SQLServer $params.DatabaseServer `
                                         -Database $params.FarmConfigDatabaseName
            }
        }

        # Run common tasks for a new server
        Install-SPHelpCollection -All | Out-Null 
        Initialize-SPResourceSecurity | Out-Null 
        Install-SPService | Out-Null 
        Install-SPFeature -AllExistingFeatures -Force | Out-Null 

        # Provision central administration
        if ($params.RunCentralAdmin -eq $true)
        {
            $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                                | Where-Object -FilterScript { 
                                    $_.IsAdministrationWebApplication -eq $true 
                                }

            
            $centralAdminProvisioned = $false
            if ((New-Object -TypeName System.Uri $centralAdminSite.Url).Port -eq $params.CentralAdministrationPort)
            {
                $centralAdminProvisioned = $true
            }
            
            if ($centralAdminProvisioned -eq $false)
            {
                New-SPCentralAdministration -Port $params.CentralAdministrationPort `
                                            -WindowsAuthProvider $params.CentralAdministrationAuth
            }
            else 
            {
                $serviceInstance = Get-SPServiceInstance -Server $env:COMPUTERNAME `
                                        | Where-Object -FilterScript {
                                            $_.TypeName -eq "Central Administration"
                                        }
                if ($null -eq $serviceInstance) 
                { 
                    $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                    $fqdn = "$($env:COMPUTERNAME).$domain"
                    $serviceInstance = Get-SPServiceInstance -Server $fqdn `
                                        | Where-Object -FilterScript {
                                            $_.TypeName -eq "Central Administration"
                                        }
                }
                if ($null -eq $serviceInstance) 
                { 
                    throw [Exception] "Unable to locate Central Admin service instance on this server"
                }
                Start-SPServiceInstance -Identity $serviceInstance 
            }
        }

        Install-SPApplicationContent | Out-Null 

        return $farmAction
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

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $RunCentralAdmin,

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
