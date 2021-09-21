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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $CacheSizeInMB,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $CreateFirewallRules,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String[]]
        $ServerProvisionOrder,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting the cache host information"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $nullReturnValue = @{
            Name   = $params.Name
            Ensure = "Absent"
        }

        try
        {
            if (Get-Command -Name "Use-CacheCluster" -ErrorAction SilentlyContinue)
            {
                Use-CacheCluster -ErrorAction SilentlyContinue
            }
            else # Use new cmdlet for SP SE
            {
                Write-Verbose -Message "'Use-CacheCluster' cmdlet not required for SPSE"
            }
            if (Get-Command -Name "Get-CacheHost" -ErrorAction SilentlyContinue)
            {
                $cacheHost = Get-CacheHost -ErrorAction SilentlyContinue
            }
            else # Use new cmdlet for SP SE
            {
                Write-Verbose -Message "Using newer 'Get-SPCacheHostConfig' cmdlet for SPSE"
                $cacheHostConfig = Get-SPCacheHostConfig -HostName $env:COMPUTERNAME -ErrorAction SilentlyContinue
                $cacheHost = Get-SPCacheHost -HostName $cacheHostConfig.HostName -CachePort $cacheHostConfig.CachePort
            }

            if ($null -eq $cacheHost)
            {
                return $nullReturnValue
            }

            if (Get-Command -Name "Get-AFCacheHostConfiguration" -ErrorAction SilentlyContinue)
            {
                $computerName = ([System.Net.Dns]::GetHostByName($env:computerName)).HostName
                $cachePort = ($cacheHost | Where-Object -FilterScript {
                        $_.HostName -eq $computerName
                    }).PortNo
                $cacheHostConfig = Get-AFCacheHostConfiguration -ComputerName $computerName `
                    -CachePort $cachePort `
                    -ErrorAction SilentlyContinue
            }

            $windowsService = Get-CimInstance -Class Win32_Service -Filter "Name='AppFabricCachingService' OR Name='SPCache'"
            $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distributed Cache" `
                -ErrorAction SilentlyContinue

            return @{
                Name                 = $params.Name
                CacheSizeInMB        = $cacheHostConfig.Size
                ServiceAccount       = $windowsService.StartName
                CreateFirewallRules  = ($null -ne $firewallRule)
                Ensure               = "Present"
                ServerProvisionOrder = $params.ServerProvisionOrder
            }
        }
        catch
        {
            return $nullReturnValue
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

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $CacheSizeInMB,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $CreateFirewallRules,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String[]]
        $ServerProvisionOrder,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting the cache host information"

    $CurrentState = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present")
    {
        Write-Verbose -Message "Adding the distributed cache to the server"
        if ($createFirewallRules -eq $true)
        {
            Write-Verbose -Message "Create a firewall rule for AppFabric"
            Invoke-SPDscCommand -Credential $InstallAccount -ScriptBlock {
                $icmpRuleName = "File and Printer Sharing (Echo Request - ICMPv4-In)"
                $icmpFirewallRule = Get-NetFirewallRule -DisplayName $icmpRuleName `
                    -ErrorAction SilentlyContinue
                if ($null -eq $icmpFirewallRule )
                {
                    New-NetFirewallRule -Name Allow_Ping -DisplayName $icmpRuleName `
                        -Description "Allow ICMPv4 ping" `
                        -Protocol ICMPv4 `
                        -IcmpType 8 `
                        -Enabled True `
                        -Profile Any `
                        -Action Allow
                }
                Enable-NetFirewallRule -DisplayName $icmpRuleName

                $spRuleName = "SharePoint Distributed Cache"
                $firewallRule = Get-NetFirewallRule -DisplayName $spRuleName `
                    -ErrorAction SilentlyContinue
                if ($null -eq $firewallRule)
                {
                    New-NetFirewallRule -Name "SPDistCache" `
                        -DisplayName $spRuleName `
                        -Protocol TCP `
                        -LocalPort 22233-22236 `
                        -Group "SharePoint"
                }
                Enable-NetFirewallRule -DisplayName $spRuleName
            }
            Write-Verbose -Message "Firewall rule added"
        }

        Write-Verbose -Message ("Current state is '$($CurrentState.Ensure)' " + `
                "and desired state is '$Ensure'")

        if ($CurrentState.Ensure -ne $Ensure)
        {
            Write-Verbose -Message "Enabling distributed cache service"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
                -ScriptBlock {
                $params = $args[0]
                $eventSource = $args[1]

                if ($params.ContainsKey("ServerProvisionOrder"))
                {
                    $serverCount = 0
                    $currentServer = $params.ServerProvisionOrder[$serverCount]

                    while ($currentServer -ne $env:COMPUTERNAME)
                    {
                        $count = 0
                        $maxCount = 30

                        # Attempt to see if we can find the service with just the computer
                        # name, or if we need to use the FQDN
                        $si = Get-SPServiceInstance -Server $currentServer `
                        | Where-Object -FilterScript {
                            $_.GetType().Name -eq "SPDistributedCacheServiceInstance"
                        }

                        if ($null -eq $si)
                        {
                            $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                            $currentServer = "$currentServer.$domain"
                        }

                        Write-Verbose "Waiting for cache on $currentServer"
                        $serviceCheck = Get-SPServiceInstance -Server $currentServer `
                        | Where-Object -FilterScript {
                            $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                                $_.Status -eq "Online"
                        }

                        while (($count -lt $maxCount) -and ($null -eq $serviceCheck))
                        {
                            Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - " + `
                                    "Waiting for distributed cache to start " + `
                                    "on $currentServer (waited $count of " + `
                                    "$maxCount minutes)")
                            Start-Sleep -Seconds 60
                            $serviceCheck = Get-SPServiceInstance -Server $currentServer `
                            | Where-Object -FilterScript {
                                $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                                    $_.Status -eq "Online"
                            }
                            $count++
                        }

                        $serviceCheck = Get-SPServiceInstance -Server $currentServer `
                        | Where-Object -FilterScript {
                            $_.GetType().Name -eq "SPDistributedCacheServiceInstance" `
                                -and $_.Status -eq "Online"
                        }

                        if ($null -eq $serviceCheck)
                        {
                            Write-Warning -Message ("Server $currentServer is not running " + `
                                    "distributed cache after waiting 30 " + `
                                    "minutes. No longer waiting for this " + `
                                    "server, progressing to next action")
                        }

                        $serverCount++

                        if ($ServerCount -ge $params.ServerProvisionOrder.Length)
                        {
                            $message = ("The server $($env:COMPUTERNAME) was not found in the " + `
                                    "ServerProvisionOrder array of Distributed Cache server(s).  " + `
                                    "The server must be included in ServerProvisionOrder or Ensure " + `
                                    "equal to Absent.")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message

                        }
                        $currentServer = $params.ServerProvisionOrder[$serverCount]
                    }
                }

                Add-SPDistributedCacheServiceInstance

                try
                {
                    Get-SPServiceInstance | Where-Object -FilterScript {
                        $_.GetType().Name -eq "SPDistributedCacheServiceInstance"
                    } | Stop-SPServiceInstance -Confirm:$false
                }
                catch
                {
                    # In SharePoint 2019, Stop-SPServiceInstance throws an exception if service
                    # is not running on the server, try/catch handles this scenario
                    Write-Verbose -Message ("Cannot stop an already stopped service. Continuing.")
                }

                $count = 0
                $maxCount = 30

                $serviceCheck = Get-SPServiceInstance | Where-Object -FilterScript {
                    $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                        $_.Status -ne "Disabled"
                }

                while (($count -lt $maxCount) -and ($null -ne $serviceCheck))
                {
                    Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting " + `
                            "for distributed cache to stop on all servers " + `
                            "(waited $count of $maxCount minutes)")
                    Start-Sleep -Seconds 60
                    $serviceCheck = Get-SPServiceInstance | Where-Object -FilterScript {
                        $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                            $_.Status -ne "Disabled"
                    }
                    $count++
                }

                Update-SPDistributedCacheSize -CacheSizeInMB $params.CacheSizeInMB

                Get-SPServiceInstance | Where-Object -FilterScript {
                    $_.GetType().Name -eq "SPDistributedCacheServiceInstance"
                } | Start-SPServiceInstance

                $count = 0
                $maxCount = 30

                $serviceCheck = Get-SPServiceInstance | Where-Object -FilterScript {
                    $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                        $_.Status -ne "Online"
                }

                while (($count -lt $maxCount) -and ($null -ne $serviceCheck))
                {
                    Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting " + `
                            "for distributed cache to start on all servers " + `
                            "(waited $count of $maxCount minutes)")
                    Start-Sleep -Seconds 60
                    $serviceCheck = Get-SPServiceInstance | Where-Object -FilterScript {
                        $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                            $_.Status -ne "Online"
                    }
                    $count++
                }

                $farm = Get-SPFarm
                $cacheService = $farm.Services | Where-Object -FilterScript {
                    $_.Name -eq "AppFabricCachingService" -or $_.Name -eq "SPCache"
                }

                if ($cacheService.ProcessIdentity.ManagedAccount.Username -ne $params.ServiceAccount)
                {
                    $cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
                    $account = Get-SPManagedAccount -Identity $params.ServiceAccount
                    $cacheService.ProcessIdentity.ManagedAccount = $account
                    $cacheService.ProcessIdentity.Update()
                    try
                    {
                        $cacheService.ProcessIdentity.Deploy()
                    }
                    catch
                    {
                        # In SharePoint 2019, ProcessIdentity.Deploy() may throw an exception
                        Write-Verbose -Message ("An error has occurred while updating the " + `
                                "ServiceAccount. The change will be retried.")
                    }
                }
            }
        }
        else
        {
            if ($CurrentState.ServiceAccount -ne $ServiceAccount.UserName)
            {
                Invoke-SPDscCommand -Credential $InstallAccount `
                    -Arguments $PSBoundParameters `
                    -ScriptBlock {
                    $params = $args[0]
                    $farm = Get-SPFarm
                    $cacheService = $farm.Services | Where-Object -FilterScript {
                        $_.Name -eq "AppFabricCachingService" -or $_.Name -eq "SPCache"
                    }

                    if ($cacheService.ProcessIdentity.ManagedAccount.Username -ne $params.ServiceAccount)
                    {
                        $cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
                        $account = Get-SPManagedAccount -Identity $params.ServiceAccount
                        $cacheService.ProcessIdentity.ManagedAccount = $account
                        $cacheService.ProcessIdentity.Update()
                        try
                        {
                            $cacheService.ProcessIdentity.Deploy()
                        }
                        catch
                        {
                            # In SharePoint 2019, ProcessIdentity.Deploy() may throw an exception
                            Write-Verbose -Message ("An error has occurred while updating the " + `
                                    "ServiceAccount. The change will be retried.")
                        }
                    }
                }
            }

            if ($CurrentState.CacheSizeInMB -ne $CacheSizeInMB)
            {
                Write-Verbose -Message "Updating distributed cache service cache size"
                Invoke-SPDscCommand -Credential $InstallAccount `
                    -Arguments $PSBoundParameters `
                    -ScriptBlock {
                    $params = $args[0]

                    Get-SPServiceInstance | Where-Object -FilterScript {
                        $_.GetType().Name -eq "SPDistributedCacheServiceInstance"
                    } | Stop-SPServiceInstance -Confirm:$false

                    $count = 0
                    $maxCount = 30

                    $serviceCheck = Get-SPServiceInstance | Where-Object -FilterScript {
                        $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                            $_.Status -ne "Disabled"
                    }

                    while (($count -lt $maxCount) -and ($null -ne $serviceCheck))
                    {
                        Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting " + `
                                "for distributed cache to stop on all servers " + `
                                "(waited $count of $maxCount minutes)")
                        Start-Sleep -Seconds 60
                        $serviceCheck = Get-SPServiceInstance | Where-Object -FilterScript {
                            $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                                $_.Status -ne "Disabled"
                        }
                        $count++
                    }

                    Update-SPDistributedCacheSize -CacheSizeInMB $params.CacheSizeInMB

                    Get-SPServiceInstance | Where-Object -FilterScript {
                        $_.GetType().Name -eq "SPDistributedCacheServiceInstance"
                    } | Start-SPServiceInstance

                    $count = 0
                    $maxCount = 30

                    $serviceCheck = Get-SPServiceInstance | Where-Object -FilterScript {
                        $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                            $_.Status -ne "Online"
                    }

                    while (($count -lt $maxCount) -and ($null -ne $serviceCheck))
                    {
                        Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting " + `
                                "for distributed cache to start on all servers " + `
                                "(waited $count of $maxCount minutes)")
                        Start-Sleep -Seconds 60
                        $serviceCheck = Get-SPServiceInstance | Where-Object -FilterScript {
                            $_.GetType().Name -eq "SPDistributedCacheServiceInstance" -and `
                                $_.Status -ne "Online"
                        }
                        $count++
                    }
                }
            }
        }
    }
    else
    {
        Write-Verbose -Message "Removing distributed cache to the server"
        Invoke-SPDscCommand -Credential $InstallAccount -ScriptBlock {
            Remove-SPDistributedCacheServiceInstance

            $serviceInstance = Get-SPServiceInstance -Server $env:computername `
            | Where-Object -FilterScript {
                $_.GetType().Name -eq "SPDistributedCacheServiceInstance"
            }

            if ($null -eq $serviceInstance)
            {
                $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                $currentServer = "$($env:computername).$domain"
                $serviceInstance = Get-SPServiceInstance -Server $currentServer `
                | Where-Object -FilterScript {
                    $_.GetType().Name -eq "SPDistributedCacheServiceInstance"
                }
            }
            if ($null -ne $serviceInstance)
            {
                $serviceInstance.Delete()
            }
        }
        if ($CreateFirewallRules -eq $true)
        {
            Invoke-SPDscCommand -Credential $InstallAccount -ScriptBlock {
                $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distribute Cache" `
                    -ErrorAction SilentlyContinue
                if ($null -ne $firewallRule)
                {
                    Write-Verbose -Message "Disabling firewall rules."
                    Disable-NetFirewallRule -DisplayName "SharePoint Distribute Cache"
                }
            }
        }
        Write-Verbose -Message "Distributed cache removed."
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

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $CacheSizeInMB,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $CreateFirewallRules,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String[]]
        $ServerProvisionOrder,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing the cache host information"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        if ($PSBoundParameters.ContainsKey("ServiceAccount"))
        {
            if ($ServiceAccount -ne $CurrentValues.ServiceAccount)
            {
                $message = ("The parameter ServiceAccount is not in the desired " + `
                        "state. Actual: $($CurrentValues.ServiceAccount), " + `
                        "Desired: $ServiceAccount")
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                Write-Verbose -Message "Test-TargetResource returned false"
                return $false
            }
        }

        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure", `
                "CreateFirewallRules", `
                "CacheSizeInMB")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPDistributedCacheService\MSFT_SPDistributedCacheService.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $params.Name = "DistributedCache"
    $results = Get-TargetResource @params
    if ($results.Get_Item("Ensure").ToLower() -eq "present" -and $results.Contains("CacheSizeInMB"))
    {
        $PartialContent = "        SPDistributedCacheService " + [System.Guid]::NewGuid().ToString() + "`r`n"
        $PartialContent += "        {`r`n"
        $results = Repair-Credentials -results $results
        $results.Remove("ServerProvisionOrder")

        $serviceAccount = Get-Credentials -UserName $results.ServiceAccount
        $convertToVariable = $false
        if ($serviceAccount)
        {
            $convertToVariable = $true
            $results.ServiceAccount = (Resolve-Credentials -UserName $results.ServiceAccount) + ".UserName"
        }
        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
        if ($convertToVariable)
        {
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "ServiceAccount"
        }
        $PartialContent += $currentBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
