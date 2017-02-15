function Get-SPDSCWebApplicationThrottlingConfig 
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)] 
        $WebApplication
    )
    return @{
        ListViewThreshold        = $WebApplication.MaxItemsPerThrottledOperation
        AllowObjectModelOverride = $WebApplication.AllowOMCodeOverrideThrottleSettings
        AdminThreshold           = $WebApplication.MaxItemsPerThrottledOperationOverride
        ListViewLookupThreshold  = $WebApplication.MaxQueryLookupFields
        HappyHourEnabled         = $WebApplication.UnthrottledPrivilegedOperationWindowEnabled
        HappyHour = @{
            Hour     = $WebApplication.DailyStartUnthrottledPrivilegedOperationsHour
            Minute   = $WebApplication.DailyStartUnthrottledPrivilegedOperationsMinute
            Duration = $WebApplication.DailyUnthrottledPrivilegedOperationsDuration
        }
        UniquePermissionThreshold = $WebApplication.MaxUniquePermScopesPerList
        RequestThrottling         = $WebApplication.HttpThrottleSettings.PerformThrottle
        ChangeLogEnabled          = $WebApplication.ChangeLogExpirationEnabled
        ChangeLogExpiryDays       = $WebApplication.ChangeLogRetentionPeriod.Days
        EventHandlersEnabled      = $WebApplication.EventHandlersEnabled
    }
}

function Set-SPDSCWebApplicationThrottlingConfig 
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] 
        $WebApplication,

        [parameter(Mandatory = $true)] 
        $Settings
    )

    # Format here is SPWebApplication property = Custom settings property
    $mapping = @{
        MaxItemsPerThrottledOperation               = "ListViewThreshold"
        AllowOMCodeOverrideThrottleSettings         = "AllowObjectModelOverride"
        MaxItemsPerThrottledOperationOverride       = "AdminThreshold"
        MaxQueryLookupFields                        = "ListViewLookupThreshold"
        UnthrottledPrivilegedOperationWindowEnabled = "HappyHourEnabled"
        MaxUniquePermScopesPerList                  = "UniquePermissionThreshold"
        EventHandlersEnabled                        = "EventHandlersEnabled"
        ChangeLogExpirationEnabled                  = "ChangeLogEnabled"
    } 
    $mapping.Keys | ForEach-Object -Process {
        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $WebApplication `
                                              -PropertyToSet $_ `
                                              -ParamsValue $settings `
                                              -ParamKey $mapping[$_]
    }

    # Set throttle settings child property seperately
    Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $WebApplication.HttpThrottleSettings `
                                          -PropertyToSet "PerformThrottle" `
                                          -ParamsValue $Settings `
                                          -ParamKey "RequestThrottling"
    
    # Create time span object separately
    if ((Test-SPDSCObjectHasProperty $Settings "ChangeLogExpiryDays") -eq $true) 
    {
        $days = New-TimeSpan -Days $Settings.ChangeLogExpiryDays
        $WebApplication.ChangeLogRetentionPeriod = $days
    }
}


function Set-SPDSCWebApplicationHappyHourConfig 
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] 
        $WebApplication,
        
        [parameter(Mandatory = $true)] 
        $Settings
    )

    if ((Test-SPDSCObjectHasProperty $Settings "Hour") -eq $false `
      -or (Test-SPDSCObjectHasProperty $Settings "Minute") -eq $false `
      -or (Test-SPDSCObjectHasProperty $Settings "Duration") -eq $false) 
    {
        throw "Happy hour settings must include 'hour', 'minute' and 'duration'"
    } 
    else 
    {
        if ($Settings.Hour -lt 0 -or $Settings.Hour -gt 23) 
        {
            throw "Happy hour setting 'hour' must be between 0 and 23"
        }
        if ($Settings.Minute -lt 0 -or $Settings.Minute -gt 59) 
        {
            throw "Happy hour setting 'minute' must be between 0 and 59"
        }
        if ($Settings.Duration -lt 0 -or $Settings.Duration -gt 23) 
        {
            throw "Happy hour setting 'hour' must be between 0 and 23"
        }
        $h = $happyHour.Hour
        $m = $happyHour.Minute
        $d = $happyHour.Duration
        $WebApplication.SetDailyUnthrottledPrivilegedOperationWindow($h, $m, $d)
    }
}

function Test-SPDSCWebApplicationThrottlingConfig 
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] 
        $CurrentSettings,
        
        [parameter(Mandatory = $true)] 
        $DesiredSettings
    )

    $relPath = "..\..\Modules\SharePointDsc.Util\SharePointDsc.Util.psm1"
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $relPath -Resolve)
    $testReturn = Test-SPDscParameterState -CurrentValues $CurrentSettings `
                                                     -DesiredValues $DesiredSettings `
                                                     -ValuesToCheck @(
                                                         "ListViewThreshold",
                                                         "AllowObjectModelOverride",
                                                         "AdminThreshold",
                                                         "ListViewLookupThreshold",
                                                         "HappyHourEnabled",
                                                         "UniquePermissionThreshold",
                                                         "RequestThrottling",
                                                         "ChangeLogEnabled",
                                                         "ChangeLogExpiryDays",
                                                         "EventHandlersEnabled"
                                                     )
    if ($testReturn -eq $true) 
    {
        if ((Test-SPDSCObjectHasProperty $DesiredSettings "HappyHour") -eq $true) 
        {
            $testReturn = Test-SPDscParameterState -CurrentValues $CurrentSettings.HappyHour `
                                                   -DesiredValues $DesiredSettings.HappyHour `
                                                   -ValuesToCheck @("Hour", "Minute", "Duration")
        }
    }
    return $testReturn
}
