$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $LogPath,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $LogSpaceInGB,

        [Parameter()]
        [System.Boolean]
        $AppAnalyticsAutomaticUploadEnabled,

        [Parameter()]
        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled,

        [Parameter()]
        [System.UInt32]
        $DaysToKeepLogs,

        [Parameter()]
        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled,

        [Parameter()]
        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled,

        [Parameter()]
        [System.Boolean]
        $ErrorReportingEnabled,

        [Parameter()]
        [System.Boolean]
        $EventLogFloodProtectionEnabled,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionThreshold,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod,

        [Parameter()]
        [System.UInt32]
        $LogCutInterval,

        [Parameter()]
        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled,

        [Parameter()]
        [System.UInt32]
        $ScriptErrorReportingDelay,

        [Parameter()]
        [System.Boolean]
        $ScriptErrorReportingEnabled,

        [Parameter()]
        [System.Boolean]
        $ScriptErrorReportingRequireAuth,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting diagnostic configuration settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturn = @{
            IsSingleInstance                            = "Yes"
            AppAnalyticsAutomaticUploadEnabled          = $null
            CustomerExperienceImprovementProgramEnabled = $null
            ErrorReportingEnabled                       = $null
            ErrorReportingAutomaticUploadEnabled        = $null
            DownloadErrorReportingUpdatesEnabled        = $null
            DaysToKeepLogs                              = $null
            LogMaxDiskSpaceUsageEnabled                 = $null
            LogSpaceInGB                                = $null
            LogPath                                     = $null
            LogCutInterval                              = $null
            EventLogFloodProtectionEnabled              = $null
            EventLogFloodProtectionThreshold            = $null
            EventLogFloodProtectionTriggerPeriod        = $null
            EventLogFloodProtectionQuietPeriod          = $null
            EventLogFloodProtectionNotifyInterval       = $null
            ScriptErrorReportingEnabled                 = $null
            ScriptErrorReportingRequireAuth             = $null
            ScriptErrorReportingDelay                   = $null
        }

        $dc = Get-SPDiagnosticConfig -ErrorAction SilentlyContinue
        if ($null -eq $dc)
        {
            return $nullReturn
        }

        return @{
            IsSingleInstance                            = "Yes"
            AppAnalyticsAutomaticUploadEnabled          = $dc.AppAnalyticsAutomaticUploadEnabled
            CustomerExperienceImprovementProgramEnabled = `
                $dc.CustomerExperienceImprovementProgramEnabled
            ErrorReportingEnabled                       = $dc.ErrorReportingEnabled
            ErrorReportingAutomaticUploadEnabled        = $dc.ErrorReportingAutomaticUploadEnabled
            DownloadErrorReportingUpdatesEnabled        = $dc.DownloadErrorReportingUpdatesEnabled
            DaysToKeepLogs                              = $dc.DaysToKeepLogs
            LogMaxDiskSpaceUsageEnabled                 = $dc.LogMaxDiskSpaceUsageEnabled
            LogSpaceInGB                                = $dc.LogDiskSpaceUsageGB
            LogPath                                     = $dc.LogLocation
            LogCutInterval                              = $dc.LogCutInterval
            EventLogFloodProtectionEnabled              = $dc.EventLogFloodProtectionEnabled
            EventLogFloodProtectionThreshold            = $dc.EventLogFloodProtectionThreshold
            EventLogFloodProtectionTriggerPeriod        = $dc.EventLogFloodProtectionTriggerPeriod
            EventLogFloodProtectionQuietPeriod          = $dc.EventLogFloodProtectionQuietPeriod
            EventLogFloodProtectionNotifyInterval       = $dc.EventLogFloodProtectionNotifyInterval
            ScriptErrorReportingEnabled                 = $dc.ScriptErrorReportingEnabled
            ScriptErrorReportingRequireAuth             = $dc.ScriptErrorReportingRequireAuth
            ScriptErrorReportingDelay                   = $dc.ScriptErrorReportingDelay
            InstallAccount                              = $params.InstallAccount
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $LogPath,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $LogSpaceInGB,

        [Parameter()]
        [System.Boolean]
        $AppAnalyticsAutomaticUploadEnabled,

        [Parameter()]
        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled,

        [Parameter()]
        [System.UInt32]
        $DaysToKeepLogs,

        [Parameter()]
        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled,

        [Parameter()]
        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled,

        [Parameter()]
        [System.Boolean]
        $ErrorReportingEnabled,

        [Parameter()]
        [System.Boolean]
        $EventLogFloodProtectionEnabled,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionThreshold,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod,

        [Parameter()]
        [System.UInt32]
        $LogCutInterval,

        [Parameter()]
        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled,

        [Parameter()]
        [System.UInt32]
        $ScriptErrorReportingDelay,

        [Parameter()]
        [System.Boolean]
        $ScriptErrorReportingEnabled,

        [Parameter()]
        [System.Boolean]
        $ScriptErrorReportingRequireAuth,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting diagnostic configuration settings"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        if ($params.ContainsKey("IsSingleInstance"))
        {
            $params.Remove("IsSingleInstance") | Out-Null
        }

        if ($params.ContainsKey("InstallAccount"))
        {
            $params.Remove("InstallAccount") | Out-Null
        }
        $params = $params | Rename-SPDscParamValue -oldName "LogPath" `
            -newName "LogLocation" `
        | Rename-SPDscParamValue -oldName "LogSpaceInGB" `
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $LogPath,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $LogSpaceInGB,

        [Parameter()]
        [System.Boolean]
        $AppAnalyticsAutomaticUploadEnabled,

        [Parameter()]
        [System.Boolean]
        $CustomerExperienceImprovementProgramEnabled,

        [Parameter()]
        [System.UInt32]
        $DaysToKeepLogs,

        [Parameter()]
        [System.Boolean]
        $DownloadErrorReportingUpdatesEnabled,

        [Parameter()]
        [System.Boolean]
        $ErrorReportingAutomaticUploadEnabled,

        [Parameter()]
        [System.Boolean]
        $ErrorReportingEnabled,

        [Parameter()]
        [System.Boolean]
        $EventLogFloodProtectionEnabled,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionNotifyInterval,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionQuietPeriod,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionThreshold,

        [Parameter()]
        [System.UInt32]
        $EventLogFloodProtectionTriggerPeriod,

        [Parameter()]
        [System.UInt32]
        $LogCutInterval,

        [Parameter()]
        [System.Boolean]
        $LogMaxDiskSpaceUsageEnabled,

        [Parameter()]
        [System.UInt32]
        $ScriptErrorReportingDelay,

        [Parameter()]
        [System.Boolean]
        $ScriptErrorReportingEnabled,

        [Parameter()]
        [System.Boolean]
        $ScriptErrorReportingRequireAuth,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing diagnostic configuration settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
