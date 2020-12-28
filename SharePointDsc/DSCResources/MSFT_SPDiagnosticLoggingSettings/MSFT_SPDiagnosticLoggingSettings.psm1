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
        $params = $params | Rename-SPDscParamValue -OldName "LogPath" `
            -NewName "LogLocation" `
        | Rename-SPDscParamValue -OldName "LogSpaceInGB" `
            -NewName "LogDiskSpaceUsageGB"

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
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

<## This function retrieves all settings related to Diagnostic Logging (ULS logs) on the SharePoint farm. #>
function Export-TargetResource
{
    if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
    }
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPDiagnosticLoggingSettings\MSFT_SPDiagnosticLoggingSettings.psm1" -Resolve
    $params = Get-DSCFakeParameters -ModulePath $module

    $Content = "        SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings`r`n"
    $Content += "        {`r`n"
    $results = Get-TargetResource @params
    $results = Repair-Credentials -results $results

    Add-ConfigurationDataEntry -Node "NonNodeData" -Key "LogPath" -Value $results.LogPath -Description "Path where the SharePoint ULS logs will be stored;"
    $results.LogPath = "`$ConfigurationData.NonNodeData.LogPath"

    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "LogPath"
    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
    $Content += $currentBlock
    $Content += "        }`r`n"
    return $Content
}

Export-ModuleMember -Function *-TargetResource
