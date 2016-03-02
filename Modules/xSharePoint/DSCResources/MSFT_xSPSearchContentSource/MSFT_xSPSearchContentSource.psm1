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
                    Addresses = $source.StartAddresses.AbsoluteUri
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
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true) { throw "Parameter ContinuousCrawl is not valid for SharePoint content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for SharePoint content sources" }
        }
        "FileShare" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) { throw "Parameter LimitPageDepth is not valid for SharePoint content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for SharePoint content sources" }
            if ($CrawlSetting -eq "Custom") { throw "Parameter 'CrawlSetting' can only be set to custom for website content sources" }
        }
    }
    
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($ContentSourceType -ne $CurrentValues.ContentSourceType -and $Force -eq $false) {
        throw "The content type can not be changed from '$($CurrentValues.ContentSourceType)' to '$ContentSourceType' without deleting and adding it again. Specify 'Force = `$true' in order to allow DSC to do this, or manually remove the existing content source and re-run the configuration."
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
            $startAddresses = "$(params.Addresses)"
            
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
                StartAddresses = $startAddresses
                Confirm = $false
            }
            
            # Set the incremental search values
            if ($params.ContainsKey("IncrementalSchedule") -eq $true -or ($params.ContainsKey("ContinuousCrawl") -eq $true -and $params.ContinuousCrawl -eq $true)) {
                $incrementalSetArgs = @{
                    ScheduleType = "Incremental"
                    #TODO: YOURE UP TO HERE BRIAN! REMEMBER THIS IN THE MORNING! Build up the args for the first set, then rinse and repeat for the full crawl without the continuous flag
                }
                if ($params.ContainsKey("ContinuousCrawl") -eq $true -and $params.ContinuousCrawl -eq $true) {
                    $incrementalSetArgs.Add("EnableContinuousCrawls", $true)
                }
                if ($params.ContainsKey("IncrementalSchedule") -eq $true) {
                    switch ($params.IncrementalSchedule.ScheduleType) {
                        "None" {  }
                        "Daily" {  }
                        "Weekly" {  }
                        "Monthly" {  }
                    }
                }
            }
            
            # Set the full search values
            
            
        }
    }
    
    
    
    

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $CurrentValues, $PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]
        $ScriptRoot = $args[2]
        
        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.Search\xSPSearchContentSource.Schedules.psm1" -Resolve)
        
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
            if ($PSBoundParameters.ContainsKey("ContinuousCrawl") -eq $true) { throw "Parameter ContinuousCrawl is not valid for SharePoint content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for SharePoint content sources" }
        }
        "FileShare" {
            if ($PSBoundParameters.ContainsKey("LimitPageDepth") -eq $true) { throw "Parameter LimitPageDepth is not valid for SharePoint content sources" }
            if ($PSBoundParameters.ContainsKey("LimitServerHops") -eq $true) { throw "Parameter LimitServerHops is not valid for SharePoint content sources" }
            if ($CrawlSetting -eq "Custom") { throw "Parameter 'CrawlSetting' can only be set to custom for website content sources" }
        }
    }   
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.Search\xSPSearchContentSource.Schedules.psm1" -Resolve)
    
    if (($PSBoundParameters.Contains("IncrementalSchedule") -eq $true) -and ((Test-xSPSearchCrawlSchedule -CurrentSchedule $CurrentValues.IncrementalSchedule -DesiredSchedule $IncrementalSchedule) -eq $false)) {
        return $false;
    }
    if (($PSBoundParameters.ContainsKey("FullSchedule") -eq $true) -and ((Test-xSPSearchCrawlSchedule -CurrentSchedule $CurrentValues.FullSchedule -DesiredSchedule $FullSchedule) -eq $false)) {
        return $false;
    }
    
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues `
                                              -DesiredValues $PSBoundParameters `
                                              -ValuesToCheck @("ContentSourceType", "Addresses", "CrawlSetting", "ContinousCrawl", "Priority", "LimitPageDepth", "LimitServerHops", "Ensure")
}

Export-ModuleMember -Function *-TargetResource
