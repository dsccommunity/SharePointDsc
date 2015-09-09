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

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $AppAnalyticsAutomaticUploadEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $DaysToKeepLogs,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ErrorReportingEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $EventLogFloodProtectionEnabled,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionThreshold,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $LogCutInterval,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $ScriptErrorReportingDelay,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ScriptErrorReportingEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ScriptErrorReportingRequireAuth,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting diagnostic configuration settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {

        $dc = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPDiagnosticConfig" -ErrorAction SilentlyContinue
        if ($null -eq $dc) { return @{} }
        
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
    return $result
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

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $AppAnalyticsAutomaticUploadEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $DaysToKeepLogs,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ErrorReportingEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $EventLogFloodProtectionEnabled,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionThreshold,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $LogCutInterval,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $ScriptErrorReportingDelay,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ScriptErrorReportingEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ScriptErrorReportingRequireAuth,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting diagnostic configuration settings"

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null } 
        $params = $params | Rename-xSharePointParamValue -oldName "LogPath" -newName "LogLocation" `
		                  | Rename-xSharePointParamValue -oldName "LogSpaceInGB" -newName "LogDiskSpaceUsageGB"

		Invoke-xSharePointSPCmdlet -CmdletName "Set-SPDiagnosticConfig" -Arguments $params
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

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $AppAnalyticsAutomaticUploadEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $DaysToKeepLogs,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ErrorReportingEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $EventLogFloodProtectionEnabled,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionThreshold,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $LogCutInterval,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled,

		[parameter(Mandatory = $false)]
        [System.UInt32]
        $ScriptErrorReportingDelay,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ScriptErrorReportingEnabled,

		[parameter(Mandatory = $false)]
        [System.Boolean]
        $ScriptErrorReportingRequireAuth,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting diagnostic configuration settings"

    $result = Get-TargetResource @PSBoundParameters
    if ($LogPath -ne $result.LogLocation) { return $false }
    if ($LogSpaceInGB -ne $result.LogDiskSpaceUsageGB) { return $false }

    if ($AppAnalyticsAutomaticUploadEnabled -ne $result.AppAnalyticsAutomaticUploadEnabled) { return $false }
    if ($CustomerExperienceImprovementProgramEnabled -ne $result.CustomerExperienceImprovementProgramEnabled) { return $false }
    if ($DaysToKeepLogs -ne $result.DaysToKeepLogs) { return $false } 
    if ($DownloadErrorReportingUpdatesEnabled -ne $result.DownloadErrorReportingUpdatesEnabled) { return $false }
    if ($ErrorReportingAutomaticUploadEnabled -ne $result.ErrorReportingAutomaticUploadEnabled) { return $false }
    if ($ErrorReportingEnabled -ne $result.ErrorReportingEnabled) { return $false }
    if ($EventLogFloodProtectionEnabled -ne $result.EventLogFloodProtectionEnabled) { return $false }
    if ($EventLogFloodProtectionNotifyInterval -ne $result.EventLogFloodProtectionNotifyInterval) { return $false }   
    if ($EventLogFloodProtectionQuietPeriod -ne $result.EventLogFloodProtectionQuietPeriod) { return $false } 
    if ($EventLogFloodProtectionThreshold -ne $result.EventLogFloodProtectionThreshold) { return $false } 
    if ($EventLogFloodProtectionTriggerPeriod -ne $result.EventLogFloodProtectionTriggerPeriod) { return $false } 
    if ($LogCutInterval -ne $result.LogCutInterval) { return $false } 
    if ($LogMaxDiskSpaceUsageEnabled -ne $result.LogMaxDiskSpaceUsageEnabled) { return $false }
    if ($ScriptErrorReportingDelay -ne $result.ScriptErrorReportingDelay) { return $false } 
    if ($ScriptErrorReportingEnabled -ne $result.ScriptErrorReportingEnabled) { return $false }
    if ($ScriptErrorReportingRequireAuth -ne $result.ScriptErrorReportingRequireAuth) { return $false }
    return $true
}


Export-ModuleMember -Function *-TargetResource
