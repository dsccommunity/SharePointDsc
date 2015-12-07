function Get-xSPWebApplicationThrottlingSettings {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)] $WebApplication
    )
    return @{
        ListViewThreshold = $WebApplication.MaxItemsPerThrottledOperation
        AllowObjectModelOverride  = $WebApplication.AllowOMCodeOverrideThrottleSettings
        AdminThreshold = $WebApplication.MaxItemsPerThrottledOperationOverride
        ListViewLookupThreshold = $WebApplication.MaxQueryLookupFields
        HappyHourEnabled = $WebApplication.UnthrottledPrivilegedOperationWindowEnabled
        HappyHour = @{
            Hour = $WebApplication.DailyStartUnthrottledPrivilegedOperationsHour
            Minute = $WebApplication.DailyStartUnthrottledPrivilegedOperationsMinute
            Duration = $WebApplication.DailyUnthrottledPrivilegedOperationsDuration
        }
        UniquePermissionThreshold = $WebApplication.MaxUniquePermScopesPerList
        RequestThrottling = $WebApplication.HttpThrottleSettings.PerformThrottle
        ChangeLogEnabled = $WebApplication.ChangeLogExpirationEnabled
        ChangeLogExpiryDays = $WebApplication.ChangeLogRetentionPeriod.Days
        EventHandlersEnabled = $WebApplication.EventHandlersEnabled
    }
}

function Set-xSPWebApplicationThrottlingSettings {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] $WebApplication,
        [parameter(Mandatory = $true)] $Settings
    )

    # Format here is SPWebApplication property = Custom settings property
    $mapping = @{
        MaxItemsPerThrottledOperation = "ListViewThreshold"
        AllowOMCodeOverrideThrottleSettings = "AllowObjectModelOverride"
        MaxItemsPerThrottledOperationOverride = "AdminThreshold"
        MaxQueryLookupFields = "ListViewLookupThreshold"
        UnthrottledPrivilegedOperationWindowEnabled = "HappyHourEnabled"
        MaxUniquePermScopesPerList = "UniquePermissionThreshold"
        EventHandlersEnabled = "EventHandlersEnabled"
        ChangeLogExpirationEnabled = "ChangeLogEnabled"
    } 
    $mapping.Keys | ForEach-Object {
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $WebApplication `
                                                   -PropertyToSet $_ `
                                                   -ParamsValue $settings `
                                                   -ParamKey $mapping[$_]
    }

    # Set throttle settings child property seperately
    Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $WebApplication.HttpThrottleSettings `
                                               -PropertyToSet "PerformThrottle" `
                                               -ParamsValue $Settings `
                                               -ParamKey "RequestThrottling"
    
    # Create time span object separately
    if ((Test-xSharePointObjectHasProperty $Settings "ChangeLogExpiryDays") -eq $true) {
        $WebApplication.ChangeLogRetentionPeriod = New-TimeSpan -Days $Settings.ChangeLogExpiryDays
    }
}


function Set-xSPWebApplicationHappyHourSettings {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] $WebApplication,
        [parameter(Mandatory = $true)] $Settings
    )

    if ((Test-xSharePointObjectHasProperty $Settings "Hour") -eq $false -or (Test-xSharePointObjectHasProperty $Settings "Minute") -eq $false -or (Test-xSharePointObjectHasProperty $Settings "Duration") -eq $false) {
        throw "Happy hour settings must include 'hour', 'minute' and 'duration'"
    } else {
        if ($Settings.Hour -lt 0 -or $Settings.Hour -gt 23) {
            throw "Happy hour setting 'hour' must be between 0 and 23"
        }
        if ($Settings.Minute -lt 0 -or $Settings.Minute -gt 59) {
            throw "Happy hour setting 'minute' must be between 0 and 59"
        }
        if ($Settings.Duration -lt 0 -or $Settings.Duration -gt 23) {
            throw "Happy hour setting 'hour' must be between 0 and 23"
        }
        $WebApplication.SetDailyUnthrottledPrivilegedOperationWindow($happyHour.Hour, $happyHour.Minute, $happyHour.Duration)
    }
}

function Test-xSPWebApplicationThrottlingSettings {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] $DesiredSettings
    )

    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.Util\xSharePoint.Util.psm1" -Resolve)
    $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentSettings `
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
    if ($testReturn -eq $true) {
        if ((Test-xSharePointObjectHasProperty $DesiredSettings "HappyHour") -eq $true) {
            $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentSettings.HappyHour `
                                                             -DesiredValues $DesiredSettings.HappyHour `
                                                             -ValuesToCheck @("Hour", "Minute", "Duration")
        }
    }
    return $testReturn
}

