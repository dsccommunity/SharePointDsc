function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ProxyName,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ApplicationPool,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumTimeBetweenEwsSyncSubscriptionSearches, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumTimeBetweenProviderRefreshes, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumTimeBetweenSearchQueries, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfSubscriptionSyncsPerEwsSyncRun, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfUsersEwsSyncWillProcessAtOnce, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfUsersPerEwsSyncBatch,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Work management service app '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue

        $nullReturn = @{
            Name = $params.Name
            Ensure = "Absent"
        } 

        if ($null -eq $serviceApps)
        { 
            return $nullReturn 
        }

        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.TypeName -eq "Work Management Service Application"
        }
        if ($null -eq $serviceApp)
        { 
            return $nullReturn 
        }
        else
        {
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

            return @{
                Name                                          = $serviceApp.DisplayName
                ProxyName                                     = $proxyName
                ApplicationPool                               = $serviceApp.ApplicationPool.Name
                MinimumTimeBetweenEwsSyncSubscriptionSearches = $serviceApp.AdminSettings.MinimumTimeBetweenEwsSyncSubscriptionSearches.TotalMinutes 
                MinimumTimeBetweenProviderRefreshes           = $serviceApp.AdminSettings.MinimumTimeBetweenProviderRefreshes.TotalMinutes 
                MinimumTimeBetweenSearchQueries               = $serviceApp.AdminSettings.MinimumTimeBetweenProviderRefreshes.TotalMinutes 
                NumberOfSubscriptionSyncsPerEwsSyncRun        = $serviceApp.AdminSettings.NumberOfSubscriptionSyncsPerEwsSyncRun
                NumberOfUsersEwsSyncWillProcessAtOnce         = $serviceApp.AdminSettings.NumberOfUsersEwsSyncWillProcessAtOnce
                NumberOfUsersPerEwsSyncBatch                  = $serviceApp.AdminSettings.NumberOfUsersPerEwsSyncBatch
                Ensure                                        = "Present"
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
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ProxyName,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ApplicationPool,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumTimeBetweenEwsSyncSubscriptionSearches, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumTimeBetweenProviderRefreshes, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumTimeBetweenSearchQueries, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfSubscriptionSyncsPerEwsSyncRun, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfUsersEwsSyncWillProcessAtOnce, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfUsersPerEwsSyncBatch,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Work management service app '$Name'"

    if ($Ensure -ne "Absent" -and $null -eq $ApplicationPool)
    {
        throw "Parameter ApplicationPool is required unless service is being removed(Ensure='Absent')"
    }

    $PSBoundParameters.Ensure = $Ensure
    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]
<<<<<<< HEAD
        $app =  Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue `
        | Where-Object { $_.TypeName -eq "Work Management Service Application"  }

        if($null -ne $app -and $params.ContainsKey("Ensure") -and $params.Ensure -eq "Absent")
        {
            $proxies = Get-SPServiceApplicationProxy
            foreach($proxyInstance in $proxies)
            {
                if($app.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication -Identity $app -RemoveData -Confirm:$false
            return
        } elseif ($null -eq $app){
=======
        $appService =  Get-SPServiceApplication -Name $params.Name `
                                                -ErrorAction SilentlyContinue `
                       | Where-Object -FilterScript {
                           $_.TypeName -eq "Work Management Service Application"
                         }

        if ($null -ne $appService `
            -and $params.ContainsKey("Ensure") `
            -and $params.Ensure -eq "Absent")
        {
            #remove existing app
            Remove-SPServiceApplication $appService 
            return
        }
        elseif ($null -eq $appService)
        {
>>>>>>> refs/remotes/PowerShell/dev
            $newParams = @{}
            $newParams.Add("Name", $params.Name) 
            $newParams.Add("ApplicationPool", $params.ApplicationPool) 

<<<<<<< HEAD
            $app = New-SPWorkManagementServiceApplication @newParams
            if ($null -eq $params.ProxyName) {$pName = "$($params.Name) Proxy"} Else {$pName = $params.ProxyName}
            New-SPWorkManagementServiceApplicationProxy -Name $pName -DefaultProxyGroup -ServiceApplication $app | Out-Null
=======
            $appService = New-SPWorkManagementServiceApplication @newParams
            if ($null -eq $params.ProxyName)
            {
                $pName = "$($params.Name) Proxy"
            }
            else
            {
                $pName = $params.ProxyName
            }
            New-SPWorkManagementServiceApplicationProxy -Name $pName `
                                                        -DefaultProxyGroup `
                                                        -ServiceApplication $appService | Out-Null
>>>>>>> refs/remotes/PowerShell/dev
            Start-Sleep -Milliseconds 200
        }
        $setParams = @{}
        if ($params.ContainsKey("MinimumTimeBetweenEwsSyncSubscriptionSearches"))
        {
            $setParams.Add("MinimumTimeBetweenEwsSyncSubscriptionSearches", $params.MinimumTimeBetweenEwsSyncSubscriptionSearches)
        }
        
        if ($params.ContainsKey("MinimumTimeBetweenProviderRefreshes"))
        {
            $setParams.Add("MinimumTimeBetweenProviderRefreshes", $params.MinimumTimeBetweenProviderRefreshes)
        }
        
        if ($params.ContainsKey("MinimumTimeBetweenSearchQueries"))
        {
            $setParams.Add("MinimumTimeBetweenSearchQueries", $params.MinimumTimeBetweenSearchQueries)
        }
        
        if ($params.ContainsKey("NumberOfSubscriptionSyncsPerEwsSyncRun"))
        {
            $setParams.Add("NumberOfSubscriptionSyncsPerEwsSyncRun", $params.NumberOfSubscriptionSyncsPerEwsSyncRun)
        }
        
        if ($params.ContainsKey("NumberOfUsersEwsSyncWillProcessAtOnce"))
        {
            $setParams.Add("NumberOfUsersEwsSyncWillProcessAtOnce", $params.NumberOfUsersEwsSyncWillProcessAtOnce)
        }
        
        if ($params.ContainsKey("NumberOfUsersPerEwsSyncBatch"))
        {
            $setParams.Add("NumberOfUsersPerEwsSyncBatch", $params.NumberOfUsersPerEwsSyncBatch)
        }

        $setParams.Add("Name", $params.Name) 
        $setParams.Add("ApplicationPool", $params.ApplicationPool) 

        if ($setParams.ContainsKey("MinimumTimeBetweenEwsSyncSubscriptionSearches"))
        { 
            $setParams.MinimumTimeBetweenEwsSyncSubscriptionSearches = New-TimeSpan -Days $setParams.MinimumTimeBetweenEwsSyncSubscriptionSearches
        }
        if ($setParams.ContainsKey("MinimumTimeBetweenProviderRefreshes"))
        { 
            $setParams.MinimumTimeBetweenProviderRefreshes = New-TimeSpan -Days $setParams.MinimumTimeBetweenProviderRefreshes
        }
        if ($setParams.ContainsKey("MinimumTimeBetweenSearchQueries"))
        { 
            $setParams.MinimumTimeBetweenSearchQueries = New-TimeSpan -Days $setParams.MinimumTimeBetweenSearchQueries
        }
        $setParams.Add("Confirm", $false)
<<<<<<< HEAD
        $app =  Get-SPServiceApplication -Name $params.Name `
            | Where-Object { $_.TypeName -eq "Work Management Service Application"  }
=======
        $appService =  Get-SPServiceApplication -Name $params.Name `
                        | Where-Object -FilterScript {
                            $_.TypeName -eq "Work Management Service Application"
                          }
>>>>>>> refs/remotes/PowerShell/dev
          
        $app | Set-SPWorkManagementServiceApplication @setPArams | Out-Null
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ProxyName,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ApplicationPool,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumTimeBetweenEwsSyncSubscriptionSearches, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumTimeBetweenProviderRefreshes, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumTimeBetweenSearchQueries, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfSubscriptionSyncsPerEwsSyncRun, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfUsersEwsSyncWillProcessAtOnce, 
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfUsersPerEwsSyncBatch,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
    
    Write-Verbose -Message "Testing Work management service app '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present")
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("ApplicationPool",
                                                         "MinimumTimeBetweenEwsSyncSubscriptionSearches",
                                                         "MinimumTimeBetweenProviderRefreshes",
                                                         "MinimumTimeBetweenSearchQueries",
                                                         "Name",
                                                         "NumberOfSubscriptionSyncsPerEwsSyncRun",
                                                         "NumberOfUsersEwsSyncWillProcessAtOnce",
                                                         "NumberOfUsersPerEwsSyncBatch",
                                                         "Ensure")
    }
    else
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Ensure")
    }
}

Export-ModuleMember -Function *-TargetResource
