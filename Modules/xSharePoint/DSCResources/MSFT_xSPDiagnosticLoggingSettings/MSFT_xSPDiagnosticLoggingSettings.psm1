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

    Write-Verbose -Message "Getting diagnostic configuration settings"
    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ScriptBlock {
        $dc = Get-SPDiagnosticConfig -ErrorAction SilentlyContinue
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
        $AppAnalyticsAutomaticUploadEnabled = $true,

        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled = $true,

        [System.UInt32]
        $DaysToKeepLogs = 14,

        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled = $true,

        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled = $true,

        [System.Boolean]
        $ErrorReportingEnabled = $true,

        [System.Boolean]
        $EventLogFloodProtectionEnabled = $true,

        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval = 5,

        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod = 2,

        [System.UInt32]
        $EventLogFloodProtectionThreshold = 5,

        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod = 2,

        [System.UInt32]
        $LogCutInterval = 30,

        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled = $true,

        [System.UInt32]
        $ScriptErrorReportingDelay = 30,

        [System.Boolean]
        $ScriptErrorReportingEnabled = $true,

        [System.Boolean]
        $ScriptErrorReportingRequireAuth = $true,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting diagnostic configuration settings"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $params.Remove("InstallAccount") | Out-Null
        $params = Rename-xSharePointParamValue -params $params -oldName "LogPath" -newName "LogLocation"
        $params = Rename-xSharePointParamValue -params $params -oldName "LogSpaceInGB" -newName "LogDiskSpaceUsageGB"

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
        $AppAnalyticsAutomaticUploadEnabled = $true,

        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled = $true,

        [System.UInt32]
        $DaysToKeepLogs = 14,

        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled = $true,

        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled = $true,

        [System.Boolean]
        $ErrorReportingEnabled = $true,

        [System.Boolean]
        $EventLogFloodProtectionEnabled = $true,

        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval = 5,

        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod = 2,

        [System.UInt32]
        $EventLogFloodProtectionThreshold = 5,

        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod = 2,

        [System.UInt32]
        $LogCutInterval = 30,

        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled = $true,

        [System.UInt32]
        $ScriptErrorReportingDelay = 30,

        [System.Boolean]
        $ScriptErrorReportingEnabled = $true,

        [System.Boolean]
        $ScriptErrorReportingRequireAuth = $true,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting diagnostic configuration settings"

    $result = Get-TargetResource -LogPath $LogPath -LogSpaceInGB $LogSpaceInGB -InstallAccount $InstallAccount 
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

