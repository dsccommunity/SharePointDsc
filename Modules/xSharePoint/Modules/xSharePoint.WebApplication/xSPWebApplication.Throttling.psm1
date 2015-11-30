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

    if($Settings.ContainsKey("ListViewThreshold") -eq $true) {
        $WebApplication.MaxItemsPerThrottledOperation = $Settings.ListViewThreshold
    }
    if($Settings.ContainsKey("AllowObjectModelOverride") -eq $true) {
        $WebApplication.AllowOMCodeOverrideThrottleSettings =  $Settings.AllowObjectModelOverride
    }
    if($Settings.ContainsKey("AdminThreshold") -eq $true) {
        $WebApplication.MaxItemsPerThrottledOperationOverride = $Settings.AdminThreshold
    }
    if($Settings.ContainsKey("ListViewLookupThreshold") -eq $true) {
        $WebApplication.MaxQueryLookupFields =  $Settings.ListViewLookupThreshold
    }
    if($Settings.ContainsKey("HappyHourEnabled") -eq $true) {
        $WebApplication.UnthrottledPrivilegedOperationWindowEnabled =$Settings.HappyHourEnabled
    }
    if($Settings.ContainsKey("HappyHour") -eq $true) {
        $happyHour = $Settings.HappyHour;
        if ($happyHour.ContainsKey("Hour") -eq $false -or $happyHour.ContainsKey("Minute") -eq $false -or $happyHour.ContainsKey("Duration") -eq $false) {
            throw "Happy hour settings must include 'hour', 'minute' and 'duration'"
        } else {
            if ($happyHour.Hour -lt 0 -or $happyHour.Hour -gt 23) {
                throw "Happy hour setting 'hour' must be between 0 and 23"
            }
            if ($happyHour.Minute -lt 0 -or $happyHour.Minute -gt 59) {
                throw "Happy hour setting 'minute' must be between 0 and 59"
            }
            if ($happyHour.Duration -lt 0 -or $happyHour.Duration -gt 23) {
                throw "Happy hour setting 'hour' must be between 0 and 23"
            }
            $WebApplication.SetDailyUnthrottledPrivilegedOperationWindow($happyHour.Hour, $happyHour.Minute, $happyHour.Duration)
        }
    }
    if($Settings.ContainsKey("UniquePermissionThreshold") -eq $true) {
        $WebApplication.MaxUniquePermScopesPerList = $Settings.UniquePermissionThreshold
    }
    if($Settings.ContainsKey("EventHandlersEnabled") -eq $true) {
        $WebApplication.EventHandlersEnabled = $Settings.EventHandlersEnabled
    }
    if($Settings.ContainsKey("RequestThrottling") -eq $true) {
        $WebApplication.HttpThrottleSettings.PerformThrottle = $Settings.RequestThrottling
    }
    if($Settings.ContainsKey("ChangeLogEnabled") -eq $true) {
        $WebApplication.ChangeLogExpirationEnabled = $Settings.ChangeLogEnabled
    }
    if($Settings.ContainsKey("ChangeLogExpiryDays") -eq $true) {
        $WebApplication.ChangeLogRetentionPeriod = New-TimeSpan -Days $Settings.ChangeLogExpiryDays
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
        if ($DesiredSettings.ContainsKey("HappyHour") -eq $true) {
            $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentSettings.HappyHour `
                                                             -DesiredValues $DesiredSettings.HappyHour
        }
    }
    return $testReturn
}

