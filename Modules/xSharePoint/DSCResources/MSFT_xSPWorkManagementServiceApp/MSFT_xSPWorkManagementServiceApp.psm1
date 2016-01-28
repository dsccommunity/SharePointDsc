function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenEwsSyncSubscriptionSearches, 
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenProviderRefreshes, 
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenSearchQueries, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfSubscriptionSyncsPerEwsSyncRun, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfUsersEwsSyncWillProcessAtOnce, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfUsersPerEwsSyncBatch 
    )
    Write-Verbose -Message "Getting Work management service app '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue 
        if ($null -eq $serviceApps) { 
            return $null 
        }
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Work Management Service Application" }

        If ($null -eq $serviceApp) { 
            return $null 
        } else {
            $returnVal =  @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
            }
            return $returnVal
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenEwsSyncSubscriptionSearches, 
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenProviderRefreshes, 
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenSearchQueries, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfSubscriptionSyncsPerEwsSyncRun, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfUsersEwsSyncWillProcessAtOnce, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfUsersPerEwsSyncBatch 
    )

    $result = Get-TargetResource @PSBoundParameters
    $setParameters = @(
                    "ApplicationPool",
                    "MinimumTimeBetweenEwsSyncSubscriptionSearches",
                    "MinimumTimeBetweenProviderRefreshes",
                    "MinimumTimeBetweenSearchQueries",
                    "Name",
                    "NumberOfSubscriptionSyncsPerEwsSyncRun",
                    "NumberOfUsersEwsSyncWillProcessAtOnce",
                    "NumberOfUsersPerEwsSyncBatch"
              )
   $newParamters = @(
                    "ApplicationPool",
                    "Name" 
                    ) 
    if ($result -eq $null) { 
        Write-Verbose -Message "Creating work management Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments ($PSBoundParameters, $setParameters, $newParameters ) -ScriptBlock {
            $params = $args[0]
            $setParams = $params.GetEnumerator() | ? {$args[1] -contains $_.Name} 
            $newParams = $params.GetEnumerator() | ? {$args[2] -contains $_.Name}
            $appService = New-SPWorkManagementServiceApplication @newParams
            New-SPWorkManagementServiceApplicationProxy -Name "$($params.Name) Proxy" -DefaultProxyGroup -ServiceApplication $appService -ea Stop | Out-Null
            if ($setParams.ContainsKey("MinimumTimeBetweenEwsSyncSubscriptionSearches")) { 
                $setParams.MinimumTimeBetweenEwsSyncSubscriptionSearches = New-TimeSpan -Days $setParams.MinimumTimeBetweenEwsSyncSubscriptionSearches
            }
            if ($setParams.ContainsKey("MinimumTimeBetweenProviderRefreshes")) { 
                $setParams.MinimumTimeBetweenProviderRefreshes = New-TimeSpan -Days $setParams.MinimumTimeBetweenProviderRefreshes
            }
            if ($setParams.ContainsKey("MinimumTimeBetweenSearchQueries")) { 
                $setParams.MinimumTimeBetweenSearchQueries = New-TimeSpan -Days $setParams.MinimumTimeBetweenSearchQueries
            }
            $setParams.Add("Confirm", $false)
            Set-SPWorkManagementServiceApplicationProxy @setPArams | Out-Null
        }
         
        #}
    }else {
        if ($Ensure -eq  "Absent") {
            $appService =  Get-SPServiceApplication -Name $params.Name `
                | Where-Object { $_.TypeName -eq "Work Management Service Application"  }
            Remove-SPServiceApplication $appService 
        }else{
            Write-Verbose -Message "Updating Work management Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments ($PSBoundParameters, $setParameters ) -ScriptBlock {
                $params = $args[0]
                $setParams = $params.GetEnumerator() | ? {$args[1] -contains $_.Name} 
                #$appService =  Get-SPServiceApplication -Name $params.Name `
                #    | Where-Object { $_.TypeName -eq "Work Management Service Application"  }
                $setParams.Add("Confirm", $false)
                <#$appPool=$null
                if($setParams.ContainsKey("ApplicationPool")){
                    $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                    $setParams.ApplicationPool = $appPool
                }#>
                if ($setParams.ContainsKey("MinimumTimeBetweenEwsSyncSubscriptionSearches")) { 
                    $setParams.MinimumTimeBetweenEwsSyncSubscriptionSearches = New-TimeSpan -Days $setParams.MinimumTimeBetweenEwsSyncSubscriptionSearches
                }
                if ($setParams.ContainsKey("MinimumTimeBetweenProviderRefreshes")) { 
                    $setParams.MinimumTimeBetweenProviderRefreshes = New-TimeSpan -Days $setParams.MinimumTimeBetweenProviderRefreshes
                }
                if ($setParams.ContainsKey("MinimumTimeBetweenSearchQueries")) { 
                    $setParams.MinimumTimeBetweenSearchQueries = New-TimeSpan -Days $setParams.MinimumTimeBetweenSearchQueries
                }

                Set-SPWorkManagementServiceApplication @setPArams | Out-Null
            }
            <#
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                
                $appService =  Get-SPServiceApplication -Name $params.Name `
                    | Where-Object { $_.TypeName -eq "Work Management Service Application"  } 
                $AppService.ApplicationPool = $appPool
                $AppService.Update()
            }#>
        }
    }
}
#}
    


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenEwsSyncSubscriptionSearches, 
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenProviderRefreshes, 
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenSearchQueries, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfSubscriptionSyncsPerEwsSyncRun, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfUsersEwsSyncWillProcessAtOnce, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfUsersPerEwsSyncBatch 
    )
    
    Write-Verbose -Message "Testing for App management Service Application '$Name'"
    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ($null -eq $CurrentValues) { return $false 
    }else{
        if($Ensure -eq "Absent")
        { #Ensure = Absent doesn't care state
        return $true
        }
    }
    
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool")
}

Export-ModuleMember -Function *-TargetResource

