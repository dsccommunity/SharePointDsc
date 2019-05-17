function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Passphrase,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AdminContentDatabaseName,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $RunCentralAdmin,

        [Parameter()]
        [System.String]
        $CentralAdministrationUrl,

        [Parameter()]
        [System.UInt32]
        $CentralAdministrationPort,

        [Parameter()]
        [System.String]
        [ValidateSet("NTLM","Kerberos")]
        $CentralAdministrationAuth,

        [Parameter()]
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
        $ServerRole,

        [Parameter()]
        [ValidateSet("Off","On","OnDemand")]
        [System.String]
        $DeveloperDashboard,


        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting the settings of the current local SharePoint Farm (if any)"

    if ($PSBoundParameters.ContainsKey("CentralAdministrationPort"))
    {
        if ($CentralAdministrationPort -notin 1..65535)
        {
            throw ("An invalid value for CentralAdministrationPort is specified: " + `
                   "$CentralAdministrationPort")
        }
    }

    if ($PSBoundParameters.ContainsKey("CentralAdministrationUrl"))
    {
        $uri = $CentralAdministrationUrl -as [System.Uri]
        if ($null -eq $uri.AbsoluteUri)
        {
            throw "CentralAdministrationUrl is not a valid URI. It should include the scheme (http/https) and address."
        }
        if ($uri.scheme -ne 'https')
        {
            throw "Currently, the CentralAdministrationUrl parameter can only be used with HTTPS. To provision CA on " + `
                  "HTTP, omit the CentralAdministrationUrl parameter to provision CA on http://servername:port."
        }
        if ($CentralAdministrationUrl -match ':\d+')
        {
            throw "CentralAdministrationUrl should not specify port. Use CentralAdministrationPort instead."
        }
    }

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
            if ($DeveloperDashboard -eq "OnDemand")
            {
                throw ("The DeveloperDashboard value 'OnDemand' is not allowed in SharePoint " + `
                       "2016 and 2019")
            }

            if ($DeveloperDashboard -eq "On")
            {
                Write-Verbose -Message ("Please make sure you also provision the Usage and Health " + `
                                        "service application to make sure the Developer Dashboard " + `
                                        "works properly")
            }

            if ($installedVersion.ProductBuildPart.ToString().Length -eq 4)
            {
                Write-Verbose -Message "Detected installation of SharePoint 2016"
            }
            else
            {
                Write-Verbose -Message "Detected installation of SharePoint 2019"
            }
        }
        default {
            throw ("Detected an unsupported major version of SharePoint. SharePointDsc only " + `
                   "supports SharePoint 2013, 2016 or 2019.")
        }
    }

    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) `
        -and $installedVersion.FileMajorPart -ne 16)
    {
        throw [Exception] "Server role is only supported in SharePoint 2016 and 2019."
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
                           "https://support.microsoft.com/en-us/kb/3127940")
    }


    # Determine if a connection to a farm already exists
    $majorVersion = $installedVersion.FileMajorPart
    $regPath      = "hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\$majorVersion.0\Secure\ConfigDB"
    $dsnValue     = Get-SPDSCRegistryKey -Key $regPath -Value "dsn" -ErrorAction SilentlyContinue

    if ($null -ne $dsnValue)
    {
        Write-Verbose -Message "This node has already been connected to a farm"
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

            if ($params.FarmAccount.UserName -eq $spFarm.DefaultServiceAccount.Name)
            {
                $farmAccount = $params.FarmAccount
            }
            else
            {
                $farmAccount = $spFarm.DefaultServiceAccount.Name
            }

            $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                                    | Where-Object -FilterScript {
                                        $_.IsAdministrationWebApplication -eq $true
                                    }

            $centralAdminProvisioned = $false
            $ca = Get-SPServiceInstance -Server $env:ComputerName
            if ($null -ne $ca)
            {
                $ca = $ca | Where-Object -Filterscript {
                          $_.GetType().Name -eq "SPWebServiceInstance" -and `
                          $_.Name -eq "WSS_Administration" -and `
                          $_.Status -eq "Online"
                      }
            }

            if ($null -ne $ca)
            {
                $centralAdminProvisioned = $true
            }

            $centralAdminAuth = $null
            if ($null -ne $centralAdminSite -and `
                $centralAdminSite.IisSettings[0].DisableKerberos -eq $false)
            {
                $centralAdminAuth = "Kerberos"
            }
            else
            {
                $centralAdminAuth = "NTLM"
            }

            $admService                 = Get-SPDSCContentService
            $developerDashboardSettings = $admService.DeveloperDashboardSettings
            $developerDashboardStatus   = $developerDashboardSettings.DisplayLevel

            $returnValue = @{
                IsSingleInstance          = "Yes"
                FarmConfigDatabaseName    = $spFarm.Name
                DatabaseServer            = $configDb.NormalizedDataSource
                FarmAccount               = $farmAccount # Need to return this as a credential to match the type expected
                Passphrase                = $null
                AdminContentDatabaseName  = $centralAdminSite.ContentDatabases[0].Name
                RunCentralAdmin           = $centralAdminProvisioned
                CentralAdministrationUrl  = $centralAdminSite.Url.TrimEnd('/')
                CentralAdministrationPort = (New-Object -TypeName System.Uri $centralAdminSite.Url).Port
                CentralAdministrationAuth = $centralAdminAuth
                DeveloperDashboard        = $developerDashboardStatus
            }
            $installedVersion = Get-SPDSCInstalledProductVersion
            if ($installedVersion.FileMajorPart -eq 16)
            {
                $server = Get-SPServer -Identity $env:COMPUTERNAME -ErrorAction SilentlyContinue
                if ($null -ne $server -and $null -ne $server.Role)
                {
                    $returnValue.Add("ServerRole", $server.Role)
                }
                else
                {
                    $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                    $currentServer = "$($env:COMPUTERNAME).$domain"

                    $server = Get-SPServer -Identity $currentServer -ErrorAction SilentlyContinue
                    if ($null -ne $server -and $null -ne $server.Role)
                    {
                        $returnValue.Add("ServerRole", $server.Role)
                    }
                }
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
                IsSingleInstance          = "Yes"
                FarmConfigDatabaseName    = $null
                DatabaseServer            = $null
                FarmAccount               = $null
                Passphrase                = $null
                AdminContentDatabaseName  = $null
                RunCentralAdmin           = $null
                CentralAdministrationUrl  = $null
                CentralAdministrationPort = $null
                CentralAdministrationAuth = $null
                Ensure                    = "Present"
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
        Write-Verbose -Message "This node has never been connected to a farm"
        # Return the null return object
        return @{
            IsSingleInstance          = "Yes"
            FarmConfigDatabaseName    = $null
            DatabaseServer            = $null
            FarmAccount               = $null
            Passphrase                = $null
            AdminContentDatabaseName  = $null
            RunCentralAdmin           = $null
            CentralAdministrationUrl  = $null
            CentralAdministrationPort = $null
            CentralAdministrationAuth = $null
            Ensure                    = "Absent"
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
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Passphrase,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AdminContentDatabaseName,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $RunCentralAdmin,

        [Parameter()]
        [System.String]
        $CentralAdministrationUrl,

        [Parameter()]
        [System.UInt32]
        $CentralAdministrationPort,

        [Parameter()]
        [System.String]
        [ValidateSet("NTLM","Kerberos")]
        $CentralAdministrationAuth,

        [Parameter()]
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
        $ServerRole,

        [Parameter()]
        [ValidateSet("Off","On","OnDemand")]
        [System.String]
        $DeveloperDashboard,


        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting local SP Farm settings"

    if ($Ensure -eq "Absent")
    {
        throw ("SharePointDsc does not support removing a server from a farm, please set the " + `
               "ensure property to 'present'")
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    # Set default values to ensure they are passed to Invoke-SPDSCCommand
    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationPort"))
    {
        # If CentralAdministrationUrl is specified and is SSL, let's infer the port from the Url
        if ($PSBoundParameters.ContainsKey("CentralAdministrationUrl") -and `
            (New-Object -TypeName System.Uri $CentralAdministrationUrl).Scheme -eq 'https')
        {
            $PSBoundParameters.Add("CentralAdministrationPort", (New-Object -TypeName System.Uri $CentralAdministrationUrl).Port)
        }
        else
        {
            $PSBoundParameters.Add("CentralAdministrationPort", 9999)
        }
    }

    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationAuth"))
    {
        $PSBoundParameters.Add("CentralAdministrationAuth", "NTLM")
    }

    if ($CurrentValues.Ensure -eq "Present")
    {
        Write-Verbose -Message "Server already part of farm, updating settings"

        if ($CurrentValues.RunCentralAdmin -ne $RunCentralAdmin)
        {
            Invoke-SPDSCCommand -Credential $InstallAccount `
                                -Arguments $PSBoundParameters `
                                -ScriptBlock {
                $params = $args[0]

                # Provision central administration
                if ($params.RunCentralAdmin -eq $true)
                {
                    Write-Verbose -Message "RunCentralAdmin set to true, provisioning Central Admin"
                    $serviceInstance = Get-SPServiceInstance -Server $env:COMPUTERNAME
                    if ($null -eq $serviceInstance)
                    {
                        $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                        $fqdn   = "$($env:COMPUTERNAME).$domain"
                        $serviceInstance = Get-SPServiceInstance -Server $fqdn
                    }

                    if ($null -ne $serviceInstance)
                    {
                        $serviceInstance = $serviceInstance | Where-Object -FilterScript {
                                               $_.GetType().Name -eq "SPWebServiceInstance" -and `
                                               $_.Name -eq "WSS_Administration"
                                           }
                    }

                    if ($null -eq $serviceInstance)
                    {
                        throw [Exception] "Unable to locate Central Admin service instance on this server"
                    }
                    Start-SPServiceInstance -Identity $serviceInstance
                }
                else
                {
                    Write-Verbose -Message "RunCentralAdmin set to false, unprovisioning Central Admin"
                    $serviceInstance = Get-SPServiceInstance -Server $env:COMPUTERNAME
                    if ($null -eq $serviceInstance)
                    {
                        $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                        $fqdn   = "$($env:COMPUTERNAME).$domain"
                        $serviceInstance = Get-SPServiceInstance -Server $fqdn
                    }

                    if ($null -ne $serviceInstance)
                    {
                        $serviceInstance = $serviceInstance | Where-Object -FilterScript {
                                               $_.GetType().Name -eq "SPWebServiceInstance" -and `
                                               $_.Name -eq "WSS_Administration"
                                           }
                    }

                    if ($null -eq $serviceInstance)
                    {
                        throw "Unable to locate Central Admin service instance on this server"
                    }
                    Stop-SPServiceInstance -Identity $serviceInstance
                }
            }
        }

        if ($RunCentralAdmin)
        {
            # For the following SSL scenarios, we should remove the CA web application and recreate it
            #   CentralAdministrationUrl is HTTPS
            #   AND     Current CentralAdministrationUrl is not equal to new CentralAdministrationUrl
            #       OR  Current SecureBindings does not exist or doesn't match desired url and port
            if ($PSBoundParameters.ContainsKey("CentralAdministrationUrl") -and `
                ([System.Uri]$CentralAdministrationUrl).Scheme -eq 'https')
            {
                Write-Verbose -Message "Updating CentralAdmin port to HTTPS"
                Invoke-SPDSCCommand -Credential $InstallAccount `
                                    -Arguments $PSBoundParameters `
                                    -ScriptBlock {
                    $params = $args[0]

                    $reprovisionCentralAdmin = $false
                    $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
                        $_.IsAdministrationWebApplication
                    }

                    $desiredUri = [System.Uri]("{0}:{1}" -f $params.CentralAdministrationUrl.TrimEnd('/'), $params.CentralAdministrationPort)
                    $currentUri = [System.Uri]$centralAdminSite.Url
                    if ($desiredUri.AbsoluteUri -ne $currentUri.AbsoluteUri)
                    {
                        Write-Verbose -Message "Re-provisioning CA because $($currentUri.AbsoluteUri) does not equal $($desiredUri.AbsoluteUri)"
                        $reprovisionCentralAdmin = $true
                    }
                    else
                    {
                        # check securebindings
                        # there should be an entry in the SecureBindings object of the
                        # SPWebApplication's IisSettings for the default zone
                        $secureBindings = $centralAdminSite.GetIisSettingsWithFallback("Default").SecureBindings
                        if ($null -ne $secureBindings[0] -and (-not [string]::IsNullOrEmpty($secureBindings[0].HostHeader)))
                        {
                            # check to see if secureBindings host header and port match what we want them to be
                            if ($desiredUri.Host -ne $secureBindings[0].HostHeader -or `
                                $desiredUri.Port -ne $secureBindings[0].Port)
                            {
                                Write-Verbose -Message "Re-provisioning CA because $($desiredUri.Host) does not equal $($secureBindings[0].HostHeader) or $($desiredUri.Port) does not equal $($secureBindings[0].Port)"
                                $reprovisionCentralAdmin = $true
                            }
                        }
                        else
                        {
                            # secureBindings did not exist or did not contain a valid hostheader
                            Write-Verbose -Message "Re-provisioning CA because secureBindings does not exist or does not contain a valid host header"
                            $reprovisionCentralAdmin = $true
                        }
                    }

                    if ($reprovisionCentralAdmin)
                    {
                        # Write-Verbose -Message "Removing Central Admin web application in order to reprovision it"
                        Remove-SPWebApplication -Identity $centralAdminSite.Url -Zone Default -DeleteIisSite

                        Write-Verbose -Message "Re-provisioning Central Admin web application with SSL"
                        $webAppParams = @{
                            Identity             = $centralAdminSite.Url
                            Name                 = "SharePoint Central Administration v4"
                            Zone                 = "Default"
                            HostHeader           = $desiredUri.Host
                            Port                 = $desiredUri.Port
                            AuthenticationMethod = $params.CentralAdministrationAuth
                            SecureSocketsLayer   = $true
                        }
                        New-SPWebApplicationExtension @webAppParams
                    }
                }
            }
            elseif ($CurrentValues.CentralAdministrationPort -ne $CentralAdministrationPort)
            {
                Write-Verbose -Message "Updating CentralAdmin port to $CentralAdministrationPort"
                Invoke-SPDSCCommand -Credential $InstallAccount `
                                    -Arguments $PSBoundParameters `
                                    -ScriptBlock {
                    $params = $args[0]

                    Write-Verbose -Message "Updating Central Admin port"
                    Set-SPCentralAdministration -Port $params.CentralAdministrationPort
                }
            }
        }

        if ($CurrentValues.DeveloperDashboard -ne $DeveloperDashboard)
        {
            Write-Verbose -Message "Updating DeveloperDashboard to $DeveloperDashboard"
            Invoke-SPDSCCommand -Credential $InstallAccount `
                                -Arguments $PSBoundParameters `
                                -ScriptBlock {
                $params = $args[0]

                Write-Verbose -Message "Updating Developer Dashboard setting"
                $admService                 = Get-SPDSCContentService
                $developerDashboardSettings = $admService.DeveloperDashboardSettings
                $developerDashboardSettings.DisplayLevel = [Microsoft.SharePoint.Administration.SPDeveloperDashboardLevel]::$params.DeveloperDashboard
                $developerDashboardSettings.Update()
            }
        }

        return
    }
    else
    {
        Write-Verbose -Message "Server not part of farm, creating or joining farm"

        $actionResult = Invoke-SPDSCCommand -Credential $InstallAccount `
                                            -Arguments @($PSBoundParameters, $PSScriptRoot) `
                                            -ScriptBlock {
            $params     = $args[0]
            $scriptRoot = $args[1]

            $modulePath = "..\..\Modules\SharePointDsc.Farm\SPFarm.psm1"
            Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

            $sqlInstanceStatus = Get-SPDSCSQLInstanceStatus -SQLServer $params.DatabaseServer `

            if ($sqlInstanceStatus.MaxDOPCorrect -ne $true)
            {
                throw "The MaxDOP setting is incorrect. Please correct before continuing."
            }

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
            }

            $executeArgs = @{
                DatabaseServer                     = $params.DatabaseServer
                DatabaseName                       = $params.FarmConfigDatabaseName
                Passphrase                         = $params.Passphrase.Password
                SkipRegisterAsDistributedCacheHost = $true
            }

            $installedVersion = Get-SPDSCInstalledProductVersion
            switch ($installedVersion.FileMajorPart)
            {
                15 {
                    Write-Verbose -Message "Detected Version: SharePoint 2013"
                }
                16 {
                    if ($params.ContainsKey("ServerRole") -eq $true)
                    {
                        if ($installedVersion.ProductBuildPart.ToString().Length -eq 4)
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint 2016 - " + `
                                                    "configuring server as $($params.ServerRole)")
                        }
                        else
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint 2019 - " + `
                                                    "configuring server as $($params.ServerRole)")
                        }
                        $executeArgs.Add("LocalServerRole", $params.ServerRole)
                    }
                    else
                    {
                        if ($installedVersion.ProductBuildPart.ToString().Length -eq 4)
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint 2016 - no server " + `
                                                    "role provided, configuring server without a " + `
                                                    "specific role")
                        }
                        else
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint 2019 - no server " + `
                                                    "role provided, configuring server without a " + `
                                                    "specific role")
                        }
                        $executeArgs.Add("ServerRoleOptional", $true)
                    }
                }
                Default {
                    throw [Exception] ("An unknown version of SharePoint (Major version $_) " + `
                                       "was detected. Only versions 15 (SharePoint 2013) and" + `
                                       "16 (SharePoint 2016 or SharePoint 2019) are supported.")
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
                $dbStatus = Get-SPDSCConfigDBStatus -SQLServer $params.DatabaseServer `
                                                    -Database $params.FarmConfigDatabaseName
                $loopCount = 0
                while ($dbStatus.DatabaseExists -eq $false -and $loopCount -lt 15)
                {
                    Write-Verbose -Message ("The configuration database is not yet provisioned " + `
                                            "by a remote server, this server will wait for up to " + `
                                            "15 minutes for this to complete")
                    Start-Sleep -Seconds 60
                    $loopCount++
                    $dbStatus = Get-SPDSCConfigDBStatus -SQLServer $params.DatabaseServer `
                                                        -Database $params.FarmConfigDatabaseName
                }

                Write-Verbose -Message "The database exists, so attempt to join the server to the farm"

                # Remove the server role optional attribute as it is only used when creating
                # a new farm
                if ($executeArgs.ContainsKey("ServerRoleOptional") -eq $true)
                {
                    $executeArgs.Remove("ServerRoleOptional")
                }

                Write-Verbose -Message ("The server will attempt to join the farm now once every " + `
                                        "60 seconds for the next 15 minutes.")
                $loopCount       = 0
                $connectedToFarm = $false
                $lastException   = $null
                while ($connectedToFarm -eq $false -and $loopCount -lt 15)
                {
                    try
                    {
                        Connect-SPConfigurationDatabase @executeArgs | Out-Null
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
                }
                $farmAction = "JoinedFarm"
            }
            else
            {
                Write-Verbose -Message "The database does not exist, so create a new farm"

                Write-Verbose -Message ("Creating Lock database to prevent two servers creating " + `
                                        "the same farm")
                Add-SPDscConfigDBLock -SQLServer $params.DatabaseServer `
                                      -Database $params.FarmConfigDatabaseName

                try
                {
                    $executeArgs += @{
                        FarmCredentials = $params.FarmAccount
                        AdministrationContentDatabaseName = $params.AdminContentDatabaseName
                    }

                    Write-Verbose -Message "Creating new Config database"
                    New-SPConfigurationDatabase @executeArgs

                    $farmAction = "CreatedFarm"
                }
                finally
                {
                    Write-Verbose -Message "Removing Lock database"
                    Remove-SPDscConfigDBLock -SQLServer $params.DatabaseServer `
                                             -Database $params.FarmConfigDatabaseName
                }
            }

            # Run common tasks for a new server
            Write-Verbose -Message "Starting Install-SPHelpCollection"
            Install-SPHelpCollection -All | Out-Null

            Write-Verbose -Message "Starting Initialize-SPResourceSecurity"
            Initialize-SPResourceSecurity | Out-Null

            Write-Verbose -Message "Starting Install-SPService"
            Install-SPService | Out-Null

            Write-Verbose -Message "Starting Install-SPFeature"
            Install-SPFeature -AllExistingFeatures -Force | Out-Null

            # Provision central administration
            if ($params.RunCentralAdmin -eq $true)
            {
                Write-Verbose -Message "RunCentralAdmin is True, provisioning Central Admin"
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

                    # if central admin is to be SSL, let's remove and re-provision
                    if (-not [string]::IsNullOrEmpty($params.CentralAdministrationUrl) -and `
                        ([System.Uri]$params.CentralAdministrationUrl).Scheme -eq 'https')
                    {
                        Write-Verbose -Message "Removing Central Admin to properly provision as SSL"

                        $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                            | Where-Object -FilterScript {
                            $_.IsAdministrationWebApplication -eq $true
                        }

                        # Wondering if -DeleteIisSite is necessary. Does this add more risk of ending up in
                        # a state without CA or a way to recover it?
                        Remove-SPWebApplication -Identity $centralAdminSite.Url -Zone Default -DeleteIisSite

                        Write-Verbose -Message "Reprovisioning Central Admin with SSL"

                        $webAppParams = @{
                            Identity             = $centralAdminSite.Url
                            Name                 = "SharePoint Central Administration v4"
                            Zone                 = "Default"
                            HostHeader           = ([System.Uri]$params.CentralAdministrationUrl).Host
                            Port                 = $params.CentralAdministrationPort
                            AuthenticationMethod = $params.CentralAdministrationAuth
                            SecureSocketsLayer   = $true
                        }

                        New-SPWebApplicationExtension @webAppParams
                    }
                }
                else
                {
                    $serviceInstance = Get-SPServiceInstance -Server $env:COMPUTERNAME
                    if ($null -eq $serviceInstance)
                    {
                        $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                        $fqdn = "$($env:COMPUTERNAME).$domain"
                        $serviceInstance = Get-SPServiceInstance -Server $fqdn
                    }

                    if ($null -ne $serviceInstance)
                    {
                        $serviceInstance = $serviceInstance | Where-Object -FilterScript {
                            $_.GetType().Name -eq "SPWebServiceInstance" -and `
                            $_.Name -eq "WSS_Administration"
                        }
                    }

                    if ($null -eq $serviceInstance)
                    {
                        throw [Exception] "Unable to locate Central Admin service instance on this server"
                    }
                    Start-SPServiceInstance -Identity $serviceInstance
                }
            }

            Write-Verbose -Message "Starting Install-SPApplicationContent"
            Install-SPApplicationContent | Out-Null

            if ($params.ContainsKey("DeveloperDashboard") -and $params.DeveloperDashboard -ne "Off")
            {
                Write-Verbose -Message "Updating Developer Dashboard setting"
                $admService                 = Get-SPDSCContentService
                $developerDashboardSettings = $admService.DeveloperDashboardSettings
                $developerDashboardSettings.DisplayLevel = [Microsoft.SharePoint.Administration.SPDeveloperDashboardLevel]::$params.DeveloperDashboard
                $developerDashboardSettings.Update()
            }

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
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Passphrase,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AdminContentDatabaseName,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $RunCentralAdmin,

        [Parameter()]
        [System.String]
        $CentralAdministrationUrl,

        [Parameter()]
        [System.UInt32]
        $CentralAdministrationPort,

        [Parameter()]
        [System.String]
        [ValidateSet("NTLM","Kerberos")]
        $CentralAdministrationAuth,

        [Parameter()]
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
        $ServerRole,

        [Parameter()]
        [ValidateSet("Off","On","OnDemand")]
        [System.String]
        $DeveloperDashboard,


        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing local SP Farm settings"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure",
                                                     "RunCentralAdmin",
                                                     "CentralAdministrationUrl",
                                                     "CentralAdministrationPort",
                                                     "DeveloperDashboard")
}

Export-ModuleMember -Function *-TargetResource
