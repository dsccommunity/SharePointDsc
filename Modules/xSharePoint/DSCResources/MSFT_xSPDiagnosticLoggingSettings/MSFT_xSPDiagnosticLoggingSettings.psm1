function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $LogPath,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $LogSpaceInGB,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Getting diagnostic configuration settings"
    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ScriptBlock {
        $dc = Get-SPDiagnosticConfig -ErrorAction SilentlyContinue
        if ($dc -eq $null) { return @{} }
        
        return @{
            AllowLegacyTraceProviders = $dc.AllowLegacyTraceProviders
            AppAnalyticsAutomaticUploadEnabled = $dc.AppAnalyticsAutomaticUploadEnabled
            CustomerExperienceImprovementProgramEnabled = $dc.CustomerExperienceImprovementProgramEnabled
            ErrorReportingEnabled = $dc.ErrorReportingEnabled
            ErrorReportingAutomaticUploadEnabled = $dc.ErrorReportingAutomaticUploadEnabled
            DownloadErrorReportingUpdatesEnabled = $dc.DownloadErrorReportingUpdatesEnabled
            DaysToKeepLogs = $dc.DaysToKeepLogs
            LogMaxDiskSpaceUsageEnabled = $dc.LogMaxDiskSpaceUsageEnabled
            LogDiskSpaceUsageGB = $dc.LogDiskSpaceUsageGB
            LogLocation = $dc.LogLocation
            LogCutInterval = $dc.LogCutInterval
            EventLogFloodProtectionEnabled = $dc.EventLogFloodProtectionEnabled
            EventLogFloodProtectionThreshold = $dc.EventLogFloodProtectionThreshold
            EventLogFloodProtectionTriggerPeriod = $dc.EventLogFloodProtectionTriggerPeriod
            EventLogFloodProtectionQuietPeriod = $dc.EventLogFloodProtectionQuietPeriod
            EventLogFloodProtectionNotifyInterval = $dc.EventLogFloodProtectionNotifyInterval
            ScriptErrorReportingEnabled = $dc.ScriptErrorReportingEnabled
            ScriptErrorReportingRequireAuth = $dc.ScriptErrorReportingRequireAuth
            ScriptErrorReportingDelay = $dc.ScriptErrorReportingDelay
        }
    }
    $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $LogPath,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $LogSpaceInGB,

        [System.Boolean]
        $AppAnalyticsAutomaticUploadEnabled,

        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled,

        [System.Boolean]
        $DaysToKeepLogs,

        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled,

        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled,

        [System.Boolean]
        $ErrorReportingEnabled,

        [System.Boolean]
        $EventLogFloodProtectionEnabled,

        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval,

        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod,

        [System.UInt32]
        $EventLogFloodProtectionThreshold,

        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod,

        [System.UInt32]
        $LogCutInterval,

        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled,

        [System.UInt32]
        $ScriptErrorReportingDelay,

        [System.Boolean]
        $ScriptErrorReportingEnabled,

        [System.Boolean]
        $ScriptErrorReportingRequireAuth,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Setting diagnostic configuration settings"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $params = @{}
    $params.Add("LogLocation", $LogPath)
    $params.Add("LogDiskSpaceUsageGB", $LogSpaceInGB)
    if ([string]::IsNullOrEmpty($AppAnalyticsAutomaticUploadEnabled) -eq $false) { $params.Add("AppAnalyticsAutomaticUploadEnabled", $AppAnalyticsAutomaticUploadEnabled)}
    if ([string]::IsNullOrEmpty($CustomerExperienceImprovementProgramEnabled) -eq $false) { $params.Add("CustomerExperienceImprovementProgramEnabled", $CustomerExperienceImprovementProgramEnabled)}
    if ([string]::IsNullOrEmpty($DaysToKeepLogs) -eq $false   -ne $null) { $params.Add("DaysToKeepLogs", $DaysToKeepLogs)}
    if ([string]::IsNullOrEmpty($DownloadErrorReportingUpdatesEnabled) -eq $false) { $params.Add("DownloadErrorReportingUpdatesEnabled", $DownloadErrorReportingUpdatesEnabled)}
    if ([string]::IsNullOrEmpty($ErrorReportingAutomaticUploadEnabled) -eq $false) { $params.Add("ErrorReportingAutomaticUploadEnabled", $ErrorReportingAutomaticUploadEnabled)}
    if ([string]::IsNullOrEmpty($ErrorReportingEnabled) -eq $false) { $params.Add("ErrorReportingEnabled", $ErrorReportingEnabled)}
    if ([string]::IsNullOrEmpty($EventLogFloodProtectionEnabled) -eq $false) { $params.Add("EventLogFloodProtectionEnabled", $EventLogFloodProtectionEnabled)}
    if ([string]::IsNullOrEmpty($EventLogFloodProtectionNotifyInterval) -eq $false) { $params.Add("EventLogFloodProtectionNotifyInterval", $EventLogFloodProtectionNotifyInterval)}
    if ([string]::IsNullOrEmpty($EventLogFloodProtectionQuietPeriod) -eq $false) { $params.Add("EventLogFloodProtectionQuietPeriod", $EventLogFloodProtectionQuietPeriod)}
    if ([string]::IsNullOrEmpty($EventLogFloodProtectionThreshold) -eq $false) { $params.Add("EventLogFloodProtectionThreshold", $EventLogFloodProtectionThreshold)}
    if ([string]::IsNullOrEmpty($EventLogFloodProtectionTriggerPeriod) -eq $false) { $params.Add("EventLogFloodProtectionTriggerPeriod", $EventLogFloodProtectionTriggerPeriod)}
    if ([string]::IsNullOrEmpty($LogCutInterval) -eq $false) { $params.Add("LogCutInterval", $LogCutInterval)}
    if ([string]::IsNullOrEmpty($LogMaxDiskSpaceUsageEnabled) -eq $false) { $params.Add("LogMaxDiskSpaceUsageEnabled", $LogMaxDiskSpaceUsageEnabled)}
    if ([string]::IsNullOrEmpty($ScriptErrorReportingDelay) -eq $false) { $params.Add("ScriptErrorReportingDelay", $ScriptErrorReportingDelay)}
    if ([string]::IsNullOrEmpty($ScriptErrorReportingEnabled) -eq $false) { $params.Add("ScriptErrorReportingEnabled", $ScriptErrorReportingEnabled)}
    if ([string]::IsNullOrEmpty($ScriptErrorReportingRequireAuth) -eq $false) { $params.Add("ScriptErrorReportingRequireAuth", $ScriptErrorReportingRequireAuth)}

    $result = Invoke-Command -Session $session -ArgumentList $params -ScriptBlock {
        $params = $args[0]
        Set-SPDiagnosticConfig @params
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
        $LogPath,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $LogSpaceInGB,

        [System.Boolean]
        $AppAnalyticsAutomaticUploadEnabled,

        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled,

        [System.Boolean]
        $DaysToKeepLogs,

        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled,

        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled,

        [System.Boolean]
        $ErrorReportingEnabled,

        [System.Boolean]
        $EventLogFloodProtectionEnabled,

        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval,

        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod,

        [System.UInt32]
        $EventLogFloodProtectionThreshold,

        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod,

        [System.UInt32]
        $LogCutInterval,

        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled,

        [System.UInt32]
        $ScriptErrorReportingDelay,

        [System.Boolean]
        $ScriptErrorReportingEnabled,

        [System.Boolean]
        $ScriptErrorReportingRequireAuth,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Getting diagnostic configuration settings"

    $result = Get-TargetResource -LogPath $LogPath -LogSpaceInGB $LogSpaceInGB -InstallAccount $InstallAccount 
    if ($LogPath -ne $result.LogLocation) { return $false }
    if ($LogSpaceInGB -ne $result.LogDiskSpaceUsageGB) { return $false }

    if ($AppAnalyticsAutomaticUploadEnabled -ne $null -and $AppAnalyticsAutomaticUploadEnabled -ne $result.AppAnalyticsAutomaticUploadEnabled) { return $false }
    if ($CustomerExperienceImprovementProgramEnabled -ne $null -and $CustomerExperienceImprovementProgramEnabled -ne $result.CustomerExperienceImprovementProgramEnabled) { return $false }
    if ($DaysToKeepLogs -gt 0 -and $DaysToKeepLogs -ne $result.DaysToKeepLogs) { return $false } 
    if ($DownloadErrorReportingUpdatesEnabled -ne $null -and $DownloadErrorReportingUpdatesEnabled -ne $result.DownloadErrorReportingUpdatesEnabled) { return $false }
    if ($ErrorReportingAutomaticUploadEnabled -ne $null -and $ErrorReportingAutomaticUploadEnabled -ne $result.ErrorReportingAutomaticUploadEnabled) { return $false }
    if ($ErrorReportingEnabled -ne $null -and $ErrorReportingEnabled -ne $result.ErrorReportingEnabled) { return $false }
    if ($EventLogFloodProtectionEnabled -ne $null -and $EventLogFloodProtectionEnabled -ne $result.EventLogFloodProtectionEnabled) { return $false }
    if ($EventLogFloodProtectionNotifyInterval -gt 0 -and $EventLogFloodProtectionNotifyInterval -ne $result.EventLogFloodProtectionNotifyInterval) { return $false }   
    if ($EventLogFloodProtectionQuietPeriod -gt 0 -and $EventLogFloodProtectionQuietPeriod -ne $result.EventLogFloodProtectionQuietPeriod) { return $false } 
    if ($EventLogFloodProtectionThreshold -gt 0 -and $EventLogFloodProtectionThreshold -ne $result.EventLogFloodProtectionThreshold) { return $false } 
    if ($EventLogFloodProtectionTriggerPeriod -gt 0 -and $EventLogFloodProtectionTriggerPeriod -ne $result.EventLogFloodProtectionTriggerPeriod) { return $false } 
    if ($LogCutInterval -gt 0 -and $LogCutInterval -ne $result.LogCutInterval) { return $false } 
    if ($LogMaxDiskSpaceUsageEnabled -ne $null -and $LogMaxDiskSpaceUsageEnabled -ne $result.LogMaxDiskSpaceUsageEnabled) { return $false }
    if ($ScriptErrorReportingDelay -gt 0 -and $ScriptErrorReportingDelay -ne $result.ScriptErrorReportingDelay) { return $false } 
    if ($ScriptErrorReportingEnabled -ne $null -and $ScriptErrorReportingEnabled -ne $result.ScriptErrorReportingEnabled) { return $false }
    if ($ScriptErrorReportingRequireAuth -ne $null -and $ScriptErrorReportingRequireAuth -ne $result.ScriptErrorReportingRequireAuth) { return $false }
    return $true
}


Export-ModuleMember -Function *-TargetResource

