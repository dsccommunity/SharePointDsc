function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Name,
        [parameter(Mandatory = $true)]  [System.String]   $ServiceAppName,
        [parameter(Mandatory = $true)]  [ValidateSet("SharePoint","Website","FileShare")] [System.String] $ContentSourceType,
        [parameter(Mandatory = $true)]  [System.String[]] $Addresses,
        [parameter(Mandatory = $true)]  [ValidateSet("CrawlEverything","CrawlFirstOnly","Custom")] [System.String] $CrawlSetting,
        [parameter(Mandatory = $false)] [System.Boolean]  $ContinuousCrawl,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance] $IncrementalSchedule,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance] $FullSchedule,
        [parameter(Mandatory = $false)] [ValidateSet("Normal","High")] [System.String] $Priority,
        [parameter(Mandatory = $false)] [System.UInt32]   $LimitPageDepth,
        [parameter(Mandatory = $false)] [System.UInt32]   $LimitServerHops,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Boolean]  $Force,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
   
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.Search\xSPSearchContentSource.Schedules.psm1" -Resolve)
        
        $source = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $source) {
            return @{
                Name = $params.Name
                ServiceAppName = $params.ServiceAppName
                ContentSourceType = $params.ContentSourceType
                Ensure = "Absent"
            }
        }
        
        switch ($source.Type) {
            "SharePoint" {
                $crawlSetting = "CrawlEverything"
                if ($source.SharePointCrawlBehavior -eq "CrawlSites") { $crawlSetting = "CrawlFirstOnly" }
                $result = @{
                    Name = $params.Name
                    ServiceAppName = $params.ServiceAppName
                    Ensure = "Present"
                    ContentSourceType = "SharePoint"
                    Addresses = $source.StartAddresses.AbsoluteUri
                    CrawlSetting = $crawlSetting
                    ContinuousCrawl = $source.EnableContinuousCrawls
                    IncrementalSchedule = (Get-xSPSearchCrawlSchedule -Schedule $source.IncrementalCrawlSchedule)
                    FullSchedule = (Get-xSPSearchCrawlSchedule -Schedule $source.FullCrawlSchedule)
                    Priority = $source.CrawlPriority
                    InstallAccount = $params.InstallAccount
                }       
            }
            "Web" {
                $crawlSetting = "Custom"
                if ($source.MaxPageEnumerationDepth -eq [System.Int32]::MaxValue) { $crawlSetting = "CrawlEverything" }
                if ($source.MaxPageEnumerationDepth -eq 0) { $crawlSetting = "CrawlFirstOnly" }
                $result = @{
                    Name = $params.Name
                    ServiceAppName = $params.ServiceAppName
                    Ensure = "Present"
                    ContentSourceType = "Website"
                    Addresses = $source.StartAddresses.AbsoluteUri
                    CrawlSetting = $crawlSetting
                    IncrementalSchedule = (Get-xSPSearchCrawlSchedule -Schedule $source.IncrementalCrawlSchedule)
                    FullSchedule = (Get-xSPSearchCrawlSchedule -Schedule $source.FullCrawlSchedule)
                    LimitPageDepth = $source.MaxPageEnumerationDepth
                    LimitServerHops = $source.MaxSiteEnumerationDepth
                    Priority = $source.CrawlPriority
                }
            }
            "File" {
                $crawlSetting = "CrawlFirstOnly"
                if ($source.FollowDirectories -eq $true) { $crawlSetting = "CrawlEverything" }
                $result = @{
                    Name = $params.Name
                    ServiceAppName = $params.ServiceAppName
                    Ensure = "Present"
                    ContentSourceType = "FileShare"
                    Addresses = $source.StartAddresses.AbsoluteUri.Replace("file:///","\\").Replace("/", "\")
                    CrawlSetting = $crawlSetting
                    IncrementalSchedule = (Get-xSPSearchCrawlSchedule -Schedule $source.IncrementalCrawlSchedule)
                    FullSchedule = (Get-xSPSearchCrawlSchedule -Schedule $source.FullCrawlSchedule)
                    Priority = $source.CrawlPriority
                }
            }
            Default {
                throw "xSharePoint does not currently support '$($source.Type)' content sources. Please use only 'SharePoint', 'FileShare' or 'Website'."
            }
        }
        return $result     
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Name,
        [parameter(Mandatory = $true)]  [System.String]   $ServiceAppName,
        [parameter(Mandatory = $true)]  [ValidateSet("SharePoint","Website","FileShare")] [System.String] $ContentSourceType,
        [parameter(Mandatory = $true)]  [System.String[]] $Addresses,
        [parameter(Mandatory = $true)]  [ValidateSet("CrawlEverything","CrawlFirstOnly","Custom")] [System.String] $CrawlSetting,
        [parameter(Mandatory = $false)] [System.Boolean]  $ContinuousCrawl,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance] $IncrementalSchedule,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance] $FullSchedule,
        [parameter(Mandatory = $false)] [ValidateSet("Normal","High")] [System.String] $Priority,
        [parameter(Mandatory = $false)] [System.UInt32]   $LimitPageDepth,
        [parameter(Mandatory = $false)] [System.UInt32]   $LimitServerHops,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Boolean]  $Force,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    switch ($ContentSourceType) {
        "SharePoint" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) { throw "Parameter LimitPageDepth is not valid for SharePoint content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for SharePoint content sources" }
            if ($ContinuousCrawl -eq $true -and $PSBoundParameters.ContainsKey("IncrementalSchedule") -eq $true) { throw "You can not specify an incremental crawl schedule on a content source that will use continous crawl" }
            if ($CrawlSetting -eq "Custom") { throw "Parameter 'CrawlSetting' can only be set to custom for website content sources" }
        }
        "Website" {
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true) { throw "Parameter ContinuousCrawl is not valid for website content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for website content sources" }
        }
        "FileShare" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) { throw "Parameter LimitPageDepth is not valid for file share content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for file share content sources" }
            if ($CrawlSetting -eq "Custom") { throw "Parameter 'CrawlSetting' can only be set to custom for website content sources" }
        }
    }   
    
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($ContentSourceType -ne $CurrentValues.ContentSourceType -and $Force -eq $false) {
        throw "The type of the a search content source can not be changed from '$($CurrentValues.ContentSourceType)' to '$ContentSourceType' without deleting and adding it again. Specify 'Force = `$true' in order to allow DSC to do this, or manually remove the existing content source and re-run the configuration."
    }
    if (($ContentSourceType -ne $CurrentValues.ContentSourceType -and $Force -eq $true) -or ($Ensure -eq "Absent" -and $CurrentValues.Ensure -ne $Ensure)) {
        # Remove the existing content source
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters) -ScriptBlock {
            $params = $args[0]            
            Remove-SPEnterpriseSearchCrawlContentSource -Identity $params.Name -SearchApplication $params.ServiceAppName -Confirm:$false
        }    
    }
    
    if ($Ensure -eq "Present") {
        # Create the new content source and then apply settings to it
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters) -ScriptBlock {
            $params = $args[0]            
            
            $OFS = ","
            $startAddresses = "$($params.Addresses)"
            
            $source = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName -Identity $params.Name -ErrorAction SilentlyContinue
            if ($source -eq $null) {
                switch ($params.ContentSourceType) {
                    "SharePoint" { $newType = "SharePoint" }
                    "Website" { $newType = "Web" }
                    "FileShare" { $newType = "File" }
                }
                $source = New-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName -Type $newType -name $params.Name -StartAddresses $startAddresses    
            }
            
            $allSetArguments = @{
                Identity = $params.Name
                SearchApplication = $params.ServiceAppName
                Confirm = $false
            }
            
            if ($params.ContentSourceType -eq "SharePoint" -and $source.EnableContinuousCrawls -eq $true) {
                Set-SPEnterpriseSearchCrawlContentSource @allSetArguments -EnableContinuousCrawls $false
                Write-Verbose -Message "Pausing to allow Continuous Crawl to shut down correctly before continuing updating the configuration."
                Start-Sleep -Seconds 300
            }
            
            if ($source.CrawlStatus -ne "Idle") {
                Write-Verbose "Content source '$($params.Name)' is not idle, stopping current crawls to allow settings to be updated"
                $source = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName -Identity $params.Name
                $source.StopCrawl()
                $loopCount = 0
                
                $sourceToWait = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName -Identity $params.Name
                while ($sourceToWait.CrawlStatus -ne "Idle" -or $loopCount > 20) {
                    $sourceToWait = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName -Identity $params.Name
                    Write-Verbose -Message "Waiting for content source '$($params.Name)' to be idle."
                    Start-Sleep -Seconds 30
                    $loopCount++
                }
            }

            $primarySetArgs = @{
                StartAddresses = $startAddresses
            }
            if ($params.ContainsKey("ContinuousCrawl") -eq $true) {
                $primarySetArgs.Add("EnableContinuousCrawls", $params.ContinuousCrawl)
            }
            if ($params.ContainsKey("Priority") -eq $true) {
                switch ($params.Priority) {
                    "High" { $primarySetArgs.Add("CrawlPriority", "2") }
                    "Normal" { $primarySetArgs.Add("CrawlPriority", "1") }
                }
            }
            Set-SPEnterpriseSearchCrawlContentSource @allSetArguments @primarySetArgs            
            
            # Set the incremental search values
            if ($params.ContainsKey("IncrementalSchedule") -eq $true -and $params.IncrementalSchedule -ne $null) {
                $incrementalSetArgs = @{
                    ScheduleType = "Incremental"
                }
                switch ($params.IncrementalSchedule.ScheduleType) {
                    "None" { 
                        $incrementalSetArgs.Add("RemoveCrawlSchedule", $true)
                    }
                    "Daily" { 
                        $incrementalSetArgs.Add("DailyCrawlSchedule", $true)
                    }
                    "Weekly" { 
                        $incrementalSetArgs.Add("WeeklyCrawlSchedule", $true)
                        if ((Test-xSharePointObjectHasProperty -Object $params.IncrementalSchedule -PropertyName "CrawlScheduleDaysOfWeek") -eq $true) {
                            $OFS = ","
                            $incrementalSetArgs.Add("CrawlScheduleDaysOfWeek", [enum]::Parse([Microsoft.Office.Server.Search.Administration.DaysOfWeek], "$($params.IncrementalSchedule.CrawlScheduleDaysOfWeek)"))                            
                        }
                    }
                    "Monthly" { 
                        $incrementalSetArgs.Add("MonthlyCrawlSchedule", $true)
                        if ((Test-xSharePointObjectHasProperty -Object $params.IncrementalSchedule -PropertyName "CrawlScheduleDaysOfMonth") -eq $true) {
                            $incrementalSetArgs.Add("CrawlScheduleDaysOfMonth", $params.IncrementalSchedule.CrawlScheduleDaysOfMonth)
                        }
                        if ((Test-xSharePointObjectHasProperty -Object $params.IncrementalSchedule -PropertyName "CrawlScheduleMonthsOfYear") -eq $true) {
                            foreach ($month in $params.IncrementalSchedule.CrawlScheduleMonthsOfYear) {
                                $months += [Microsoft.Office.Server.Search.Administration.MonthsOfYear]::$month
                            }
                            $incrementalSetArgs.Add("CrawlScheduleMonthsOfYear", $months)
                        }
                    }
                }
                
                if ((Test-xSharePointObjectHasProperty -Object $params.IncrementalSchedule -PropertyName "CrawlScheduleRepeatDuration") -eq $true) {
                    $incrementalSetArgs.Add("CrawlScheduleRepeatDuration", $params.IncrementalSchedule.CrawlScheduleRepeatDuration)
                }
                if ((Test-xSharePointObjectHasProperty -Object $params.IncrementalSchedule -PropertyName "CrawlScheduleRepeatInterval") -eq $true) {
                    $incrementalSetArgs.Add("CrawlScheduleRepeatInterval", $params.IncrementalSchedule.CrawlScheduleRepeatInterval)
                }
                if ((Test-xSharePointObjectHasProperty -Object $params.IncrementalSchedule -PropertyName "CrawlScheduleRunEveryInterval") -eq $true) {
                    $incrementalSetArgs.Add("CrawlScheduleRunEveryInterval", $params.IncrementalSchedule.CrawlScheduleRunEveryInterval)
                }
                Set-SPEnterpriseSearchCrawlContentSource @allSetArguments @incrementalSetArgs
            }
            
            # Set the full search values
            if ($params.ContainsKey("FullSchedule") -eq $true) {
                $fullSetArgs = @{
                    ScheduleType = "Full"
                }
                switch ($params.FullSchedule.ScheduleType) {
                    "None" { 
                        $fullSetArgs.Add("RemoveCrawlSchedule", $true)
                    }
                    "Daily" { 
                        $fullSetArgs.Add("DailyCrawlSchedule", $true)
                    }
                    "Weekly" { 
                        $fullSetArgs.Add("WeeklyCrawlSchedule", $true)
                        if ((Test-xSharePointObjectHasProperty -Object $params.FullSchedule -PropertyName "CrawlScheduleDaysOfWeek") -eq $true) {
                            foreach ($day in $params.FullSchedule.CrawlScheduleDaysOfWeek) {
                                $daysOfweek += [Microsoft.Office.Server.Search.Administration.DaysOfWeek]::$day
                            }
                            $fullSetArgs.Add("CrawlScheduleDaysOfWeek", $daysOfweek)
                        }
                    }
                    "Monthly" { 
                        $fullSetArgs.Add("MonthlyCrawlSchedule", $true)
                        if ((Test-xSharePointObjectHasProperty -Object $params.FullSchedule -PropertyName "CrawlScheduleDaysOfMonth") -eq $true) {
                            $fullSetArgs.Add("CrawlScheduleDaysOfMonth", $params.FullSchedule.CrawlScheduleDaysOfMonth)
                        }
                        if ((Test-xSharePointObjectHasProperty -Object $params.FullSchedule -PropertyName "CrawlScheduleMonthsOfYear") -eq $true) {
                            foreach ($month in $params.FullSchedule.CrawlScheduleMonthsOfYear) {
                                $months += [Microsoft.Office.Server.Search.Administration.MonthsOfYear]::$month
                            }
                            $fullSetArgs.Add("CrawlScheduleMonthsOfYear", $months)
                        }
                    }
                }
                
                if ((Test-xSharePointObjectHasProperty -Object $params.FullSchedule -PropertyName "CrawlScheduleRepeatDuration") -eq $true) {
                    $fullSetArgs.Add("CrawlScheduleRepeatDuration", $params.FullSchedule.CrawlScheduleRepeatDuration)
                }
                if ((Test-xSharePointObjectHasProperty -Object $params.FullSchedule -PropertyName "CrawlScheduleRepeatInterval") -eq $true) {
                    $fullSetArgs.Add("CrawlScheduleRepeatInterval", $params.FullSchedule.CrawlScheduleRepeatInterval)
                }
                if ((Test-xSharePointObjectHasProperty -Object $params.FullSchedule -PropertyName "CrawlScheduleRunEveryInterval") -eq $true) {
                    $fullSetArgs.Add("CrawlScheduleRunEveryInterval", $params.FullSchedule.CrawlScheduleRunEveryInterval)
                }
                Set-SPEnterpriseSearchCrawlContentSource @allSetArguments @fullSetArgs
            }
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Name,
        [parameter(Mandatory = $true)]  [System.String]   $ServiceAppName,
        [parameter(Mandatory = $true)]  [ValidateSet("SharePoint","Website","FileShare")] [System.String] $ContentSourceType,
        [parameter(Mandatory = $true)]  [System.String[]] $Addresses,
        [parameter(Mandatory = $true)]  [ValidateSet("CrawlEverything","CrawlFirstOnly","Custom")] [System.String] $CrawlSetting,
        [parameter(Mandatory = $false)] [System.Boolean]  $ContinuousCrawl,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance] $IncrementalSchedule,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance] $FullSchedule,
        [parameter(Mandatory = $false)] [ValidateSet("Normal","High")] [System.String] $Priority,
        [parameter(Mandatory = $false)] [System.UInt32]   $LimitPageDepth,
        [parameter(Mandatory = $false)] [System.UInt32]   $LimitServerHops,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Boolean]  $Force,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
 
    switch ($ContentSourceType) {
        "SharePoint" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) { throw "Parameter LimitPageDepth is not valid for SharePoint content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for SharePoint content sources" }
            if ($ContinuousCrawl -eq $true -and $PSBoundParameters.ContainsKey("IncrementalSchedule") -eq $true) { throw "You can not specify an incremental crawl schedule on a content source that will use continous crawl" }
            if ($CrawlSetting -eq "Custom") { throw "Parameter 'CrawlSetting' can only be set to custom for website content sources" }
        }
        "Website" {
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true) { throw "Parameter ContinuousCrawl is not valid for website content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for website content sources" }
        }
        "FileShare" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) { throw "Parameter LimitPageDepth is not valid for file share content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for file share content sources" }
            if ($CrawlSetting -eq "Custom") { throw "Parameter 'CrawlSetting' can only be set to custom for website content sources" }
        }
    }   
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -eq "Absent") {
        return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues `
                                                  -DesiredValues $PSBoundParameters `
                                                  -ValuesToCheck @("Ensure")
    }
    
    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.Search\xSPSearchContentSource.Schedules.psm1" -Resolve)
    
    if (($PSBoundParameters.ContainsKey("IncrementalSchedule") -eq $true) -and ($IncrementalSchedule -ne $null) -and ((Test-xSPSearchCrawlSchedule -CurrentSchedule $CurrentValues.IncrementalSchedule -DesiredSchedule $IncrementalSchedule) -eq $false)) {
        return $false;
    }
    if (($PSBoundParameters.ContainsKey("FullSchedule") -eq $true) -and ($FullSchedule -ne $null) -and ((Test-xSPSearchCrawlSchedule -CurrentSchedule $CurrentValues.FullSchedule -DesiredSchedule $FullSchedule) -eq $false)) {
        return $false;
    }
    
    # Compare the addresses as Uri objects to handle things like trailing /'s on URLs
    $currentAddresses = @()
    foreach ($address in $CurrentValues.Addresses) { $currentAddresses += New-Object System.Uri -ArgumentList $address }
    $desiredAddresses = @()
    foreach ($address in $Addresses) { $desiredAddresses += New-Object System.Uri -ArgumentList $address }
    
    if ((Compare-Object -ReferenceObject $currentAddresses -DifferenceObject $desiredAddresses) -ne $null) {
        return $false
    }
    
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues `
                                              -DesiredValues $PSBoundParameters `
                                              -ValuesToCheck @("ContentSourceType", "CrawlSetting", "ContinousCrawl", "Priority", "LimitPageDepth", "LimitServerHops", "Ensure")
}

Export-ModuleMember -Function *-TargetResource
