$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $UserProfileServiceAppName,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String] $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $RunOnlyWhenWriteable,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile sync service for $UserProfileServiceAppName"

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -ne 15)
    {
        $message = ("Only SharePoint 2013 is supported to deploy the user profile sync " + `
                "service via DSC, as 2016/2019 do not use the FIM based sync service.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
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
                $message = ("Specified InstallAccount ($($InstallAccount.UserName)) is the Farm " + `
                        "Account. Make sure the specified InstallAccount isn't the Farm Account " + `
                        "and try again")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
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
                    $message = ("Specified PSDSCRunAsCredential ($localaccount) is the Farm " + `
                            "Account. Make sure the specified PSDSCRunAsCredential isn't the " + `
                            "Farm Account and try again")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
                }
            }
        }
    }
    else
    {
        $message = ("Unable to retrieve the Farm Account. Check if the farm exists.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $services = Get-SPServiceInstance -Server $env:COMPUTERNAME `
            -ErrorAction SilentlyContinue

        if ($null -eq $services)
        {
            return @{
                UserProfileServiceAppName = $params.UserProfileServiceAppName
                Ensure                    = "Absent"
                RunOnlyWhenWriteable      = $params.RunOnlyWhenWriteable
            }
        }

        $syncService = $services | Where-Object -FilterScript {
            $_.GetType().Name -eq "ProfileSynchronizationServiceInstance"
        }

        if ($null -eq $syncService)
        {
            $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
            $currentServer = "$($env:COMPUTERNAME).$domain"
            $services = Get-SPServiceInstance -Server $currentServer `
                -ErrorAction SilentlyContinue
            $syncService = $services | Where-Object -FilterScript {
                $_.GetType().Name -eq "ProfileSynchronizationServiceInstance"
            }
        }

        if ($null -eq $syncService)
        {
            return @{
                UserProfileServiceAppName = $params.UserProfileServiceAppName
                Ensure                    = "Absent"
                RunOnlyWhenWriteable      = $params.RunOnlyWhenWriteable
            }
        }
        if ($null -ne $syncService.UserProfileApplicationGuid -and `
                $syncService.UserProfileApplicationGuid -ne [Guid]::Empty)
        {
            $upa = Get-SPServiceApplication -Identity $syncService.UserProfileApplicationGuid `
                -ErrorAction SilentlyContinue
        }
        if ($syncService.Status -eq "Online")
        {
            $localEnsure = "Present"
        }
        else
        {
            $localEnsure = "Absent"
        }

        return @{
            UserProfileServiceAppName = $upa.Name
            Ensure                    = $localEnsure
            RunOnlyWhenWriteable      = $params.RunOnlyWhenWriteable
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
        $UserProfileServiceAppName,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String] $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $RunOnlyWhenWriteable,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting user profile sync service for $UserProfileServiceAppName"

    $PSBoundParameters.Ensure = $Ensure

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -ne 15)
    {
        $message = ("Only SharePoint 2013 is supported to deploy the user profile sync " + `
                "service via DSC, as 2016/2019 do not use the FIM based sync service.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
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
                $message = ("Specified InstallAccount ($($InstallAccount.UserName)) is the Farm " + `
                        "Account. Make sure the specified InstallAccount isn't the Farm Account " + `
                        "and try again")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
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
                    $message = ("Specified PSDSCRunAsCredential ($localaccount) is the Farm " + `
                            "Account. Make sure the specified PSDSCRunAsCredential isn't the " + `
                            "Farm Account and try again")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
                }
            }
        }
    }
    else
    {
        $message = ("Unable to retrieve the Farm Account. Check if the farm exists.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("RunOnlyWhenWriteable") -eq $true)
    {
        $databaseReadOnly = Test-SPDscUserProfileDBReadOnly `
            -UserProfileServiceAppName $UserProfileServiceAppName `
            -InstallAccount $InstallAccount

        if ($databaseReadOnly)
        {
            Write-Verbose -Message ("User profile database is read only, setting user profile " + `
                    "sync service to not run on the local server")
            $PSBoundParameters.Ensure = "Absent"
        }
        else
        {
            $PSBoundParameters.Ensure = "Present"
        }
    }

    # Add the Farm Account to the local Admins group, if it's not already there
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

    $isInDesiredState = $false
    try
    {
        Invoke-SPDscCommand -Credential $FarmAccount `
            -Arguments ($PSBoundParameters, $MyInvocation.MyCommand.Source, $farmAccount) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]
            $farmAccount = $args[2]

            $currentServer = $env:COMPUTERNAME

            $services = Get-SPServiceInstance -Server $currentServer `
                -ErrorAction SilentlyContinue
            $syncService = $services | Where-Object -FilterScript {
                $_.GetType().Name -eq "ProfileSynchronizationServiceInstance"
            }
            if ($null -eq $syncService)
            {
                $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                $currentServer = "$currentServer.$domain"
                $syncService = $services | Where-Object -FilterScript {
                    $_.GetType().Name -eq "ProfileSynchronizationServiceInstance"
                }
            }
            if ($null -eq $syncService)
            {
                $message = "Unable to locate a user profile sync service instance on $currentServer to start"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            # Start the Sync service if it should be running on this server
            if (($params.Ensure -eq "Present") -and ($syncService.Status -ne "Online"))
            {
                $ups = Get-SPServiceApplication | Where-Object -FilterScript {
                    $_.Name -eq $params.UserProfileServiceAppName
                }

                if ($null -eq $ups)
                {
                    $message = ("No User Profile Service Application was found " + `
                            "named $($params.UserProfileServiceAppName)")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                $userName = $farmAccount.UserName
                $password = $farmAccount.GetNetworkCredential().Password
                $ups.SetSynchronizationMachine($currentServer, $syncService.ID, $userName, $password)

                Start-SPServiceInstance -Identity $syncService.ID

                $desiredState = "Online"
            }
            # Stop the Sync service in all other cases
            else
            {
                Stop-SPServiceInstance -Identity $syncService.ID -Confirm:$false
                $desiredState = "Disabled"
            }

            $count = 0
            $maxCount = 20

            while (($count -lt $maxCount) -and ($syncService.Status -ne $desiredState))
            {
                if ($syncService.Status -ne $desiredState)
                {
                    Start-Sleep -Seconds 60
                }

                # Get the current status of the Sync service
                Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting for user " + `
                        "profile sync service to become '$desiredState' (waited " + `
                        "$count of $maxCount minutes)")

                $services = Get-SPServiceInstance -Server $currentServer `
                    -ErrorAction SilentlyContinue
                $syncService = $services | Where-Object -FilterScript {
                    $_.GetType().Name -eq "ProfileSynchronizationServiceInstance"
                }
                $count++
            }

            if ($syncService.Status -ne $desiredState)
            {
                $message = "An error occured. We couldn't properly set the User Profile Sync Service on the server."
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
        }
    }
    finally
    {
        # Remove the Farm Account from the local Admins group, if it was added above
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
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $UserProfileServiceAppName,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String] $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $RunOnlyWhenWriteable,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing user profile sync service for $UserProfileServiceAppName"

    $PSBoundParameters.Ensure = $Ensure

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -ne 15)
    {
        $message = ("Only SharePoint 2013 is supported to deploy the user profile sync " + `
                "service via DSC, as 2016/2019 do not use the FIM based sync service.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($PSBoundParameters.ContainsKey("RunOnlyWhenWriteable") -eq $true)
    {
        $databaseReadOnly = Test-SPDscUserProfileDBReadOnly `
            -UserProfileServiceAppName $UserProfileServiceAppName `
            -InstallAccount $InstallAccount

        if ($databaseReadOnly)
        {
            Write-Verbose -Message ("User profile database is read only, setting user profile " + `
                    "sync service to not run on the local server")
            $PSBoundParameters.Ensure = "Absent"
        }
        else
        {
            $PSBoundParameters.Ensure = "Present"
        }
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Test-SPDscUserProfileDBReadOnly()
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $UserProfileServiceAppName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $databaseReadOnly = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($UserProfileServiceAppName, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $UserProfileServiceAppName = $args[0]
        $eventSource = $args[1]

        $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.UserProfileServiceAppName
        }

        if ($null -eq $serviceApps)
        {
            $message = ("No user profile service was found " + `
                    "named $UserProfileServiceAppName")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }
        $ups = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.Office.Server.Administration.UserProfileApplication"
        }

        $propType = $ups.GetType()
        $propData = $propType.GetProperties([System.Reflection.BindingFlags]::Instance -bor `
                [System.Reflection.BindingFlags]::NonPublic)
        $profileProp = $propData | Where-Object -FilterScript {
            $_.Name -eq "ProfileDatabase"
        }
        $profileDBName = $profileProp.GetValue($ups).Name

        $database = Get-SPDatabase | Where-Object -FilterScript {
            $_.Name -eq $profileDBName
        }
        return $database.IsReadyOnly
    }
    return $databaseReadOnly
}

<## This function retrieves all Services in the SharePoint farm. It does not care if the service is enabled or not. It lists them all, and simply sets the "Ensure" attribute of those that are disabled to "Absent". #>
function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String[]]
        $Servers
    )

    $VerbosePreference = "SilentlyContinue"
    $servicesMasterList = @()
    foreach ($Server in $Servers)
    {
        Write-Host "Scanning SPServiceInstance on {$Server}"
        $serviceInstancesOnCurrentServer = Get-SPServiceInstance -Server $Server | Sort-Object -Property TypeName
        $serviceStatuses = @()
        $ensureValue = "Present"

        $i = 1
        $total = $serviceInstancesOnCurrentServer.Length
        foreach ($serviceInstance in $serviceInstancesOnCurrentServer)
        {
            try
            {
                $serviceTypeName = $serviceInstance.GetType().Name
                Write-Host "    -> Scanning instance [$i/$total] {$serviceTypeName}"

                if ($serviceInstance.Status -eq "Online")
                {
                    $ensureValue = "Present"
                }
                else
                {
                    $ensureValue = "Absent"
                }

                $currentService = @{
                    Name   = $serviceInstance.TypeName
                    Ensure = $ensureValue
                }

                if ($serviceTypeName -ne "SPDistributedCacheServiceInstance" -and $serviceTypeName -ne "ProfileSynchronizationServiceInstance")
                {
                    $serviceStatuses += $currentService
                }
                if ($ensureValue -eq "Present" -and !$servicesMasterList.Contains($serviceTypeName))
                {
                    $servicesMasterList += $serviceTypeName
                    if ($serviceTypeName -eq "ProfileSynchronizationServiceInstance")
                    {
                        $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
                        $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPUserProfileSyncService\MSFT_SPUserProfileSyncService.psm1" -Resolve
                        $Content = ''
                        $params = Get-DSCFakeParameters -ModulePath $module
                        $params.Ensure = $ensureValue
                        if ($null -eq $params.InstallAccount)
                        {
                            $params.Remove("InstallAccount")
                        }
                        $results = Get-TargetResource @params
                        if ($ensureValue -eq "Present")
                        {
                            $PartialContent = "        SPUserProfileSyncService " + $serviceTypeName.Replace(" ", "") + "Instance`r`n"
                            $PartialContent += "        {`r`n"

                            if ($results.Contains("InstallAccount"))
                            {
                                $results.Remove("InstallAccount")
                            }
                            $results = Repair-Credentials -results $results
                            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                            $PartialContent += $currentBlock
                            $PartialContent += "        }`r`n"
                            $Content += $PartialContent
                        }
                    }
                }
                $i++
            }
            catch
            {
                $_
                $Global:ErrorLog += "[Service Instance]" + $serviceInstance.TypeName + "`r`n"
                $Global:ErrorLog += "$_`r`n`r`n"
            }
        }

        if ($DynamicCompilation)
        {
            Add-ConfigurationDataEntry -Node  $env:ComputerName -Key "ServiceInstances" -Value $serviceStatuses
        }
        elseif ($StandAlone)
        {
            Add-ConfigurationDataEntry -Node $env:ComputerName -Key "ServiceInstances" -Value $serviceStatuses
        }
        elseif ($servicesStatuses.Length -gt 0)
        {
            Add-ConfigurationDataEntry -Node $Server -Key "ServiceInstances" -Value $serviceStatuses
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
