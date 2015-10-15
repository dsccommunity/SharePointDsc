[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPDiagnosticLoggingSettings"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

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
            EventLogFloodProtectionEnabled = $true
            EventLogFloodProtectionThreshold = 10
            EventLogFloodProtectionTriggerPeriod = 5
            EventLogFloodProtectionQuietPeriod = 5
            EventLogFloodProtectionNotifyInterval = 5
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Context "Diagnostic configuration can not be loaded" {
            Mock Get-SPDiagnosticConfig { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Diagnostic configuration can be loaded and it is configured correctly" {
            Mock Get-SPDiagnosticConfig { return @{
                AppAnalyticsAutomaticUploadEnabled = $testParams.AppAnalyticsAutomaticUploadEnabled
                CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                ErrorReportingEnabled = $testParams.ErrorReportingEnabled
                ErrorReportingAutomaticUploadEnabled = $testParams.ErrorReportingAutomaticUploadEnabled
                DownloadErrorReportingUpdatesEnabled = $testParams.DownloadErrorReportingUpdatesEnabled
                DaysToKeepLogs = $testParams.DaysToKeepLogs
                LogMaxDiskSpaceUsageEnabled = $testParams.LogMaxDiskSpaceUsageEnabled
                LogDiskSpaceUsageGB = $testParams.LogSpaceInGB
                LogLocation = $testParams.LogPath
                LogCutInterval = $testParams.LogCutInterval
                EventLogFloodProtectionEnabled = $testParams.EventLogFloodProtectionEnabled
                EventLogFloodProtectionThreshold = $testParams.EventLogFloodProtectionThreshold
                EventLogFloodProtectionTriggerPeriod = $testParams.EventLogFloodProtectionTriggerPeriod
                EventLogFloodProtectionQuietPeriod = $testParams.EventLogFloodProtectionQuietPeriod
                EventLogFloodProtectionNotifyInterval = $testParams.EventLogFloodProtectionNotifyInterval
                ScriptErrorReportingEnabled = $testParams.ScriptErrorReportingEnabled
                ScriptErrorReportingRequireAuth = $testParams.ScriptErrorReportingRequireAuth
                ScriptErrorReportingDelay = $testParams.ScriptErrorReportingDelay
            } }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Diagnostic configuration can be loaded and the log path is not set correctly" {
            Mock Get-SPDiagnosticConfig { return @{
                AppAnalyticsAutomaticUploadEnabled = $testParams.AppAnalyticsAutomaticUploadEnabled
                CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                ErrorReportingEnabled = $testParams.ErrorReportingEnabled
                ErrorReportingAutomaticUploadEnabled = $testParams.ErrorReportingAutomaticUploadEnabled
                DownloadErrorReportingUpdatesEnabled = $testParams.DownloadErrorReportingUpdatesEnabled
                DaysToKeepLogs = $testParams.DaysToKeepLogs
                LogMaxDiskSpaceUsageEnabled = $testParams.LogMaxDiskSpaceUsageEnabled
                LogDiskSpaceUsageGB = $testParams.LogSpaceInGB
                LogLocation = "C:\incorrect\value"
                LogCutInterval = $testParams.LogCutInterval
                EventLogFloodProtectionEnabled = $testParams.EventLogFloodProtectionEnabled
                EventLogFloodProtectionThreshold = $testParams.EventLogFloodProtectionThreshold
                EventLogFloodProtectionTriggerPeriod = $testParams.EventLogFloodProtectionTriggerPeriod
                EventLogFloodProtectionQuietPeriod = $testParams.EventLogFloodProtectionQuietPeriod
                EventLogFloodProtectionNotifyInterval = $testParams.EventLogFloodProtectionNotifyInterval
                ScriptErrorReportingEnabled = $testParams.ScriptErrorReportingEnabled
                ScriptErrorReportingRequireAuth = $testParams.ScriptErrorReportingRequireAuth
                ScriptErrorReportingDelay = $testParams.ScriptErrorReportingDelay
            } }


            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Diagnostic configuration can be loaded and the log size is not set correctly" {
            Mock Get-SPDiagnosticConfig { return @{
                AppAnalyticsAutomaticUploadEnabled = $testParams.AppAnalyticsAutomaticUploadEnabled
                CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                ErrorReportingEnabled = $testParams.ErrorReportingEnabled
                ErrorReportingAutomaticUploadEnabled = $testParams.ErrorReportingAutomaticUploadEnabled
                DownloadErrorReportingUpdatesEnabled = $testParams.DownloadErrorReportingUpdatesEnabled
                DaysToKeepLogs = $testParams.DaysToKeepLogs
                LogMaxDiskSpaceUsageEnabled = $testParams.LogMaxDiskSpaceUsageEnabled
                LogDiskSpaceUsageGB = 1
                LogLocation = $testParams.LogPath
                LogCutInterval = $testParams.LogCutInterval
                EventLogFloodProtectionEnabled = $testParams.EventLogFloodProtectionEnabled
                EventLogFloodProtectionThreshold = $testParams.EventLogFloodProtectionThreshold
                EventLogFloodProtectionTriggerPeriod = $testParams.EventLogFloodProtectionTriggerPeriod
                EventLogFloodProtectionQuietPeriod = $testParams.EventLogFloodProtectionQuietPeriod
                EventLogFloodProtectionNotifyInterval = $testParams.EventLogFloodProtectionNotifyInterval
                ScriptErrorReportingEnabled = $testParams.ScriptErrorReportingEnabled
                ScriptErrorReportingRequireAuth = $testParams.ScriptErrorReportingRequireAuth
                ScriptErrorReportingDelay = $testParams.ScriptErrorReportingDelay
            } }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "repairs the diagnostic configuration" {
                Mock Set-SPDiagnosticConfig {}
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPDiagnosticConfig
            }
        }

        Context "Diagnostic configuration needs updating and the InstallAccount option is used" {
            $testParams.Add("InstallAccount", (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))) )

            Mock Get-SPDiagnosticConfig { return @{
                AppAnalyticsAutomaticUploadEnabled = $testParams.AppAnalyticsAutomaticUploadEnabled
                CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                ErrorReportingEnabled = $testParams.ErrorReportingEnabled
                ErrorReportingAutomaticUploadEnabled = $testParams.ErrorReportingAutomaticUploadEnabled
                DownloadErrorReportingUpdatesEnabled = $testParams.DownloadErrorReportingUpdatesEnabled
                DaysToKeepLogs = $testParams.DaysToKeepLogs
                LogMaxDiskSpaceUsageEnabled = $testParams.LogMaxDiskSpaceUsageEnabled
                LogDiskSpaceUsageGB = 1
                LogLocation = $testParams.LogPath
                LogCutInterval = $testParams.LogCutInterval
                EventLogFloodProtectionEnabled = $testParams.EventLogFloodProtectionEnabled
                EventLogFloodProtectionThreshold = $testParams.EventLogFloodProtectionThreshold
                EventLogFloodProtectionTriggerPeriod = $testParams.EventLogFloodProtectionTriggerPeriod
                EventLogFloodProtectionQuietPeriod = $testParams.EventLogFloodProtectionQuietPeriod
                EventLogFloodProtectionNotifyInterval = $testParams.EventLogFloodProtectionNotifyInterval
                ScriptErrorReportingEnabled = $testParams.ScriptErrorReportingEnabled
                ScriptErrorReportingRequireAuth = $testParams.ScriptErrorReportingRequireAuth
                ScriptErrorReportingDelay = $testParams.ScriptErrorReportingDelay
            } }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "repairs the diagnostic configuration" {
                Mock Set-SPDiagnosticConfig {}
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPDiagnosticConfig
            }
        }
    }    
}