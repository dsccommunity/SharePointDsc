[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPDiagnosticLoggingSettings"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "xSPDiagnosticLoggingSettings" {
    InModuleScope $ModuleName {
        $testParams = @{
            LogPath = "L:\ULSLogs"
            LogSpaceInGB = 10
            AppAnalyticsAutomaticUploadEnabled = $true
            CustomerExperienceImprovementProgramEnabled = $true
            ErrorReportingEnabled = $true
            ErrorReportingAutomaticUploadEnabled = $true
            DownloadErrorReportingUpdatesEnabled = $true
            DaysToKeepLogs = 7
            LogMaxDiskSpaceUsageEnabled = $true
            LogCutInterval = 30
            ScriptErrorReportingEnabled = $true
            ScriptErrorReportingRequireAuth = $true
            ScriptErrorReportingDelay = 5
        }

        Context "Validate get method" {
            It "Calls the correct function to retrieve settings" {
                Mock Invoke-xSharePointSPCmdlet { return @{}} -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPDiagnosticConfig" }
                Get-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails logging settings can not be found" {
                Mock Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when logging settings are applied correctly" {
                Mock Get-TargetResource { 
                    return @{
                        AppAnalyticsAutomaticUploadEnabled = $testParams.AppAnalyticsAutomaticUploadEnabled
                        CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                        ErrorReportingEnabled = $testParams.ErrorReportingEnabled
                        ErrorReportingAutomaticUploadEnabled = $testParams.ErrorReportingAutomaticUploadEnabled
                        DownloadErrorReportingUpdatesEnabled = $testParams.DownloadErrorReportingUpdatesEnabled
                        DaysToKeepLogs = $testParams.DaysToKeepLogs
                        LogMaxDiskSpaceUsageEnabled = $testParams.LogMaxDiskSpaceUsageEnabled
                        LogSpaceInGB = $testParams.LogSpaceInGB
                        LogPath = $testParams.LogPath
                        LogCutInterval = $testParams.LogCutInterval
                        ScriptErrorReportingEnabled = $testParams.ScriptErrorReportingEnabled
                        ScriptErrorReportingRequireAuth = $testParams.ScriptErrorReportingRequireAuth
                        ScriptErrorReportingDelay = $testParams.ScriptErrorReportingDelay
                        InstallAccount = $null
                    }
                }
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when disk location is incorrect" {
                Mock Get-TargetResource { 
                    return @{
                        AppAnalyticsAutomaticUploadEnabled = $testParams.AppAnalyticsAutomaticUploadEnabled
                        CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                        ErrorReportingEnabled = $testParams.ErrorReportingEnabled
                        ErrorReportingAutomaticUploadEnabled = $testParams.ErrorReportingAutomaticUploadEnabled
                        DownloadErrorReportingUpdatesEnabled = $testParams.DownloadErrorReportingUpdatesEnabled
                        DaysToKeepLogs = $testParams.DaysToKeepLogs
                        LogMaxDiskSpaceUsageEnabled = $testParams.LogMaxDiskSpaceUsageEnabled
                        LogSpaceInGB = $testParams.LogSpaceInGB
                        LogPath = "C:\logs"
                        LogCutInterval = $testParams.LogCutInterval
                        EventLogFloodProtectionEnabled = $testParams.EventLogFloodProtectionEnabled
                        EventLogFloodProtectionThreshold = $testParams.EventLogFloodProtectionThreshold
                        EventLogFloodProtectionTriggerPeriod = $testParams.EventLogFloodProtectionTriggerPeriod
                        EventLogFloodProtectionQuietPeriod = $testParams.EventLogFloodProtectionQuietPeriod
                        EventLogFloodProtectionNotifyInterval = $testParams.EventLogFloodProtectionNotifyInterval
                        ScriptErrorReportingEnabled = $testParams.ScriptErrorReportingEnabled
                        ScriptErrorReportingRequireAuth = $testParams.ScriptErrorReportingRequireAuth
                        ScriptErrorReportingDelay = $testParams.ScriptErrorReportingDelay
                    }
                }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Fails when log size is incorrect" {
                Mock Get-TargetResource { 
                    return @{
                        AppAnalyticsAutomaticUploadEnabled = $testParams.AppAnalyticsAutomaticUploadEnabled
                        CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                        ErrorReportingEnabled = $testParams.ErrorReportingEnabled
                        ErrorReportingAutomaticUploadEnabled = $testParams.ErrorReportingAutomaticUploadEnabled
                        DownloadErrorReportingUpdatesEnabled = $testParams.DownloadErrorReportingUpdatesEnabled
                        DaysToKeepLogs = $testParams.DaysToKeepLogs
                        LogMaxDiskSpaceUsageEnabled = $testParams.LogMaxDiskSpaceUsageEnabled
                        LogSpaceInGB = 1
                        LogPath = $testParams.LogPath
                        LogCutInterval = $testParams.LogCutInterval
                        EventLogFloodProtectionEnabled = $testParams.EventLogFloodProtectionEnabled
                        EventLogFloodProtectionThreshold = $testParams.EventLogFloodProtectionThreshold
                        EventLogFloodProtectionTriggerPeriod = $testParams.EventLogFloodProtectionTriggerPeriod
                        EventLogFloodProtectionQuietPeriod = $testParams.EventLogFloodProtectionQuietPeriod
                        EventLogFloodProtectionNotifyInterval = $testParams.EventLogFloodProtectionNotifyInterval
                        ScriptErrorReportingEnabled = $testParams.ScriptErrorReportingEnabled
                        ScriptErrorReportingRequireAuth = $testParams.ScriptErrorReportingRequireAuth
                        ScriptErrorReportingDelay = $testParams.ScriptErrorReportingDelay
                    }
                }
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Calls the correct function to retrieve settings" {
                Mock Invoke-xSharePointSPCmdlet { return @{}} -Verifiable -ParameterFilter { $CmdletName -eq "Set-SPDiagnosticConfig" -and $Arguments.ContainsKey("InstallAccount") -eq $false }
                Set-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }
    }    
}