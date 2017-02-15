function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]  
        [System.String]
        $ServiceAppName,

        [parameter(Mandatory = $true)]
        [ValidateSet("SharePoint","Website","FileShare")]
        [System.String]
        $ContentSourceType,
        
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Addresses,
        
        [parameter(Mandatory = $true)]
        [ValidateSet("CrawlEverything","CrawlFirstOnly","Custom")]
        [System.String] 
        $CrawlSetting,
        
        [parameter(Mandatory = $false)] 
        [System.Boolean]
        $ContinuousCrawl,
        
        [parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $IncrementalSchedule,
        
        [parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $FullSchedule,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Normal","High")] 
        [System.String] 
        $Priority,

        [parameter(Mandatory = $false)] 
        [System.UInt32]
        $LimitPageDepth,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $LimitServerHops,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String] 
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Force,
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
   
    Write-Verbose -Message "Getting Content Source Setting for '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters, $PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        $relativePath = "..\..\Modules\SharePointDsc.Search\SPSearchContentSource.Schedules.psm1"
        $modulePath = Join-Path -Path $ScriptRoot `
                                -ChildPath $relativePath `
                                -Resolve
        Import-Module -Name $modulePath
        
        $source = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $params.ServiceAppName `
                                                           -Identity $params.Name `
                                                           -ErrorAction SilentlyContinue
        if ($null -eq $source) 
        {
            return @{
                Name = $params.Name
                ServiceAppName = $params.ServiceAppName
                ContentSourceType = $params.ContentSourceType
                Ensure = "Absent"
            }
        }
        
        switch ($source.Type) 
        {
            "SharePoint" {
                $crawlSetting = "CrawlEverything"
                if ($source.SharePointCrawlBehavior -eq "CrawlSites") 
                { 
                    $crawlSetting = "CrawlFirstOnly" 
                }
                
                $incrementalSchedule = Get-SPDSCSearchCrawlSchedule `
                                            -Schedule $source.IncrementalCrawlSchedule
                $fullSchedule = Get-SPDSCSearchCrawlSchedule `
                                            -Schedule $source.FullCrawlSchedule
                
                $result = @{
                    Name = $params.Name
                    ServiceAppName = $params.ServiceAppName
                    Ensure = "Present"
                    ContentSourceType = "SharePoint"
                    Addresses = $source.StartAddresses.AbsoluteUri
                    CrawlSetting = $crawlSetting
                    ContinuousCrawl = $source.EnableContinuousCrawls
                    IncrementalSchedule = $incrementalSchedule
                    FullSchedule = $fullSchedule
                    Priority = $source.CrawlPriority
                    InstallAccount = $params.InstallAccount
                }       
            }
            "Web" {
                $crawlSetting = "Custom"
                if ($source.MaxPageEnumerationDepth -eq [System.Int32]::MaxValue) 
                { 
                    $crawlSetting = "CrawlEverything" 
                }
                if ($source.MaxPageEnumerationDepth -eq 0) 
                { 
                    $crawlSetting = "CrawlFirstOnly" 
                }

                $incrementalSchedule = Get-SPDSCSearchCrawlSchedule `
                                            -Schedule $source.IncrementalCrawlSchedule
                $fullSchedule = Get-SPDSCSearchCrawlSchedule `
                                            -Schedule $source.FullCrawlSchedule

                $result = @{
                    Name = $params.Name
                    ServiceAppName = $params.ServiceAppName
                    Ensure = "Present"
                    ContentSourceType = "Website"
                    Addresses = $source.StartAddresses.AbsoluteUri
                    CrawlSetting = $crawlSetting
                    IncrementalSchedule = $incrementalSchedule
                    FullSchedule = $fullSchedule
                    LimitPageDepth = $source.MaxPageEnumerationDepth
                    LimitServerHops = $source.MaxSiteEnumerationDepth
                    Priority = $source.CrawlPriority
                }
            }
            "File" {
                $crawlSetting = "CrawlFirstOnly"
                if ($source.FollowDirectories -eq $true) 
                { 
                    $crawlSetting = "CrawlEverything" 
                }
                
                $addresses = $source.StartAddresses.AbsoluteUri
                $addresses = $addresses.Replace("file:///","\\").Replace("/", "\")

                $incrementalSchedule = Get-SPDSCSearchCrawlSchedule `
                                            -Schedule $source.IncrementalCrawlSchedule
                $fullSchedule = Get-SPDSCSearchCrawlSchedule `
                                            -Schedule $source.FullCrawlSchedule

                $result = @{
                    Name = $params.Name
                    ServiceAppName = $params.ServiceAppName
                    Ensure = "Present"
                    ContentSourceType = "FileShare"
                    Addresses = $addresses
                    CrawlSetting = $crawlSetting
                    IncrementalSchedule = $incrementalSchedule
                    FullSchedule = $fullSchedule
                    Priority = $source.CrawlPriority
                }
            }
            Default {
                throw ("SharePointDsc does not currently support '$($source.Type)' content " + `
                       "sources. Please use only 'SharePoint', 'FileShare' or 'Website'.")
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
        [parameter(Mandatory = $true)]  
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]  
        [System.String]
        $ServiceAppName,

        [parameter(Mandatory = $true)]
        [ValidateSet("SharePoint","Website","FileShare")]
        [System.String]
        $ContentSourceType,
        
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Addresses,
        
        [parameter(Mandatory = $true)]
        [ValidateSet("CrawlEverything","CrawlFirstOnly","Custom")]
        [System.String] 
        $CrawlSetting,
        
        [parameter(Mandatory = $false)] 
        [System.Boolean]
        $ContinuousCrawl,
        
        [parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $IncrementalSchedule,
        
        [parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $FullSchedule,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Normal","High")] 
        [System.String] 
        $Priority,

        [parameter(Mandatory = $false)] 
        [System.UInt32]
        $LimitPageDepth,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $LimitServerHops,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String] 
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Force,
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Content Source Setting for '$Name'"

    switch ($ContentSourceType)
    {
        "SharePoint" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) 
            { 
                throw "Parameter LimitPageDepth is not valid for SharePoint content sources" 
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) 
            { 
                throw "Parameter LimitServerHops is not valid for SharePoint content sources" 
            }
            if ($ContinuousCrawl -eq $true -and `
                $PSBoundParameters.ContainsKey("IncrementalSchedule") -eq $true) 
            { 
                throw ("You can not specify an incremental crawl schedule on a content source " + `
                       "that will use continous crawl") 
            }
            if ($CrawlSetting -eq "Custom") 
            { 
                throw ("Parameter 'CrawlSetting' can only be set to custom for website content " + `
                       "sources") 
            }
        }
        "Website" {
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true) 
            { 
                throw "Parameter ContinuousCrawl is not valid for website content sources" 
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) 
            { 
                throw "Parameter LimitServerHops is not valid for website content sources" 
            }
        }
        "FileShare" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) 
            { 
                throw "Parameter LimitPageDepth is not valid for file share content sources" 
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) 
            { 
                throw "Parameter LimitServerHops is not valid for file share content sources" 
            }
            if ($CrawlSetting -eq "Custom") 
            { 
                throw "Parameter 'CrawlSetting' can only be set to custom for website content sources" 
            }
        }
    }   
    
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($ContentSourceType -ne $CurrentValues.ContentSourceType -and $Force -eq $false) 
    {
        throw ("The type of the a search content source can not be changed from " + `
               "'$($CurrentValues.ContentSourceType)' to '$ContentSourceType' without " + `
               "deleting and adding it again. Specify 'Force = `$true' in order to allow " + `
               "DSC to do this, or manually remove the existing content source and re-run " + `
               "the configuration.")
    }

    if (($ContentSourceType -ne $CurrentValues.ContentSourceType -and $Force -eq $true) `
       -or ($Ensure -eq "Absent" -and $CurrentValues.Ensure -ne $Ensure)) 
    {
        # Remove the existing content source
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments @($PSBoundParameters) `
                            -ScriptBlock {
            $params = $args[0]            
            Remove-SPEnterpriseSearchCrawlContentSource -Identity $params.Name `
                                                        -SearchApplication $params.ServiceAppName `
                                                        -Confirm:$false
        }    
    }
    
    if ($Ensure -eq "Present") 
    {
        # Create the new content source and then apply settings to it
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments @($PSBoundParameters) `
                            -ScriptBlock {
            $params = $args[0]            
            
            $OFS = ","
            $startAddresses = "$($params.Addresses)"
            
            $source = Get-SPEnterpriseSearchCrawlContentSource `
                            -SearchApplication $params.ServiceAppName `
                            -Identity $params.Name `
                            -ErrorAction SilentlyContinue

            if ($null -eq $source) 
            {
                switch ($params.ContentSourceType) {
                    "SharePoint" { 
                        $newType = "SharePoint" 
                    }
                    "Website" { 
                        $newType = "Web"
                    }
                    "FileShare" { 
                        $newType = "File" 
                    }
                }
                $source = New-SPEnterpriseSearchCrawlContentSource `
                                -SearchApplication $params.ServiceAppName `
                                -Type $newType `
                                -Name $params.Name `
                                -StartAddresses $startAddresses    
            }
            
            $allSetArguments = @{
                Identity = $params.Name
                SearchApplication = $params.ServiceAppName
                Confirm = $false
            }
            
            if ($params.ContentSourceType -eq "SharePoint" -and `
                $source.EnableContinuousCrawls -eq $true) 
            {
                Set-SPEnterpriseSearchCrawlContentSource @allSetArguments `
                                                        -EnableContinuousCrawls $false
                Write-Verbose -Message ("Pausing to allow Continuous Crawl to shut down " + `
                                        "correctly before continuing updating the configuration.")
                Start-Sleep -Seconds 300
            }
            
            if ($source.CrawlStatus -ne "Idle") 
            {
                Write-Verbose -Message ("Content source '$($params.Name)' is not idle, " + `
                                        "stopping current crawls to allow settings to be updated")
                
                $source = Get-SPEnterpriseSearchCrawlContentSource `
                                -SearchApplication $params.ServiceAppName `
                                -Identity $params.Name
                
                $source.StopCrawl()
                $loopCount = 0
                
                $sourceToWait = Get-SPEnterpriseSearchCrawlContentSource `
                                    -SearchApplication $params.ServiceAppName `
                                    -Identity $params.Name

                while ($sourceToWait.CrawlStatus -ne "Idle" -or $loopCount > 15) 
                {
                    $sourceToWait = Get-SPEnterpriseSearchCrawlContentSource `
                                        -SearchApplication $params.ServiceAppName `
                                        -Identity $params.Name

                    Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting " + `
                                            "for content source '$($params.Name)' to be idle " + `
                                            "(waited $loopCount of 15 minutes)")
                    Start-Sleep -Seconds 60
                    $loopCount++
                }
            }

            $primarySetArgs = @{
                StartAddresses = $startAddresses
            }
            
            if ($params.ContainsKey("ContinuousCrawl") -eq $true) 
            {
                $primarySetArgs.Add("EnableContinuousCrawls", $params.ContinuousCrawl)
            }

            if ($params.ContainsKey("Priority") -eq $true) 
            {
                switch ($params.Priority) 
                {
                    "High" { 
                        $primarySetArgs.Add("CrawlPriority", "2") 
                    }
                    "Normal" { 
                        $primarySetArgs.Add("CrawlPriority", "1") 
                    }
                }
            }

            Set-SPEnterpriseSearchCrawlContentSource @allSetArguments @primarySetArgs            
            
            # Set the incremental search values
            if ($params.ContainsKey("IncrementalSchedule") -eq $true -and `
                $null -ne $params.IncrementalSchedule) 
            {
                $incrementalSetArgs = @{
                    ScheduleType = "Incremental"
                }
                switch ($params.IncrementalSchedule.ScheduleType) 
                {
                    "None" { 
                        $incrementalSetArgs.Add("RemoveCrawlSchedule", $true)
                    }
                    "Daily" { 
                        $incrementalSetArgs.Add("DailyCrawlSchedule", $true)
                    }
                    "Weekly" { 
                        $incrementalSetArgs.Add("WeeklyCrawlSchedule", $true)
                        $propertyTest = Test-SPDSCObjectHasProperty `
                                            -Object $params.IncrementalSchedule `
                                            -PropertyName "CrawlScheduleDaysOfWeek"
                        
                        if ($propertyTest -eq $true) 
                        {
                            $OFS = ","
                            $enumValue = `
                                [enum]::Parse([Microsoft.Office.Server.Search.Administration.DaysOfWeek], `
                                "$($params.IncrementalSchedule.CrawlScheduleDaysOfWeek)")
                            
                            $incrementalSetArgs.Add("CrawlScheduleDaysOfWeek", $enumValue)                            
                        }
                    }
                    "Monthly" { 
                        $incrementalSetArgs.Add("MonthlyCrawlSchedule", $true)
                        $propertyTest = Test-SPDSCObjectHasProperty `
                                            -Object $params.IncrementalSchedule `
                                            -PropertyName "CrawlScheduleDaysOfMonth"

                        if ($propertyTest -eq $true) 
                        {
                            $incrementalSetArgs.Add("CrawlScheduleDaysOfMonth", `
                                $params.IncrementalSchedule.CrawlScheduleDaysOfMonth)
                        }

                        $propertyTest = Test-SPDSCObjectHasProperty `
                                            -Object $params.IncrementalSchedule `
                                            -PropertyName "CrawlScheduleMonthsOfYear"

                        if ($propertyTest -eq $true) 
                        {
                            foreach ($month in $params.IncrementalSchedule.CrawlScheduleMonthsOfYear) {
                                $months += [Microsoft.Office.Server.Search.Administration.MonthsOfYear]::$month
                            }
                            $incrementalSetArgs.Add("CrawlScheduleMonthsOfYear", $months)
                        }
                    }
                }
                
                $propertyTest = Test-SPDSCObjectHasProperty -Object $params.IncrementalSchedule `
                                                            -PropertyName "CrawlScheduleRepeatDuration"
                if ($propertyTest -eq $true) 
                {
                    $incrementalSetArgs.Add("CrawlScheduleRepeatDuration", 
                        $params.IncrementalSchedule.CrawlScheduleRepeatDuration)
                }

                $propertyTest = Test-SPDSCObjectHasProperty -Object $params.IncrementalSchedule `
                                                            -PropertyName "CrawlScheduleRepeatInterval"
                if ($propertyTest -eq $true) 
                {
                    $incrementalSetArgs.Add("CrawlScheduleRepeatInterval", 
                        $params.IncrementalSchedule.CrawlScheduleRepeatInterval)
                }

                $propertyTest = Test-SPDSCObjectHasProperty -Object $params.IncrementalSchedule `
                                                            -PropertyName "CrawlScheduleRunEveryInterval"
                if ($propertyTest -eq $true) {
                    $incrementalSetArgs.Add("CrawlScheduleRunEveryInterval", 
                        $params.IncrementalSchedule.CrawlScheduleRunEveryInterval)
                }
                Set-SPEnterpriseSearchCrawlContentSource @allSetArguments @incrementalSetArgs
            }
            
            # Set the full search values
            if ($params.ContainsKey("FullSchedule") -eq $true) 
            {
                $fullSetArgs = @{
                    ScheduleType = "Full"
                }
                switch ($params.FullSchedule.ScheduleType) 
                {
                    "None" { 
                        $fullSetArgs.Add("RemoveCrawlSchedule", $true)
                    }
                    "Daily" { 
                        $fullSetArgs.Add("DailyCrawlSchedule", $true)
                    }
                    "Weekly" { 
                        $fullSetArgs.Add("WeeklyCrawlSchedule", $true)
                        $propertyTest = Test-SPDSCObjectHasProperty -Object $params.FullSchedule `
                                                                    -PropertyName "CrawlScheduleDaysOfWeek"
                        if ($propertyTest -eq $true) 
                        {
                            foreach ($day in $params.FullSchedule.CrawlScheduleDaysOfWeek) {
                                $daysOfweek += [Microsoft.Office.Server.Search.Administration.DaysOfWeek]::$day
                            }
                            $fullSetArgs.Add("CrawlScheduleDaysOfWeek", $daysOfweek)
                        }
                    }
                    "Monthly" { 
                        $fullSetArgs.Add("MonthlyCrawlSchedule", $true)
                        $propertyTest = Test-SPDSCObjectHasProperty -Object $params.FullSchedule `
                                                                    -PropertyName "CrawlScheduleDaysOfMonth"
                        if ($propertyTest -eq $true) 
                        {
                            $fullSetArgs.Add("CrawlScheduleDaysOfMonth", 
                                $params.FullSchedule.CrawlScheduleDaysOfMonth)
                        }

                        $propertyTest = Test-SPDSCObjectHasProperty -Object $params.FullSchedule `
                                                                    -PropertyName "CrawlScheduleMonthsOfYear"
                        if ($propertyTest -eq $true) 
                        {
                            foreach ($month in $params.FullSchedule.CrawlScheduleMonthsOfYear) {
                                $months += [Microsoft.Office.Server.Search.Administration.MonthsOfYear]::$month
                            }
                            $fullSetArgs.Add("CrawlScheduleMonthsOfYear", $months)
                        }
                    }
                }
                
                $propertyTest = Test-SPDSCObjectHasProperty -Object $params.FullSchedule `
                                                            -PropertyName "CrawlScheduleRepeatDuration"
                if ($propertyTest -eq $true) 
                {
                    $fullSetArgs.Add("CrawlScheduleRepeatDuration", 
                        $params.FullSchedule.CrawlScheduleRepeatDuration)
                }

                $propertyTest = Test-SPDSCObjectHasProperty -Object $params.FullSchedule `
                                                            -PropertyName "CrawlScheduleRepeatInterval"
                if ($propertyTest -eq $true) 
                {
                    $fullSetArgs.Add("CrawlScheduleRepeatInterval", 
                        $params.FullSchedule.CrawlScheduleRepeatInterval)
                }

                $propertyTest = Test-SPDSCObjectHasProperty -Object $params.FullSchedule `
                                                            -PropertyName "CrawlScheduleRunEveryInterval"
                if ($propertyTest -eq $true) 
                {
                    $fullSetArgs.Add("CrawlScheduleRunEveryInterval", 
                        $params.FullSchedule.CrawlScheduleRunEveryInterval)
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
        [parameter(Mandatory = $true)]  
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]  
        [System.String]
        $ServiceAppName,

        [parameter(Mandatory = $true)]
        [ValidateSet("SharePoint","Website","FileShare")]
        [System.String]
        $ContentSourceType,
        
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Addresses,
        
        [parameter(Mandatory = $true)]
        [ValidateSet("CrawlEverything","CrawlFirstOnly","Custom")]
        [System.String] 
        $CrawlSetting,
        
        [parameter(Mandatory = $false)] 
        [System.Boolean]
        $ContinuousCrawl,
        
        [parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $IncrementalSchedule,
        
        [parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $FullSchedule,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Normal","High")] 
        [System.String] 
        $Priority,

        [parameter(Mandatory = $false)] 
        [System.UInt32]
        $LimitPageDepth,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $LimitServerHops,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String] 
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Force,
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
 
    Write-Verbose -Message "Testing Content Source Setting for '$Name'"

    $PSBoundParameters.Ensure = $Ensure
    
    switch ($ContentSourceType)
    {
        "SharePoint" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) 
            { 
                throw "Parameter LimitPageDepth is not valid for SharePoint content sources" 
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) 
            { 
                throw "Parameter LimitServerHops is not valid for SharePoint content sources" 
            }
            if ($ContinuousCrawl -eq $true -and `
                $PSBoundParameters.ContainsKey("IncrementalSchedule") -eq $true) 
            { 
                throw ("You can not specify an incremental crawl schedule on a content source " + `
                       "that will use continous crawl") 
            }
            if ($CrawlSetting -eq "Custom") 
            { 
                throw ("Parameter 'CrawlSetting' can only be set to custom for website content " + `
                       "sources") 
            }
        }
        "Website" {
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true) 
            { 
                throw "Parameter ContinuousCrawl is not valid for website content sources" 
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) 
            { 
                throw "Parameter LimitServerHops is not valid for website content sources" 
            }
        }
        "FileShare" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) 
            { 
                throw "Parameter LimitPageDepth is not valid for file share content sources" 
            }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) 
            { 
                throw "Parameter LimitServerHops is not valid for file share content sources" 
            }
            if ($CrawlSetting -eq "Custom") 
            { 
                throw "Parameter 'CrawlSetting' can only be set to custom for website content sources" 
            }
        }
    } 
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -eq "Absent" -or $CurrentValues.Ensure -eq "Absent") 
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Ensure")
    }
    
    $relativePath = "..\..\Modules\SharePointDsc.Search\SPSearchContentSource.Schedules.psm1"
    $modulePath = Join-Path -Path $PSScriptRoot `
                            -ChildPath $relativePath `
                            -Resolve
    Import-Module -Name $modulePath
                                                  
    if (($PSBoundParameters.ContainsKey("IncrementalSchedule") -eq $true) -and ($null -ne $IncrementalSchedule)) 
    {
        $propertyTest = Test-SPDSCSearchCrawlSchedule -CurrentSchedule $CurrentValues.IncrementalSchedule `
                                                      -DesiredSchedule $IncrementalSchedule
        if ($propertyTest -eq $false)
        {
            return $false
        }
    }
    
    if (($PSBoundParameters.ContainsKey("FullSchedule") -eq $true) -and ($null -ne $FullSchedule))
    {
        $propertyTest = Test-SPDSCSearchCrawlSchedule -CurrentSchedule $CurrentValues.FullSchedule `
                                                      -DesiredSchedule $FullSchedule
        if ($propertyTest -eq $false)
        {
            return $false
        }
    }
    
    # Compare the addresses as Uri objects to handle things like trailing /'s on URLs
    $currentAddresses = @()
    foreach ($address in $CurrentValues.Addresses) 
    { 
        $currentAddresses += New-Object -TypeName System.Uri -ArgumentList $address 
    }
    $desiredAddresses = @()
    foreach ($address in $Addresses) 
    { 
        $desiredAddresses += New-Object -TypeName System.Uri -ArgumentList $address 
    }
    
    if ($null -ne (Compare-Object -ReferenceObject $currentAddresses `
                                  -DifferenceObject $desiredAddresses)) 
    {
        return $false
    }
    
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("ContentSourceType", 
                                                         "CrawlSetting", 
                                                         "ContinousCrawl", 
                                                         "Priority", 
                                                         "LimitPageDepth", 
                                                         "LimitServerHops", 
                                                         "Ensure")
}

Export-ModuleMember -Function *-TargetResource
