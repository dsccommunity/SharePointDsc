$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $MySiteHostLocation,

        [Parameter()]
        [System.String]
        $MySiteManagedPath,

        [Parameter()]
        [System.String]
        $ProfileDBName,

        [Parameter()]
        [System.String]
        $ProfileDBServer,

        [Parameter()]
        [System.String]
        $SocialDBName,

        [Parameter()]
        [System.String]
        $SocialDBServer,

        [Parameter()]
        [System.String]
        $SyncDBName,

        [Parameter()]
        [System.String]
        $SyncDBServer,

        [Parameter()]
        [System.Boolean]
        $EnableNetBIOS = $false,

        [Parameter()]
        [System.Boolean]
        $NoILMUsed = $false,

        [Parameter()]
        [ValidateSet("Username_CollisionError", "Username_CollisionDomain", "Domain_Username")]
        [System.String]
        $SiteNamingConflictResolution,

        [Parameter()]
        [System.Boolean]
        $UpdateProxyGroup = $true,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service application $Name"

    if ($PSBoundParameters.ContainsKey("MySiteHostLocation") -eq $false)
    {
        Write-Verbose -Message ("You should also specify the MySiteHostLocation parameter. " + `
                "This will be required as of SharePointDsc v4.0")
    }

    $farmAccount = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        return Get-SPDscFarmAccount
    }

    if ($null -ne $farmAccount)
    {
        if ($PSBoundParameters.ContainsKey("InstallAccount") -eq $true)
        {
            # InstallAccount used
            if ($InstallAccount.UserName -eq $farmAccount.UserName)
            {
                throw ("Specified InstallAccount ($($InstallAccount.UserName)) is the Farm " + `
                        "Account. Make sure the specified InstallAccount isn't the Farm Account " + `
                        "and try again")
            }
        }
        else
        {
            # PSDSCRunAsCredential or System
            if (-not $Env:USERNAME.Contains("$"))
            {
                # PSDSCRunAsCredential used
                $localaccount = "$($Env:USERDOMAIN)\$($Env:USERNAME)"
                if ($localaccount -eq $farmAccount.UserName)
                {
                    Write-Verbose -Message ("The current user ($localaccount) is the Farm " + `
                            "Account. Please note that this will cause issues when applying the configuration.")
                }
            }
        }
    }
    else
    {
        throw ("Unable to retrieve the Farm Account. Check if the farm exists.")
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name            = $params.Name
            Ensure          = "Absent"
            ApplicationPool = $params.ApplicationPool
        }
        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.Office.Server.Administration.UserProfileApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $databases = @{ }
            $propertyFlags = [System.Reflection.BindingFlags]::Instance -bor `
                [System.Reflection.BindingFlags]::NonPublic

            $propData = $serviceApp.GetType().GetProperties($propertyFlags)

            $socialProp = $propData | Where-Object -FilterScript {
                $_.Name -eq "SocialDatabase"
            }
            $databases.Add("SocialDatabase", $socialProp.GetValue($serviceApp))

            $profileProp = $propData | Where-Object -FilterScript {
                $_.Name -eq "ProfileDatabase"
            }
            $databases.Add("ProfileDatabase", $profileProp.GetValue($serviceApp))

            $syncProp = $propData | Where-Object -FilterScript {
                $_.Name -eq "SynchronizationDatabase"
            }
            $databases.Add("SynchronizationDatabase", $syncProp.GetValue($serviceApp))

            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue
            if ($null -ne $serviceAppProxies)
            {
                $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                    $serviceApp.IsConnected($_)
                }
                if ($null -ne $serviceAppProxy)
                {
                    $proxyName = $serviceAppProxy.Name
                }
            }

            $proxyGroups = Get-SPServiceApplicationProxyGroup

            $proxyGroup = $proxyGroups | Where-Object -FilterScript {
                $_.Proxies.DisplayName -contains $proxyName
            } | Select-Object -First 1

            if ($null -ne $proxyGroup -and
                $proxyGroup -eq $serviceApp.ServiceApplicationProxyGroup)
            {
                $updateProxyGroup = $false
            }
            else
            {
                $updateProxyGroup = $true
            }

            $upMySiteLocation = $null
            $upMySiteManagedPath = $null
            $upSiteConflictNaming = $null
            try
            {
                $ca = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript { $_.IsAdministrationWebApplication }
                $caSite = $ca.Sites[0]
                $serviceContext = Get-SPServiceContext($caSite)
                $userProfileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($serviceContext)
                $upMySiteLocation = $userProfileManager.MySiteHostUrl
                $upMySiteManagedPath = $userProfileManager.PersonalSiteInclusion
                $upSiteConflictNaming = $userProfileManager.PersonalSiteFormat
            }
            catch
            {
                throw "The provided My Site Location is not a valid My Site Host."
            }

            return @{
                Name                         = $serviceApp.DisplayName
                ProxyName                    = $proxyName
                ApplicationPool              = $serviceApp.ApplicationPool.Name
                MySiteHostLocation           = $upMySiteLocation
                MySiteManagedPath            = $upMySiteManagedPath
                ProfileDBName                = $databases.ProfileDatabase.Name
                ProfileDBServer              = $databases.ProfileDatabase.NormalizedDataSource
                SocialDBName                 = $databases.SocialDatabase.Name
                SocialDBServer               = $databases.SocialDatabase.NormalizedDataSource
                SyncDBName                   = $databases.SynchronizationDatabase.Name
                SyncDBServer                 = $databases.SynchronizationDatabase.NormalizedDataSource
                InstallAccount               = $params.InstallAccount
                EnableNetBIOS                = $serviceApp.NetBIOSDomainNamesEnabled
                NoILMUsed                    = $serviceApp.NoILMUsed
                SiteNamingConflictResolution = $upSiteConflictNaming
                UpdateProxyGroup             = $updateProxyGroup
                Ensure                       = "Present"
            }
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $MySiteHostLocation,

        [Parameter()]
        [System.String]
        $MySiteManagedPath,

        [Parameter()]
        [System.String]
        $ProfileDBName,

        [Parameter()]
        [System.String]
        $ProfileDBServer,

        [Parameter()]
        [System.String]
        $SocialDBName,

        [Parameter()]
        [System.String]
        $SocialDBServer,

        [Parameter()]
        [System.String]
        $SyncDBName,

        [Parameter()]
        [System.String]
        $SyncDBServer,

        [Parameter()]
        [System.Boolean]
        $EnableNetBIOS = $false,

        [Parameter()]
        [System.Boolean]
        $NoILMUsed = $false,

        [Parameter()]
        [ValidateSet("Username_CollisionError", "Username_CollisionDomain", "Domain_Username")]
        [System.String]
        $SiteNamingConflictResolution,

        [Parameter()]
        [System.Boolean]
        $UpdateProxyGroup = $true,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting user profile service application $Name"

    if ($PSBoundParameters.ContainsKey("MySiteHostLocation") -eq $false)
    {
        Write-Verbose -Message ("You should also specify the MySiteHostLocation parameter. " + `
                "This will be required as of SharePointDsc v4.0")
    }

    if ($Ensure -eq "Present")
    {
        $PSBoundParameters.UpdateProxyGroup = $UpdateProxyGroup

        $farmAccount = Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            return Get-SPDscFarmAccount
        }

        if ($null -ne $farmAccount)
        {
            if ($PSBoundParameters.ContainsKey("InstallAccount") -eq $true)
            {
                # InstallAccount used
                if ($InstallAccount.UserName -eq $farmAccount.UserName)
                {
                    throw ("Specified InstallAccount ($($InstallAccount.UserName)) is the Farm " + `
                            "Account. Make sure the specified InstallAccount isn't the Farm Account " + `
                            "and try again")
                }
                $setupAccount = $InstallAccount.UserName
            }
            else
            {
                # PSDSCRunAsCredential or System
                if (-not $Env:USERNAME.Contains("$"))
                {
                    # PSDSCRunAsCredential used
                    $localaccount = "$($Env:USERDOMAIN)\$($Env:USERNAME)"
                    if ($localaccount -eq $farmAccount.UserName)
                    {
                        throw ("Specified PSDSCRunAsCredential ($localaccount) is the Farm " + `
                                "Account. Make sure the specified PSDSCRunAsCredential isn't the " + `
                                "Farm Account and try again")
                    }
                    $setupAccount = $localaccount
                }
            }
        }
        else
        {
            throw ("Unable to retrieve the Farm Account. Check if the farm exists.")
        }

        Write-Verbose -Message "Creating user profile service application $Name"

        # Add the FarmAccount to the local Administrators group, if it's not already there
        $isLocalAdmin = Test-SPDscUserIsLocalAdmin -UserName $farmAccount.UserName

        if (!$isLocalAdmin)
        {
            Write-Verbose -Message "Adding farm account to Local Administrators group"
            Add-SPDscUserToLocalAdmin -UserName $farmAccount.UserName

            # Cycle the Timer Service and flush Kerberos tickets
            # so that it picks up the local Admin token
            Restart-Service -Name "SPTimerV4"

            Clear-SPDscKerberosToken -Account $farmAccount.UserName
        }

        $null = Invoke-SPDscCommand -Credential $FarmAccount `
            -Arguments @($PSBoundParameters, $setupAccount) `
            -ScriptBlock {
            $params = $args[0]
            $setupAccount = $args[1]

            $updateEnableNetBIOS = $false
            if ($params.ContainsKey("EnableNetBIOS"))
            {
                $updateEnableNetBIOS = $true
                $enableNetBIOS = $params.EnableNetBIOS
                $params.Remove("EnableNetBIOS") | Out-Null
            }

            $updateNoILMUsed = $false
            if ($params.ContainsKey("NoILMUsed"))
            {
                $updateNoILMUsed = $true
                $NoILMUsed = $params.NoILMUsed
                $params.Remove("NoILMUsed") | Out-Null
            }

            $updateProxyGroup = $params.UpdateProxyGroup
            $params.Remove("UpdateProxyGroup") | Out-Null

            $updateSiteNamingConflict = $false
            if ($params.ContainsKey("SiteNamingConflictResolution"))
            {
                $updateSiteNamingConflict = $true
                $SiteNamingConflictResolution = $params.SiteNamingConflictResolution
                $params.Remove("SiteNamingConflictResolution") | Out-Null
            }

            if ($params.ContainsKey("InstallAccount"))
            {
                $params.Remove("InstallAccount") | Out-Null
            }
            if ($params.ContainsKey("Ensure"))
            {
                $params.Remove("Ensure") | Out-Null
            }

            $params = Rename-SPDscParamValue -params $params `
                -oldName "SyncDBName" `
                -newName "ProfileSyncDBName"

            $params = Rename-SPDscParamValue -params $params `
                -oldName "SyncDBServer" `
                -newName "ProfileSyncDBServer"

            $pName = "$($params.Name) Proxy"

            if ($params.ContainsKey("ProxyName") -and $null -ne $params.ProxyName)
            {
                $pName = $params.ProxyName
                $params.Remove("ProxyName") | Out-Null
            }

            $serviceApps = Get-SPServiceApplication -Name $params.Name `
                -ErrorAction SilentlyContinue
            $app = $serviceApps | Select-Object -First 1
            if ($null -eq $serviceApps)
            {
                $app = New-SPProfileServiceApplication @params
                if ($null -eq $app)
                {
                    throw ("An error occurred during creation of the service application: " + `
                            $_.Exception.Message)
                }
                New-SPProfileServiceApplicationProxy -Name $pName `
                    -ServiceApplication $app `
                    -DefaultProxyGroup

                $claimsPrincipal = New-SPClaimsPrincipal -Identity $setupAccount `
                    -IdentityType WindowsSamAccountName

                $serviceAppSecurity = Get-SPServiceApplicationSecurity $app
                $acl = [Microsoft.SharePoint.Administration.AccessControl.SPNamedIisWebServiceApplicationRights]::FullControl.Name
                Grant-SPObjectSecurity -Identity $serviceAppSecurity `
                    -Principal $claimsPrincipal `
                    -Rights $acl
                Set-SPServiceApplicationSecurity -Identity $app `
                    -ObjectSecurity $serviceAppSecurity

                $app = Get-SPServiceApplication -Name $params.Name `
                    -ErrorAction SilentlyContinue
            }

            $updateServiceApp = $false

            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue
            if ($null -ne $serviceAppProxies)
            {
                $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                    $app.IsConnected($_)
                }
                if ($null -ne $serviceAppProxy)
                {
                    $proxyName = $serviceAppProxy.Name
                }
            }

            if ($updateProxyGroup -eq $true)
            {
                $proxyGroups = Get-SPServiceApplicationProxyGroup

                $proxyGroup = $proxyGroups | Where-Object -FilterScript {
                    $_.Proxies.DisplayName -contains $proxyName
                } | Select-Object -First 1

                if ($null -ne $proxyGroup -and `
                        $proxyGroup -ne $app.ServiceApplicationProxyGroup)
                {
                    Write-Verbose -Message "Updating ServiceApplicationProxyGroup property"
                    $app.ServiceApplicationProxyGroup = $proxyGroup
                    $updateServiceApp = $true
                }
            }

            if (($updateEnableNetBIOS -eq $true) -or ($updateNoILMUsed -eq $true))
            {
                if (($updateEnableNetBIOS -eq $true) -and `
                    ($app.NetBIOSDomainNamesEnabled -ne $enableNetBIOS))
                {
                    Write-Verbose -Message "Updating NetBIOSDomainNamesEnabled property"
                    $app.NetBIOSDomainNamesEnabled = $enableNetBIOS
                }

                if (($updateNoILMUsed -eq $true) -and `
                    ($app.NoILMUsed -ne $NoILMUsed))
                {
                    Write-Verbose -Message "Updating NoILMUsed property"
                    $app.NoILMUsed = $NoILMUsed
                }
                $updateServiceApp = $true
            }

            if ($updateServiceApp -eq $true)
            {
                Write-Verbose -Message "Storing updated UPS Service App settings"
                $app.Update()
            }

            if ($updateSiteNamingConflict -eq $true)
            {
                Write-Verbose -Message "Updating SiteNamingConflict setting"
                $ca = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript { $_.IsAdministrationWebApplication }
                $caSite = $ca.Sites[0]
                $serviceContext = Get-SPServiceContext($caSite)
                $userProfileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($serviceContext)
                $userProfileManager.PersonalSiteFormat = $SiteNamingConflictResolution
            }
        }

        # Remove the InstallAccount from the local Administrators group, if it was added above
        if (!$isLocalAdmin)
        {
            Write-Verbose -Message "Removing farm account from Local Administrators group"
            Remove-SPDscUserToLocalAdmin -UserName $farmAccount.UserName

            # Cycle the Timer Service and flush Kerberos tickets
            # so that it picks up the local Admin token
            Restart-Service -Name "SPTimerV4"

            Clear-SPDscKerberosToken -Account $farmAccount.UserName
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing user profile service application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {

            $params = $args[0]

            $app = Get-SPServiceApplication -Name $params.Name `
            | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.Office.Server.Administration.UserProfileApplication"
            }

            $proxies = Get-SPServiceApplicationProxy
            foreach ($proxyInstance in $proxies)
            {
                if ($app.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication -Identity $app -Confirm:$false
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
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $MySiteHostLocation,

        [Parameter()]
        [System.String]
        $MySiteManagedPath,

        [Parameter()]
        [System.String]
        $ProfileDBName,

        [Parameter()]
        [System.String]
        $ProfileDBServer,

        [Parameter()]
        [System.String]
        $SocialDBName,

        [Parameter()]
        [System.String]
        $SocialDBServer,

        [Parameter()]
        [System.String]
        $SyncDBName,

        [Parameter()]
        [System.String]
        $SyncDBServer,

        [Parameter()]
        [System.Boolean]
        $EnableNetBIOS = $false,

        [Parameter()]
        [System.Boolean]
        $NoILMUsed = $false,

        [Parameter()]
        [ValidateSet("Username_CollisionError", "Username_CollisionDomain", "Domain_Username")]
        [System.String]
        $SiteNamingConflictResolution,

        [Parameter()]
        [System.Boolean]
        $UpdateProxyGroup = $true,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing for user profile service application $Name"

    if ($PSBoundParameters.ContainsKey("MySiteHostLocation") -eq $false)
    {
        Write-Verbose -Message ("You should also specify the MySiteHostLocation parameter. " + `
                "This will be required as of SharePointDsc v4.0")
    }

    $PSBoundParameters.Ensure = $Ensure
    $PSBoundParameters.UpdateProxyGroup = $UpdateProxyGroup

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        if ($UpdateProxyGroup -eq $true -and `
                $CurrentValues.UpdateProxyGroup -eq $true)
        {
            return $false
        }

        return Test-SPDscParameterState -CurrentValues $CurrentValues `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Name",
            "EnableNetBIOS",
            "NoILMUsed",
            "SiteNamingConflictResolution",
            "Ensure")
    }
    else
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Name", "Ensure")
    }
}

Export-ModuleMember -Function *-TargetResource
