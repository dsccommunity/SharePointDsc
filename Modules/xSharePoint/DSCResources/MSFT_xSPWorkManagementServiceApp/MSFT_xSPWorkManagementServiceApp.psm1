function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
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
                MinimumTimeBetweenEwsSyncSubscriptionSearches =  $serviceApp.AdminSettings.MinimumTimeBetweenEwsSyncSubscriptionSearches.TotalMinutes 
                MinimumTimeBetweenProviderRefreshes= $serviceApp.AdminSettings.MinimumTimeBetweenProviderRefreshes.TotalMinutes 
                MinimumTimeBetweenSearchQueries=  $serviceApp.AdminSettings.MinimumTimeBetweenProviderRefreshes.TotalMinutes 
                NumberOfSubscriptionSyncsPerEwsSyncRun=  $serviceApp.AdminSettings.NumberOfSubscriptionSyncsPerEwsSyncRun
                NumberOfUsersEwsSyncWillProcessAtOnce=  $serviceApp.AdminSettings.NumberOfUsersEwsSyncWillProcessAtOnce
                NumberOfUsersPerEwsSyncBatch=  $serviceApp.AdminSettings.NumberOfUsersPerEwsSyncBatch
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
        [parameter(Mandatory = $false)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenEwsSyncSubscriptionSearches, 
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenProviderRefreshes, 
        [parameter(Mandatory = $false)] [System.UInt32] $MinimumTimeBetweenSearchQueries, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfSubscriptionSyncsPerEwsSyncRun, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfUsersEwsSyncWillProcessAtOnce, 
        [parameter(Mandatory = $false)] [System.UInt32] $NumberOfUsersPerEwsSyncBatch 
    )
    if($Ensure -ne "Absent" -and $ApplicationPool -eq $null){
        throw "Parameter ApplicationPool is required unless service is being removed(Ensure='Absent')"
    }
    <#
    if ($Ensure -eq  "Absent") {
        if($result -ne $null){
            Write-Verbose -Message "Removing Work management Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters  -ScriptBlock {
            $params = $args[0]
            }
        }
    }#>
    Write-Verbose -Message "Creating work management Service Application $Name"
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $appService =  Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue `
        | Where-Object { $_.TypeName -eq "Work Management Service Application"  }

        if($appService -ne $null -and $params.ContainsKey("Ensure") -and $params.Ensure -eq "Absent")
        {
            #remove existing app
            
            Remove-SPServiceApplication $appService 
            return;
        } elseif ( $appService -eq $null){
            $newParams = @{}
            $newParams.Add("Name", $params.Name) 
            $newParams.Add("ApplicationPool", $params.ApplicationPool) 

            $appService = New-SPWorkManagementServiceApplication @newParams
            New-SPWorkManagementServiceApplicationProxy -Name "$($params.Name) Proxy" -DefaultProxyGroup -ServiceApplication $appService | Out-Null
            Sleep -Milliseconds 200
        }
        $setParams = @{}
        if ($params.ContainsKey("MinimumTimeBetweenEwsSyncSubscriptionSearches")) { $setParams.Add("MinimumTimeBetweenEwsSyncSubscriptionSearches", $params.MinimumTimeBetweenEwsSyncSubscriptionSearches) }
        if ($params.ContainsKey("MinimumTimeBetweenProviderRefreshes")) { $setParams.Add("MinimumTimeBetweenProviderRefreshes", $params.MinimumTimeBetweenProviderRefreshes) }
        if ($params.ContainsKey("MinimumTimeBetweenSearchQueries")) { $setParams.Add("MinimumTimeBetweenSearchQueries", $params.MinimumTimeBetweenSearchQueries) }
        if ($params.ContainsKey("NumberOfSubscriptionSyncsPerEwsSyncRun")) { $setParams.Add("NumberOfSubscriptionSyncsPerEwsSyncRun", $params.NumberOfSubscriptionSyncsPerEwsSyncRun) }
        if ($params.ContainsKey("NumberOfUsersEwsSyncWillProcessAtOnce")) { $setParams.Add("NumberOfUsersEwsSyncWillProcessAtOnce", $params.NumberOfUsersEwsSyncWillProcessAtOnce) }
        if ($params.ContainsKey("NumberOfUsersPerEwsSyncBatch")) { $setParams.Add("NumberOfUsersPerEwsSyncBatch", $params.NumberOfUsersPerEwsSyncBatch) }

        $setParams.Add("Name", $params.Name) 
        $setParams.Add("ApplicationPool", $params.ApplicationPool) 

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
        $appService =  Get-SPServiceApplication -Name $params.Name `
            | Where-Object { $_.TypeName -eq "Work Management Service Application"  }
          
        $appService | Set-SPWorkManagementServiceApplication @setPArams | Out-Null
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
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
    
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool",
                                                                                                                                "MinimumTimeBetweenEwsSyncSubscriptionSearches",
                                                                                                                                "MinimumTimeBetweenProviderRefreshes",
                                                                                                                                "MinimumTimeBetweenSearchQueries",
                                                                                                                                "Name",
                                                                                                                                "NumberOfSubscriptionSyncsPerEwsSyncRun",
                                                                                                                                "NumberOfUsersEwsSyncWillProcessAtOnce",
                                                                                                                                "NumberOfUsersPerEwsSyncBatch"
                                                                                                                               )
}

Export-ModuleMember -Function *-TargetResource
