function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $LogPath,
        [parameter(Mandatory = $true)]  [System.UInt32]  $LogSpaceInGB,
        [parameter(Mandatory = $false)] [System.Boolean] $AppAnalyticsAutomaticUploadEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $CustomerExperienceImprovementProgramEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $DaysToKeepLogs,
        [parameter(Mandatory = $false)] [System.Boolean] $DownloadErrorReportingUpdatesEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $ErrorReportingAutomaticUploadEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $ErrorReportingEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $EventLogFloodProtectionEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionNotifyInterval,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionQuietPeriod,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionThreshold,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionTriggerPeriod,
        [parameter(Mandatory = $false)] [System.UInt32]  $LogCutInterval,
        [parameter(Mandatory = $false)] [System.Boolean] $LogMaxDiskSpaceUsageEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $ScriptErrorReportingDelay,
        [parameter(Mandatory = $false)] [System.Boolean] $ScriptErrorReportingEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $ScriptErrorReportingRequireAuth,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
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
            LogSpaceInGB = $dc.LogDiskSpaceUsageGB
            LogPath = $dc.LogLocation
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
    $result.Add("InstallAccount", $InstallAccount)
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $LogPath,
        [parameter(Mandatory = $true)]  [System.UInt32]  $LogSpaceInGB,
        [parameter(Mandatory = $false)] [System.Boolean] $AppAnalyticsAutomaticUploadEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $CustomerExperienceImprovementProgramEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $DaysToKeepLogs,
        [parameter(Mandatory = $false)] [System.Boolean] $DownloadErrorReportingUpdatesEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $ErrorReportingAutomaticUploadEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $ErrorReportingEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $EventLogFloodProtectionEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionNotifyInterval,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionQuietPeriod,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionThreshold,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionTriggerPeriod,
        [parameter(Mandatory = $false)] [System.UInt32]  $LogCutInterval,
        [parameter(Mandatory = $false)] [System.Boolean] $LogMaxDiskSpaceUsageEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $ScriptErrorReportingDelay,
        [parameter(Mandatory = $false)] [System.Boolean] $ScriptErrorReportingEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $ScriptErrorReportingRequireAuth,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String]  $LogPath,
        [parameter(Mandatory = $true)]  [System.UInt32]  $LogSpaceInGB,
        [parameter(Mandatory = $false)] [System.Boolean] $AppAnalyticsAutomaticUploadEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $CustomerExperienceImprovementProgramEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $DaysToKeepLogs,
        [parameter(Mandatory = $false)] [System.Boolean] $DownloadErrorReportingUpdatesEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $ErrorReportingAutomaticUploadEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $ErrorReportingEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $EventLogFloodProtectionEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionNotifyInterval,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionQuietPeriod,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionThreshold,
        [parameter(Mandatory = $false)] [System.UInt32]  $EventLogFloodProtectionTriggerPeriod,
        [parameter(Mandatory = $false)] [System.UInt32]  $LogCutInterval,
        [parameter(Mandatory = $false)] [System.Boolean] $LogMaxDiskSpaceUsageEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $ScriptErrorReportingDelay,
        [parameter(Mandatory = $false)] [System.Boolean] $ScriptErrorReportingEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $ScriptErrorReportingRequireAuth,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting diagnostic configuration settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
}


Export-ModuleMember -Function *-TargetResource
