function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $false)]    
        [System.String[]]
        $Url,

        [parameter(Mandatory = $false)]
        [ValidateSet('Present','Absent')] 
        [System.String]
        $Ensure = 'Present',
      
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IncludeCentralAdmin = $true,

        [parameter(Mandatory = $false)]
        [ValidateSet('mon','tue','wed','thu','fri','sat','sun')]
        [System.String[]]
        $WarmUpDays,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $WarmUpTime = '6:00am to 7:00am',
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message 'WarmUp - Getting all SPSite'

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        if ($null -eq $params.WarmUpDays)
        {
            Write-Verbose -Message "No WarmUpDays specified, WarmUp can be ran on any day."
            $warmUpDaysResult = @('mon','tue','wed','thu','fri','sat','sun')
        }
        else
        {
            $warmUpDaysResult = $params.WarmUpDays     
        }

        $spSiteUrl = Get-SPDscAllSPSite -IncludeCentralAdmin $params.IncludeCentralAdmin
        if ($spSiteUrl) 
        { 
            $ensureResult = 'Present'
        } 
        else 
        { 
            $ensureResult = 'Absent'
        }
        
        return @{
            Url                 = $spSiteUrl
            Ensure              = $ensureResult
            IncludeCentralAdmin = $params.IncludeCentralAdmin
            WarmUpDays          = $warmUpDaysResult
            WarmUpTime          = $params.WarmUpTime
        }
    }

    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $false)]    
        [System.String[]]
        $Url,

        [parameter(Mandatory = $false)]
        [ValidateSet('Present','Absent')] 
        [System.String]
        $Ensure = 'Present',
      
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IncludeCentralAdmin = $true,

        [parameter(Mandatory = $false)]
        [ValidateSet('mon','tue','wed','thu','fri','sat','sun')]
        [System.String[]]
        $WarmUpDays,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $WarmUpTime = '6:00am to 7:00am',
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message 'WarmUp - Setting'    
    $PSBoundParameters.Ensure = $Ensure
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $false)]    
        [System.String[]]
        $Url,

        [parameter(Mandatory = $false)]
        [ValidateSet('Present','Absent')] 
        [System.String]
        $Ensure = 'Present',
      
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IncludeCentralAdmin,

        [parameter(Mandatory = $false)]
        [ValidateSet('mon','tue','wed','thu','fri','sat','sun')]
        [System.String[]]
        $WarmUpDays,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $WarmUpTime = '6:00am to 7:00am',
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message 'WarmUp - Testing all SPSite'
    $PSBoundParameters.Ensure = $Ensure
    if ($Ensure -eq "Absent")
    {
        throw [Exception] "WarmUp - Only Ensure equal Present is supported"
        return
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $now = Get-Date
    if ($WarmUpDays)
    {
        # WarmUpDays parameter exists, check if current day is specified
        $currentDayOfWeek = $now.DayOfWeek.ToString().ToLower().Substring(0,3)

        if ($WarmUpDays -contains $currentDayOfWeek)
        {
            Write-Verbose -Message ("Current day is present in the parameter WarmUpDays. " + `
                                    "WarmUp can be run today.")
        }
        else
        {
            Write-Verbose -Message ("Current day is not present in the parameter WarmUpDays, " + `
                                    "skipping the WarmUp")
            return
        }
    }
    else
    {
        Write-Verbose -Message "No WarmUpDays specified, WarmUp can be ran on any day."
    }

    # Check if WarmUpTime parameter exists
    if ($WarmUpTime)
    {
        # Check if current time is inside of time window
        $upgradeTimes = $WarmUpTime.Split(" ")
        $starttime = 0
        $endtime = 0

        if ($upgradeTimes.Count -ne 3)
        {
            throw "Time window incorrectly formatted."
        }
        else
        {
            if ([datetime]::TryParse($upgradeTimes[0],[ref]$starttime) -ne $true)
            {
                throw "Error converting start time"
            }

            if ([datetime]::TryParse($upgradeTimes[2],[ref]$endtime) -ne $true)
            {
                throw "Error converting end time"
            }

            if ($starttime -gt $endtime)
            {
                throw 'Error: Start time cannot be larger than end time'
            }
        }

        if (($starttime -lt $now) -and ($endtime -gt $now))
        {
            Write-Verbose -Message ("Current time is inside of the window specified in " + `
                                    "WarmUpTime. Starting WarmUp")
        }
        else
        {
            Write-Verbose -Message ("Current time is outside of the window specified in " + `
                                    "WarmUpTime, skipping the WarmUp")
            return
        }
    }
    else
    {
        Write-Verbose -Message ("No WarmUpTime specified, WarmUp can be ran at " + `
                                "any time. Starting WarmUp.")
    }
    
    try
    {
        Write-Verbose -Message 'WarmUp SPSite In Progress'
        $warmUpResult = @()
        $spSites = $CurrentValues.Url
        foreach ($spSite in $spSites)
        {
            $invokeSPSite = Invoke-WebRequest -Uri $spSite -UseDefaultCredentials -TimeoutSec 80
            $invokeResult = New-Object System.Object
            $invokeResult | Add-Member -MemberType NoteProperty -Name Url -Value $spSite
		    $invokeResult | Add-Member -MemberType NoteProperty -Name Status -Value $invokeSPSite.BaseResponse.StatusCode
            $warmUpResult += $invokeResult
        }

        $warmUpResult = $warmUpResult | Out-String
        Write-Verbose -Message 'WarmUp SPSite Completed - Add Event in Event Viewer'
        New-EventLog –LogName Application –Source 'SharePointDsc WarmUp SPSite' -ErrorAction SilentlyContinue
        Write-EventLog –LogName Application `
                       –Source 'SharePointDsc WarmUp SPSite' `
                       –EntryType Information `
                       –EventID 1 `
                       –Message $warmUpResult
    }
    catch
    {
        throw "An error occurred warming up site collections: $($_.Exception.Message)"
    }
}

function Get-SPDscAllSPSite
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IncludeCentralAdmin
    )
 
    $tbSitesURL = New-Object -TypeName System.Collections.ArrayList

    try
    {
        [void]$tbSitesURL.Add('http://localhost:32843/Topology/topology.svc')
        
        if ($IncludeCentralAdmin -eq $true)
        {
            $webAppADM = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
                $_.IsAdministrationWebApplication
            }
            $siteADM = $webAppADM.Url
            [void]$tbSitesURL.Add($siteADM)
            [void]$tbSitesURL.Add($siteADM + 'Lists/HealthReports/AllItems.aspx')
            [void]$tbSitesURL.Add($siteADM + '_admin/FarmServers.aspx')
            [void]$tbSitesURL.Add($siteADM + '_admin/Server.aspx')
            [void]$tbSitesURL.Add($siteADM + '_admin/WebApplicationList.aspx')
            [void]$tbSitesURL.Add($siteADM + '_admin/ServiceApplications.aspx')
        }
    
        $webApps = Get-SPWebApplication
    
        foreach ($webApp in $webApps)
        {
            $sites = $webApp.sites
            foreach ($site in $sites)
            {
                [void]$tbSitesURL.Add($site.Url)
                $site.Dispose()
            }
        }
    }
    catch
    {
        throw "An error occurred getting all site collections: $($_.Exception.Message)"	
    }

    $tbSitesURL
}

Export-ModuleMember -Function *-TargetResource
