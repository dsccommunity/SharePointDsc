function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String]  
        $LogPath,

        [Parameter(Mandatory = $true)]  
        [System.UInt32]  
        $LogSpaceInGB,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AppAnalyticsAutomaticUploadEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $CustomerExperienceImprovementProgramEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $DaysToKeepLogs,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $DownloadErrorReportingUpdatesEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ErrorReportingAutomaticUploadEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ErrorReportingEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $EventLogFloodProtectionEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionNotifyInterval,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionQuietPeriod,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionThreshold,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionTriggerPeriod,

        [Parameter(Mandatory = $false)] 
        [System.UInt32] 
        $LogCutInterval,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $LogMaxDiskSpaceUsageEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $ScriptErrorReportingDelay,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ScriptErrorReportingEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ScriptErrorReportingRequireAuth,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting diagnostic configuration settings"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $dc = Get-SPDiagnosticConfig -ErrorAction SilentlyContinue
        if ($null -eq $dc)
        {
            return $null 
        }
        
        return @{
            AppAnalyticsAutomaticUploadEnabled = $dc.AppAnalyticsAutomaticUploadEnabled
            CustomerExperienceImprovementProgramEnabled = `
                $dc.CustomerExperienceImprovementProgramEnabled
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
            InstallAccount = $params.InstallAccount
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String]  
        $LogPath,

        [Parameter(Mandatory = $true)]  
        [System.UInt32]  
        $LogSpaceInGB,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AppAnalyticsAutomaticUploadEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $CustomerExperienceImprovementProgramEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $DaysToKeepLogs,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $DownloadErrorReportingUpdatesEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ErrorReportingAutomaticUploadEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ErrorReportingEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $EventLogFloodProtectionEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionNotifyInterval,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionQuietPeriod,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionThreshold,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionTriggerPeriod,

        [Parameter(Mandatory = $false)] 
        [System.UInt32] 
        $LogCutInterval,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $LogMaxDiskSpaceUsageEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $ScriptErrorReportingDelay,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ScriptErrorReportingEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ScriptErrorReportingRequireAuth,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting diagnostic configuration settings"

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]
        
        if ($params.ContainsKey("InstallAccount"))
        {
            $params.Remove("InstallAccount") | Out-Null 
        } 
        $params = $params | Rename-SPDSCParamValue -oldName "LogPath" `
                                                   -newName "LogLocation" `
                          | Rename-SPDSCParamValue -oldName "LogSpaceInGB" `
                                                   -newName "LogDiskSpaceUsageGB"

        Set-SPDiagnosticConfig @params
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String]  
        $LogPath,

        [Parameter(Mandatory = $true)]  
        [System.UInt32]  
        $LogSpaceInGB,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AppAnalyticsAutomaticUploadEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $CustomerExperienceImprovementProgramEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $DaysToKeepLogs,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $DownloadErrorReportingUpdatesEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ErrorReportingAutomaticUploadEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ErrorReportingEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $EventLogFloodProtectionEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionNotifyInterval,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionQuietPeriod,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionThreshold,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $EventLogFloodProtectionTriggerPeriod,

        [Parameter(Mandatory = $false)] 
        [System.UInt32] 
        $LogCutInterval,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $LogMaxDiskSpaceUsageEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $ScriptErrorReportingDelay,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ScriptErrorReportingEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ScriptErrorReportingRequireAuth,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing diagnostic configuration settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues)
    {
        return $false 
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
