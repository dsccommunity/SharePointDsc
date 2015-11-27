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

    if($Settings.ListViewThreshold -ne $null ){
        $WebApplication.MaxItemsPerThrottledOperation = $Settings.ListViewThreshold
    }
    if($Settings.AllowObjectModelOverride -ne $null){
        $WebApplication.AllowOMCodeOverrideThrottleSettings =  $Settings.AllowObjectModelOverride
    }
    if($Settings.AdminThreshold -ne $null){
        $WebApplication.MaxItemsPerThrottledOperationOverride = $Settings.AdminThreshold
    }
    if($Settings.ListViewLookupThreshold -ne $null){
        $WebApplication.MaxQueryLookupFields =  $Settings.ListViewLookupThreshold
    }
    if($Settings.HappyHourEnabled -ne $null){
        $WebApplication.UnthrottledPrivilegedOperationWindowEnabled =$Settings.HappyHourEnabled
    }
    if($Settings.HappyHour -ne $null){
        $happyHour =$Settings.HappyHour;
        if(($happyHour.Hour -ne $null) -and ($happyHour.Minute -ne $null) -and ($happyHour.Duration -ne $null)){
            if(($happyHour.Hour -le 24) -and ($happyHour.Minute -le 24) -and ($happyHour.Duration -le 24)){
                $WebApplication.DailyStartUnthrottledPrivilegedOperationsHour = $happyHour.Hour 
                $WebApplication.DailyStartUnthrottledPrivilegedOperationsMinute = $happyHour.Minute
                $WebApplication.DailyUnthrottledPrivilegedOperationsDuration = $happyHour.Duration
            }else{
                throw "the valid  hour, minute and duration range is 0-24";
                }
                    
        }else {
            throw "You need to Provide Hour, Minute and Duration when providing HappyHour settings";
        }
    }
    if($Settings.UniquePermissionThreshold){
        $WebApplication.MaxUniquePermScopesPerList = $Settings.UniquePermissionThreshold
    }
    if($Settings.EventHandlersEnabled){
        $WebApplication.EventHandlersEnabled = $Settings.EventHandlersEnabled
    }
    if($Settings.RequestThrottling){
        $WebApplication.HttpThrottleSettings.PerformThrottle = $Settings.RequestThrottling
    }
    if($Settings.ChangeLogEnabled){
        $WebApplication.ChangeLogExpirationEnabled = $Settings.ChangeLogEnabled
    }
    if($Settings.ChangeLogExpiryDays){
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
        if ($Settings.ContainsKey("HappyHour") -eq $true) {
            $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentSettings.HappyHour `
                                                             -DesiredValues $DesiredSettings.HappyHour
        }
    }
    return $testReturn
}

