$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:resourceFarmHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Farm'
Import-Module -Name (Join-Path -Path $script:resourceFarmHelperModulePath -ChildPath 'SPFarm.psm1')

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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

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
        [ValidateRange(1, 65535)]
        [System.UInt32]
        $CentralAdministrationPort,

        [Parameter()]
        [System.String]
        [ValidateSet("NTLM", "Kerberos")]
        $CentralAdministrationAuth,

        [Parameter()]
        [System.String]
        [ValidateSet("Application",
            "ApplicationWithSearch",
            "Custom",
            "DistributedCache",
            "Search",
            "SingleServerFarm",
            "WebFrontEnd",
            "WebFrontEndWithDistributedCache")]
        $ServerRole,

        [Parameter()]
        [ValidateSet("Off", "On", "OnDemand")]
        [System.String]
        $DeveloperDashboard,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationCredentialKey,

        [Parameter()]
        [System.Boolean]
        $SkipRegisterAsDistributedCacheHost = $true,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting the settings of the current local SharePoint Farm (if any)"

    if ($Ensure -eq "Absent")
    {
        $message = "SharePointDsc does not support removing a server from a farm, please set " + `
            "the ensure property to 'present'"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $supportsSettingApplicationCredentialKey = $false
    $installedVersion = Get-SPDscInstalledProductVersion
    switch ($installedVersion.FileMajorPart)
    {
        15
        {
            Write-Verbose -Message "Detected installation of SharePoint 2013"
        }
        16
        {
            if ($DeveloperDashboard -eq "OnDemand")
            {
                $message = "The DeveloperDashboard value 'OnDemand' is not allowed in SharePoint " + `
                    "2016 and 2019"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if ($DeveloperDashboard -eq "On")
            {
                $message = "Please make sure you also provision the Usage and Health " +
                "service application to make sure the Developer Dashboard " +
                "works properly"
                Write-Verbose -Message $message
            }

            $buildVersion = $installedVersion.ProductBuildPart
            # SharePoint 2016
            if ($buildVersion -lt 10000)
            {
                Write-Verbose -Message "Detected installation of SharePoint 2016"
            }
            # SharePoint 2019
            elseif ($buildVersion -ge 10000 -and
                $buildVersion -le 12999)
            {
                Write-Verbose -Message "Detected installation of SharePoint 2019"
                $supportsSettingApplicationCredentialKey = $true
            }
            # SharePoint Server Subscription Edition
            elseif ($buildVersion -ge 13000)
            {
                Write-Verbose -Message "Detected installation of SharePoint Server Subscription Edition"
                $supportsSettingApplicationCredentialKey = $true
            }
        }
        default
        {
            $message = ("Detected an unsupported major version of SharePoint. SharePointDsc only " +
                "supports SharePoint 2013, 2016, 2019 and Subscription Edition.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey("ApplicationCredentialKey") -and
        -not $supportsSettingApplicationCredentialKey)
    {
        $message = ("Specifying ApplicationCredentialKey is only supported " +
            "on SharePoint 2019 and Subscription Edition")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) -and
        $installedVersion.FileMajorPart -ne 16)
    {
        $message = "Server role is only supported in SharePoint 2016, 2019 and Subscription Edition."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($PSBoundParameters.ContainsKey("ServerRole") -eq $true) -and
        $installedVersion.FileMajorPart -eq 16 -and
        $installedVersion.FileBuildPart -lt 4456 -and
        ($ServerRole -eq "ApplicationWithSearch" -or
            $ServerRole -eq "WebFrontEndWithDistributedCache"))
    {
        $message = ("ServerRole values of 'ApplicationWithSearch' or " +
            "'WebFrontEndWithDistributedCache' require the SharePoint 2016 " +
            "Feature Pack 1 to be installed. See " +
            "https://support.microsoft.com/en-us/kb/3127940")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }


    # Determine if a connection to a farm already exists
    $majorVersion = $installedVersion.FileMajorPart
    $regPath = "hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\$majorVersion.0\Secure\ConfigDB"
    $dsnValue = Get-SPDscRegistryKey -Key $regPath -Value "dsn" -ErrorAction SilentlyContinue

    if ($null -ne $dsnValue)
    {
        Write-Verbose -Message "This node has already been connected to a farm"
        $result = Invoke-SPDscCommand -Credential $InstallAccount `
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

            $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration |
                Where-Object -FilterScript {
                    $_.IsAdministrationWebApplication -eq $true
                }

            $centralAdminProvisioned = $false
            $ca = Get-SPServiceInstance -Server $env:ComputerName
            if ($null -ne $ca)
            {
                $ca = $ca | Where-Object -FilterScript {
                    $_.GetType().Name -eq "SPWebServiceInstance" -and
                    $_.Name -eq "WSS_Administration" -and
                    $_.Status -eq "Online"
                }
            }

            if ($null -ne $ca)
            {
                $centralAdminProvisioned = $true
            }

            $centralAdminAuth = $null
            if ($null -ne $centralAdminSite -and
                $centralAdminSite.IisSettings[0].DisableKerberos -eq $false)
            {
                $centralAdminAuth = "Kerberos"
            }
            else
            {
                $centralAdminAuth = "NTLM"
            }

            $admService = Get-SPDscContentService
            $developerDashboardSettings = $admService.DeveloperDashboardSettings
            $developerDashboardStatus = $developerDashboardSettings.DisplayLevel

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
                ApplicationCredentialKey  = $null
            }
            $installedVersion = Get-SPDscInstalledProductVersion
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
            Write-Verbose -Message ("This server appears to be connected to a farm already, " +
                "but the configuration database is currently unable to be " +
                "accessed. Values returned from the get method will be " +
                "incomplete, however the 'Ensure' property should be " +
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
                ApplicationCredentialKey  = $null
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
            ApplicationCredentialKey  = $null
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $useSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

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
        [ValidateRange(1, 65535)]
        [System.UInt32]
        $CentralAdministrationPort,

        [Parameter()]
        [System.String]
        [ValidateSet("NTLM", "Kerberos")]
        $CentralAdministrationAuth,

        [Parameter()]
        [System.String]
        [ValidateSet("Application",
            "ApplicationWithSearch",
            "Custom",
            "DistributedCache",
            "Search",
            "SingleServerFarm",
            "WebFrontEnd",
            "WebFrontEndWithDistributedCache")]
        $ServerRole,

        [Parameter()]
        [ValidateSet("Off", "On", "OnDemand")]
        [System.String]
        $DeveloperDashboard,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationCredentialKey,

        [Parameter()]
        [System.Boolean]
        $SkipRegisterAsDistributedCacheHost = $true,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting local SP Farm settings"

    if ($Ensure -eq "Absent")
    {
        $message = ("SharePointDsc does not support removing a server from a farm, please set the " +
            "ensure property to 'present'")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $PSBoundParameters.SkipRegisterAsDistributedCacheHost = $SkipRegisterAsDistributedCacheHost

    if ($PSBoundParameters.ContainsKey("CentralAdministrationUrl"))
    {
        if ([string]::IsNullOrEmpty($CentralAdministrationUrl))
        {
            $PSBoundParameters.Remove('CentralAdministrationUrl') | Out-Null
        }
        else
        {
            $uri = $CentralAdministrationUrl -as [System.Uri]
            if ($null -eq $uri.AbsoluteUri -or $uri.scheme -notin ('http', 'https'))
            {
                $message = "CentralAdministrationUrl is not a valid URI. It should include the " + `
                    "scheme (http/https) and address."
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if ($PSBoundParameters.ContainsKey("CentralAdministrationPort"))
            {
                if ($uri.Port -ne $CentralAdministrationPort)
                {
                    $message = ("CentralAdministrationPort does not match port number specified in " + `
                            "CentralAdministrationUrl. Either make the values match or don't specify " + `
                            "CentralAdministrationPort.")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
                }
            }
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    # Set default values to ensure they are passed to Invoke-SPDscCommand
    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationPort"))
    {
        # If CentralAdministrationUrl is specified, let's infer the port from the Url
        if ($PSBoundParameters.ContainsKey("CentralAdministrationUrl"))
        {
            $CentralAdministrationPort =
            $PSBoundParameters.CentralAdministrationPort =
            (New-Object -TypeName System.Uri $CentralAdministrationUrl).Port
        }
        else
        {
            $CentralAdministrationPort =
            $PSBoundParameters.CentralAdministrationPort = 9999
        }
    }

    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationAuth"))
    {
        $CentralAdministrationAuth =
        $PSBoundParameters.CentralAdministrationAuth = "NTLM"
    }

    if ($CurrentValues.Ensure -eq "Present")
    {
        Write-Verbose -Message "Server already part of farm, updating settings"

        if ($CurrentValues.RunCentralAdmin -ne $RunCentralAdmin)
        {
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
                -ScriptBlock {
                $params = $args[0]
                $eventSource = $args[1]

                # Provision central administration
                if ($params.RunCentralAdmin -eq $true)
                {
                    Write-Verbose -Message "RunCentralAdmin set to true, provisioning Central Admin"
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
                            $_.GetType().Name -eq "SPWebServiceInstance" -and
                            $_.Name -eq "WSS_Administration"
                        }
                    }

                    if ($null -eq $serviceInstance)
                    {
                        $message = "Unable to locate Central Admin service instance on this server"
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
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
                        $fqdn = "$($env:COMPUTERNAME).$domain"
                        $serviceInstance = Get-SPServiceInstance -Server $fqdn
                    }

                    if ($null -ne $serviceInstance)
                    {
                        $serviceInstance = $serviceInstance | Where-Object -FilterScript {
                            $_.GetType().Name -eq "SPWebServiceInstance" -and
                            $_.Name -eq "WSS_Administration"
                        }
                    }

                    if ($null -eq $serviceInstance)
                    {
                        $message = "Unable to locate Central Admin service instance on this server"
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                    Stop-SPServiceInstance -Identity $serviceInstance
                }
            }
        }

        if ($RunCentralAdmin)
        {
            # track whether or not we end up reprovisioning CA
            $reprovisionCentralAdmin = $false

            if ($PSBoundParameters.ContainsKey("CentralAdministrationUrl"))
            {
                # For the following scenarios, we should remove the CA web application and recreate it
                #   CentralAdministrationUrl is passed in
                #   AND     Current CentralAdministrationUrl is not equal to new CentralAdministrationUrl
                #       OR  Current SecureBindings (HTTPS) or ServerBindings (HTTP) does not exist or doesn't
                #           match desired url and port

                Write-Verbose -Message "Updating Central Admin URL configuration"
                Invoke-SPDscCommand -Credential $InstallAccount `
                    -Arguments $PSBoundParameters `
                    -ScriptBlock {
                    $params = $args[0]

                    $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
                        $_.IsAdministrationWebApplication
                    }

                    $isCentralAdminUrlHttps = (([System.Uri]$params.CentralAdministrationUrl).Scheme -eq 'https')

                    $desiredUri = [System.Uri]($params.CentralAdministrationUrl.TrimEnd('/'))
                    $currentUri = [System.Uri]$centralAdminSite.Url
                    if ($desiredUri.AbsoluteUri -ne $currentUri.AbsoluteUri)
                    {
                        Write-Verbose -Message ("Re-provisioning CA because $($currentUri.AbsoluteUri) " + `
                                "does not equal $($desiredUri.AbsoluteUri)")
                        $reprovisionCentralAdmin = $true
                    }
                    else
                    {
                        # check securebindings (https) or serverbindings (http)
                        # there should be an entry in the SecureBindings object of the
                        # SPWebApplication's IisSettings for the default zone
                        $iisBindings = $null
                        if ($isCentralAdminUrlHttps)
                        {
                            Write-Verbose -Message "Getting current secure bindings..."
                            $iisBindings = $centralAdminSite.GetIisSettingsWithFallback("Default").SecureBindings
                        }
                        else
                        {
                            Write-Verbose -Message "Getting current server bindings..."
                            $iisBindings = $centralAdminSite.GetIisSettingsWithFallback("Default").ServerBindings
                        }

                        if ($null -ne $iisBindings[0] -and (-not [string]::IsNullOrEmpty($iisBindings[0].HostHeader)))
                        {
                            # check to see if iisBindings host header and port match what we want them to be
                            if ($desiredUri.Host -ne $iisBindings[0].HostHeader -or
                                $desiredUri.Port -ne $iisBindings[0].Port)
                            {
                                Write-Verbose -Message ("Re-provisioning CA because $($desiredUri.Host) does not " + `
                                        "equal $($iisBindings[0].HostHeader) or $($desiredUri.Port) does not " + `
                                        "equal $($iisBindings[0].Port)")
                                $reprovisionCentralAdmin = $true
                            }
                        }
                        else
                        {
                            # iisBindings did not exist or did not contain a valid hostheader
                            Write-Verbose -Message ("Re-provisioning CA because IIS Bindings does not " + `
                                    "exist or does not contain a valid host header")
                            $reprovisionCentralAdmin = $true
                        }
                    }

                    if ($reprovisionCentralAdmin)
                    {
                        # Write-Verbose -Message "Removing Central Admin web application in order to reprovision it"
                        Remove-SPWebApplication -Identity $centralAdminSite.Url -Zone Default -DeleteIisSite

                        $farm = Get-SPFarm
                        $ca_service = $farm.Services | Where-Object -FilterScript { $_.TypeName -eq "Central Administration" }

                        Write-Verbose -Message "Re-provisioning Central Admin web application"
                        $webAppParams = @{
                            Identity             = $centralAdminSite.Url
                            Name                 = $ca_service.ApplicationPools.Name
                            Zone                 = "Default"
                            HostHeader           = $desiredUri.Host
                            Port                 = $desiredUri.Port
                            AuthenticationMethod = $params.CentralAdministrationAuth
                            SecureSocketsLayer   = $isCentralAdminUrlHttps
                        }
                        New-SPWebApplicationExtension @webAppParams
                    }
                }
            }
            elseif ($CurrentValues.CentralAdministrationPort -ne $CentralAdministrationPort)
            {
                Write-Verbose -Message "Updating CentralAdmin port to $CentralAdministrationPort"
                Invoke-SPDscCommand -Credential $InstallAccount `
                    -Arguments $PSBoundParameters `
                    -ScriptBlock {
                    $params = $args[0]

                    Set-SPCentralAdministration -Port $params.CentralAdministrationPort
                }
            }

            # if Authentication Method doesn't match and we haven't reprovisioned CA above, update auth method
            if ($CurrentValues.CentralAdministrationAuth -ne $CentralAdministrationAuth -and
                (-not $reprovisionCentralAdmin))
            {
                Write-Verbose -Message ("Updating CentralAdmin authentication method from " + `
                        "$($CurrentValues.CentralAdministrationAuth) to $CentralAdministrationAuth")
                Invoke-SPDscCommand -Credential $InstallAccount `
                    -Arguments $PSBoundParameters `
                    -ScriptBlock {
                    $params = $args[0]

                    $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
                        $_.IsAdministrationWebApplication
                    }

                    $centralAdminSite | Set-SPWebApplication -Zone "Default" -AuthenticationMethod $params.CentralAdministrationAuth
                }
            }
        }

        if ($CurrentValues.DeveloperDashboard -ne $DeveloperDashboard)
        {
            Write-Verbose -Message "Updating DeveloperDashboard to $DeveloperDashboard"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                Write-Verbose -Message "Updating Developer Dashboard setting"
                $admService = Get-SPDscContentService
                $developerDashboardSettings = $admService.DeveloperDashboardSettings
                $developerDashboardSettings.DisplayLevel = [Microsoft.SharePoint.Administration.SPDeveloperDashboardLevel]::$($params.DeveloperDashboard)
                $developerDashboardSettings.Update()
            }
        }

        return
    }
    else
    {
        Write-Verbose -Message "Server not part of farm, creating or joining farm"

        $actionResult = Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]
            $scriptRoot = $args[2]

            $modulePath = "..\..\Modules\SharePointDsc.Farm\SPFarm.psm1"
            Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

            if ($params.UseSQLAuthentication -eq $true)
            {
                Write-Verbose -Message ("Using SQL authentication to create service application as " + `
                        "`$useSQLAuthentication is set to $($params.useSQLAuthentication).")
                $databaseCredentialsParam = @{
                    DatabaseCredentials = $params.DatabaseCredentials
                }
            }
            else
            {
                $databaseCredentialsParam = ""
            }

            $sqlInstanceStatus = Get-SPDscSQLInstanceStatus -SQLServer $params.DatabaseServer @databaseCredentialsParam

            if ($sqlInstanceStatus.MaxDOPCorrect -ne $true)
            {
                $message = "The MaxDOP setting is incorrect. Please correct before continuing."
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            $dbStatus = Get-SPDscConfigDBStatus -SQLServer $params.DatabaseServer `
                -Database $params.FarmConfigDatabaseName `
                @databaseCredentialsParam

            while ($dbStatus.Locked -eq $true)
            {
                Write-Verbose -Message ("[$([DateTime]::Now.ToShortTimeString())] The configuration " +
                    "database is currently being provisioned by a remote " +
                    "server, this server will wait for this to complete")
                Start-Sleep -Seconds 30
                $dbStatus = Get-SPDscConfigDBStatus -SQLServer $params.DatabaseServer `
                    -Database $params.FarmConfigDatabaseName `
                    @databaseCredentialsParam
            }

            if ($dbStatus.ValidPermissions -eq $false)
            {
                if ($dbStatus.DatabaseEmpty -eq $true)
                {
                    # If DatabaseEmpty is True most probably precreated databases are being used
                    Write-Verbose -Message ("IMPORTANT: Permissions check failed, but an empty " + `
                            "configDB '$($params.FarmConfigDatabaseName)' was found. Assuming that " + `
                            "precreated databases are being used.")
                }
                else
                {
                    # If DatabaseEmpty is False, then either the specified ConfigDB doesn't exist or
                    # is already provisioned
                    $message = "The current user does not have sufficient permissions to SQL Server"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
            }

            $executeArgs = @{
                DatabaseServer                     = $params.DatabaseServer
                DatabaseName                       = $params.FarmConfigDatabaseName
                Passphrase                         = $params.Passphrase.Password
                SkipRegisterAsDistributedCacheHost = $params.SkipRegisterAsDistributedCacheHost
            }

            $supportsSettingApplicationCredentialKey = $false

            if ($params.useSQLAuthentication -eq $true)
            {
                Write-Verbose -Message ("Using SQL authentication to connect to / create farm as " + `
                        "`$useSQLAuthentication is set to $($params.useSQLAuthentication).")
                $executeArgs.Add("DatabaseCredentials", $params.DatabaseCredentials)
            }
            else
            {
                Write-Verbose -Message ("`$useSQLAuthentication is false or not specified; using " + `
                        "default Windows authentication.")
            }

            $installedVersion = Get-SPDscInstalledProductVersion
            switch ($installedVersion.FileMajorPart)
            {
                15
                {
                    Write-Verbose -Message "Detected Version: SharePoint 2013"
                }
                16
                {
                    if ($params.ContainsKey("ServerRole") -eq $true)
                    {
                        $buildVersion = $installedVersion.ProductBuildPart
                        # SharePoint 2016
                        if ($buildVersion -lt 10000)
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint 2016 - " +
                                "configuring server as $($params.ServerRole)")
                        }
                        # SharePoint 2019
                        elseif ($buildVersion -ge 10000 -and
                            $buildVersion -le 12999)
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint 2019 - " +
                                "configuring server as $($params.ServerRole)")
                            $supportsSettingApplicationCredentialKey = $true
                        }
                        # SharePoint Server Subscription Edition
                        elseif ($buildVersion -ge 13000)
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint Server Subscription Edition - " +
                                "configuring server as $($params.ServerRole)")
                            $supportsSettingApplicationCredentialKey = $true
                        }
                        $executeArgs.Add("LocalServerRole", $params.ServerRole)
                    }
                    else
                    {
                        $buildVersion = $installedVersion.ProductBuildPart
                        # SharePoint 2016
                        if ($buildVersion -lt 10000)
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint 2016 - no server " +
                                "role provided, configuring server without a " +
                                "specific role")
                        }
                        # SharePoint 2019
                        elseif ($buildVersion -ge 10000 -and
                            $buildVersion -le 12999)
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint 2019 - no server " +
                                "role provided, configuring server without a " +
                                "specific role")
                            $supportsSettingApplicationCredentialKey = $true
                        }
                        # SharePoint Server Subscription Edition
                        elseif ($buildVersion -ge 13000)
                        {
                            Write-Verbose -Message ("Detected Version: SharePoint Server Subscription Edition - " +
                                "configuring server as $($params.ServerRole)")
                            $supportsSettingApplicationCredentialKey = $true
                        }
                        $executeArgs.Add("ServerRoleOptional", $true)
                    }
                }
                Default
                {
                    $message = ("An unknown version of SharePoint (Major version $_) " +
                        "was detected. Only versions 15 (SharePoint 2013) and" +
                        "16 (SharePoint 2016, 2019 or Subscription Edition) are supported.")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
            }

            if ($params.ContainsKey("ApplicationCredentialKey") -and
                -not $supportsSettingApplicationCredentialKey)
            {
                $message = ("Specifying ApplicationCredentialKey is only supported " +
                    "on SharePoint 2019 or Subscription Edition")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            if ($dbStatus.DatabaseExists -eq $true)
            {
                if ($dbStatus.DatabaseEmpty -eq $true)
                {
                    Write-Verbose -Message ("The SharePoint config database " +
                        "'$($params.FarmConfigDatabaseName)' exists but is empty, so " +
                        "this server will create the farm.")
                    $createFarm = $true
                }
                else
                {
                    Write-Verbose -Message ("The SharePoint config database " +
                        "'$($params.FarmConfigDatabaseName)' already exists, so " +
                        "this server will join the farm.")
                    $createFarm = $false
                }
            }
            elseif ($dbStatus.DatabaseExists -eq $false -and $params.RunCentralAdmin -eq $false)
            {
                # Only allow the farm to be created by a server that will run central admin
                # to avoid a ghost CA site appearing on this server and causing issues
                Write-Verbose -Message ("The SharePoint config database " +
                    "'$($params.FarmConfigDatabaseName)' does not exist, but " +
                    "this server will not be running the central admin " +
                    "website, so it will wait to join the farm rather than " +
                    "create one.")
                $createFarm = $false
            }
            else
            {
                Write-Verbose -Message ("The SharePoint config database " +
                    "'$($params.FarmConfigDatabaseName)' does not exist, so " +
                    "this server will create the farm.")
                $createFarm = $true
            }

            $farmAction = ""
            if ($createFarm -eq $false)
            {
                $dbStatus = Get-SPDscConfigDBStatus -SQLServer $params.DatabaseServer `
                    -Database $params.FarmConfigDatabaseName `
                    @databaseCredentialsParam
                $loopCount = 0
                while ($dbStatus.DatabaseExists -eq $false -and $loopCount -lt 15)
                {
                    Write-Verbose -Message ("The configuration database is not yet provisioned " +
                        "by a remote server, this server will wait for up to " +
                        "15 minutes for this to complete")
                    Start-Sleep -Seconds 60
                    $loopCount++
                    $dbStatus = Get-SPDscConfigDBStatus -SQLServer $params.DatabaseServer `
                        -Database $params.FarmConfigDatabaseName `
                        @databaseCredentialsParam
                }

                Write-Verbose -Message "The database exists, so attempt to join the server to the farm"

                # Remove the server role optional attribute as it is only used when creating
                # a new farm
                if ($executeArgs.ContainsKey("ServerRoleOptional") -eq $true)
                {
                    $executeArgs.Remove("ServerRoleOptional")
                }

                Write-Verbose -Message ("The server will attempt to join the farm now once every " +
                    "60 seconds for the next 15 minutes.")
                $loopCount = 0
                $connectedToFarm = $false
                $lastException = $null
                while ($connectedToFarm -eq $false -and $loopCount -lt 15)
                {
                    try
                    {
                        Write-Verbose -Message "Connecting to existing Config database"
                        Write-Verbose -Message "executeArgs is:"
                        foreach ($arg in $executeArgs.Keys)
                        {
                            if ($executeArgs.$arg -is [System.Management.Automation.PSCredential])
                            {
                                Write-Verbose -Message "$arg : $($executeArgs.$arg.UserName)"
                            }
                            else
                            {
                                Write-Verbose -Message "$arg : $($executeArgs.$arg)"
                            }
                        }

                        Connect-SPConfigurationDatabase @executeArgs | Out-Null
                        $connectedToFarm = $true
                    }
                    catch
                    {
                        $lastException = $_.Exception
                        Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - An error " +
                            "occured joining config database " +
                            "'$($params.FarmConfigDatabaseName)' on " +
                            "'$($params.DatabaseServer)'. This resource will " +
                            "wait and retry automatically for up to 15 minutes. " +
                            "(waited $loopCount of 15 minutes)")
                        $loopCount++
                        Start-Sleep -Seconds 60
                    }
                }

                if ($connectedToFarm -eq $false)
                {
                    Write-Verbose -Message ("Unable to join config database. Throwing exception.")
                    $message = $lastException
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
                $farmAction = "JoinedFarm"
            }
            else
            {
                Write-Verbose -Message "The database does not exist, so create a new farm"

                Write-Verbose -Message "Creating Lock to prevent two servers creating the same farm"
                $lockConnection = Add-SPDscConfigDBLock -SQLServer $params.DatabaseServer `
                    -Database $params.FarmConfigDatabaseName `
                    @databaseCredentialsParam

                try
                {
                    $executeArgs += @{
                        FarmCredentials                   = $params.FarmAccount
                        AdministrationContentDatabaseName = $params.AdminContentDatabaseName
                    }

                    Write-Verbose -Message "Creating new Config database"
                    Write-Verbose -Message "executeArgs is:"
                    foreach ($arg in $executeArgs.Keys)
                    {
                        if ($executeArgs.$arg -is [System.Management.Automation.PSCredential])
                        {
                            Write-Verbose -Message "$arg : $($executeArgs.$arg.UserName)"
                        }
                        else
                        {
                            Write-Verbose -Message "$arg : $($executeArgs.$arg)"
                        }
                    }
                    New-SPConfigurationDatabase @executeArgs

                    $farmAction = "CreatedFarm"
                }
                finally
                {
                    Write-Verbose -Message "Removing Lock"
                    Remove-SPDscConfigDBLock -SQLServer $params.DatabaseServer `
                        -Database $params.FarmConfigDatabaseName `
                        -Connection $lockConnection `
                        @databaseCredentialsParam
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

            if ($params.ContainsKey("ApplicationCredentialKey"))
            {
                Write-Verbose -Message "Setting application credential key"
                Set-SPApplicationCredentialKey -Password $params.ApplicationCredentialKey.Password
            }

            # Provision central administration
            if ($params.RunCentralAdmin -eq $true)
            {
                Write-Verbose -Message "RunCentralAdmin is True, provisioning Central Admin"
                $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
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

                    if (-not [string]::IsNullOrEmpty($params.CentralAdministrationUrl))
                    {
                        $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
                            $_.IsAdministrationWebApplication -eq $true
                        }

                        # cases where we need to reprovision CA:
                        # 1. desired Url is https
                        # 2. desired Url/port does not match current Url/port
                        # 3. IIS bindings don't match (shouldn't need this because case #2 should catch it in this case)
                        $reprovisionCentralAdmin = $false
                        $isCentralAdminUrlHttps = (([System.Uri]$params.CentralAdministrationUrl).Scheme -eq 'https')

                        $desiredUri = [System.Uri]($params.CentralAdministrationUrl.TrimEnd('/'))
                        $currentUri = [System.Uri]$centralAdminSite.Url

                        if ($isCentralAdminUrlHttps)
                        {
                            Write-Verbose -Message "Re-provisioning newly created CA because we want it to be HTTPS"
                            $reprovisionCentralAdmin = $true
                        }
                        elseif ($desiredUri.AbsoluteUri -ne $currentUri.AbsoluteUri)
                        {
                            Write-Verbose -Message ("Re-provisioning CA because $($currentUri.AbsoluteUri) " + `
                                    "does not equal $($desiredUri.AbsoluteUri)")
                            $reprovisionCentralAdmin = $true
                        }

                        if ($reprovisionCentralAdmin)
                        {
                            Write-Verbose -Message "Removing Central Admin web application"

                            # Wondering if -DeleteIisSite is necessary. Does this add more risk of ending up in
                            # a state without CA or a way to recover it?
                            Remove-SPWebApplication -Identity $centralAdminSite.Url -Zone Default -DeleteIisSite

                            Write-Verbose -Message "Reprovisioning Central Admin with SSL"

                            $webAppParams = @{
                                Identity             = $centralAdminSite.Url
                                Name                 = "SharePoint Central Administration v4"
                                Zone                 = "Default"
                                HostHeader           = $desiredUri.Host
                                Port                 = $desiredUri.Port
                                AuthenticationMethod = $params.CentralAdministrationAuth
                                SecureSocketsLayer   = $isCentralAdminUrlHttps
                            }

                            New-SPWebApplicationExtension @webAppParams
                        }
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
                            $_.GetType().Name -eq "SPWebServiceInstance" -and
                            $_.Name -eq "WSS_Administration"
                        }
                    }

                    if ($null -eq $serviceInstance)
                    {
                        $message = "Unable to locate Central Admin service instance on this server"
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                    Start-SPServiceInstance -Identity $serviceInstance
                }
            }

            Write-Verbose -Message "Starting Install-SPApplicationContent"
            Install-SPApplicationContent | Out-Null

            if ($params.ContainsKey("DeveloperDashboard") -and $params.DeveloperDashboard -ne "Off")
            {
                Write-Verbose -Message "Updating Developer Dashboard setting"
                $admService = Get-SPDscContentService
                $developerDashboardSettings = $admService.DeveloperDashboardSettings
                $developerDashboardSettings.DisplayLevel = [Microsoft.SharePoint.Administration.SPDeveloperDashboardLevel]::$($params.DeveloperDashboard)
                $developerDashboardSettings.Update()
            }

            return $farmAction
        }

        if ($actionResult -eq "JoinedFarm")
        {
            Write-Verbose -Message "Starting timer service"
            Start-Service -Name sptimerv4

            Write-Verbose -Message ("Pausing for 5 minutes to allow the timer service to " +
                "fully provision the server")
            Start-Sleep -Seconds 300
            Write-Verbose -Message ("Join farm complete. Restarting computer to allow " +
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

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
        [ValidateRange(1, 65535)]
        [System.UInt32]
        $CentralAdministrationPort,

        [Parameter()]
        [System.String]
        [ValidateSet("NTLM", "Kerberos")]
        $CentralAdministrationAuth,

        [Parameter()]
        [System.String]
        [ValidateSet("Application",
            "ApplicationWithSearch",
            "Custom",
            "DistributedCache",
            "Search",
            "SingleServerFarm",
            "WebFrontEnd",
            "WebFrontEndWithDistributedCache")]
        $ServerRole,

        [Parameter()]
        [ValidateSet("Off", "On", "OnDemand")]
        [System.String]
        $DeveloperDashboard,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationCredentialKey,

        [Parameter()]
        [System.Boolean]
        $SkipRegisterAsDistributedCacheHost = $true,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing local SP Farm settings"

    $PSBoundParameters.Ensure = $Ensure

    if ($PSBoundParameters.ContainsKey("CentralAdministrationUrl"))
    {
        if ([string]::IsNullOrEmpty($CentralAdministrationUrl))
        {
            $PSBoundParameters.Remove('CentralAdministrationUrl') | Out-Null
        }
        else
        {
            $uri = $CentralAdministrationUrl -as [System.Uri]
            if ($null -eq $uri.AbsoluteUri)
            {
                $message = ("CentralAdministrationUrl is not a valid URI. It should " +
                    "include the scheme (http/https) and address.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if ($PSBoundParameters.ContainsKey("CentralAdministrationPort"))
            {
                if ($uri.Port -ne $CentralAdministrationPort)
                {
                    $message = ("CentralAdministrationPort does not match port number specified " + `
                            "in CentralAdministrationUrl. Either make the values match or don't " + `
                            "specify CentralAdministrationPort.")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
                }
            }
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure",
        "RunCentralAdmin",
        "CentralAdministrationUrl",
        "CentralAdministrationPort",
        "CentralAdministrationAuth",
        "DeveloperDashboard")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.Boolean]
        $RunCentralAdmin
    )

    $spMajorVersion = (Get-SPDscInstalledProductVersion).FileMajorPart
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPFarm\MSFT_SPFarm.psm1" -Resolve

    $Content = "        SPFarm " + [System.Guid]::NewGuid().ToString() + "`r`n        {`r`n"
    $params = Get-DSCFakeParameters -ModulePath $module
    $params.CentralAdministrationPort = 443

    <# If not SP2016 or above, remove the server role param. #>
    if ($spMajorVersion -lt 16)
    {
        $params.Remove("ServerRole")
    }

    <# if not 2019 or above, remove the ApplicationCredentialKey param#>
    if ($spMajorVersion -lt 19)
    {
        $params.Remove("ApplicationCredentialKey")
    }

    <# Can't have both the InstallAccount and PsDscRunAsCredential variables present. Remove InstallAccount if both are there. #>
    if ($params.Contains("InstallAccount"))
    {
        $params.Remove("InstallAccount")
    }

    $params.FarmAccount = $Global:spFarmAccount
    $params.Passphrase = $Global:spFarmAccount
    $results = Get-TargetResource @params

    <# Remove the default generated PassPhrase and ensure the resulting Configuration Script will prompt user for it. #>
    $results.Remove("Passphrase");

    $dbServer = $results.DatabaseServer
    $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"

    if ($null -ne $results.CentralAdministrationUrl -and $results.CentralAdministrationUrl.ToLower() -like 'http://*')
    {
        $results.Remove("CentralAdministrationUrl") | Out-Null
    }

    if ($DynamicCompilation)
    {
        Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value 'localhost' -Description "Name of the Database Server associated with the destination SharePoint Farm;"
    }
    else
    {
        Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value $dbServer -Description "Name of the Database Server associated with the destination SharePoint Farm;"
    }

    if ($null -eq (Get-ConfigurationDataEntry -Node "NonNodeData" -Key "PassPhrase"))
    {
        Add-ConfigurationDataEntry -Node "NonNodeData" -Key "PassPhrase" -Value "pass@word1" -Description "SharePoint Farm's PassPhrase;"
    }

    $Content += "            Passphrase = New-Object System.Management.Automation.PSCredential ('Passphrase', (ConvertTo-SecureString -String `$ConfigurationData.NonNodeData.PassPhrase -AsPlainText -Force));`r`n"

    if (!$results.ContainsKey("RunCentralAdmin"))
    {
        $results.Add("RunCentralAdmin", $RunCentralAdmin)
    }

    if ($StandAlone)
    {
        $results.RunCentralAdmin = $true
    }

    if ($spMajorVersion -ge 16)
    {
        if (!$results.Contains("ServerRole"))
        {
            $results.Add("ServerRole", "`$Node.ServerRole")
        }
        else
        {
            $results["ServerRole"] = "`$Node.ServerRole"
        }
    }
    else
    {
        $results.Remove("ServerRole")
    }
    $results = Repair-Credentials -results $results
    $results.FarmAccount = Resolve-Credentials -UserName $results.FarmAccount
    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "DatabaseServer"
    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "FarmAccount"
    if ($spMajorVersion -ge 16)
    {
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "ServerRole"
    }
    $Content += $currentBlock
    $Content += "        }`r`n"

    <# SPFarm Feature Section #>
    if (($Global:ExtractionModeValue -eq 3 -and $Quiet) -or $Global:ComponentsToExtract.Contains("SPFeature"))
    {
        $Properties = @{
            Scope = "Farm"
        }
        $Content += Read-TargetResource -ResourceName 'SPFeature' -ExportParams $Properties
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
