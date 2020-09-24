[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPDiagnosticLoggingSettings'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Mocks for all contexts
                Mock -CommandName Set-SPDiagnosticConfig -MockWith { }
            }

            # Test contexts
            Context -Name "Diagnostic configuration can not be loaded" {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance                            = "Yes"
                        LogPath                                     = "L:\ULSLogs"
                        LogSpaceInGB                                = 10
                        AppAnalyticsAutomaticUploadEnabled          = $true
                        CustomerExperienceImprovementProgramEnabled = $true
                        ErrorReportingEnabled                       = $true
                        ErrorReportingAutomaticUploadEnabled        = $true
                        DownloadErrorReportingUpdatesEnabled        = $true
                        DaysToKeepLogs                              = 7
                        LogMaxDiskSpaceUsageEnabled                 = $true
                        LogCutInterval                              = 30
                        ScriptErrorReportingEnabled                 = $true
                        ScriptErrorReportingRequireAuth             = $true
                        ScriptErrorReportingDelay                   = 5
                        EventLogFloodProtectionEnabled              = $true
                        EventLogFloodProtectionThreshold            = 10
                        EventLogFloodProtectionTriggerPeriod        = 5
                        EventLogFloodProtectionQuietPeriod          = 5
                        EventLogFloodProtectionNotifyInterval       = 5
                    }

                    Mock -CommandName Get-SPDiagnosticConfig -MockWith {
                        return $null
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).LogPath | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Diagnostic configuration can be loaded and it is configured correctly" {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance                            = "Yes"
                        LogPath                                     = "L:\ULSLogs"
                        LogSpaceInGB                                = 10
                        AppAnalyticsAutomaticUploadEnabled          = $true
                        CustomerExperienceImprovementProgramEnabled = $true
                        ErrorReportingEnabled                       = $true
                        ErrorReportingAutomaticUploadEnabled        = $true
                        DownloadErrorReportingUpdatesEnabled        = $true
                        DaysToKeepLogs                              = 7
                        LogMaxDiskSpaceUsageEnabled                 = $true
                        LogCutInterval                              = 30
                        ScriptErrorReportingEnabled                 = $true
                        ScriptErrorReportingRequireAuth             = $true
                        ScriptErrorReportingDelay                   = 5
                        EventLogFloodProtectionEnabled              = $true
                        EventLogFloodProtectionThreshold            = 10
                        EventLogFloodProtectionTriggerPeriod        = 5
                        EventLogFloodProtectionQuietPeriod          = 5
                        EventLogFloodProtectionNotifyInterval       = 5
                    }

                    Mock -CommandName Get-SPDiagnosticConfig -MockWith {
                        return @{
                            AppAnalyticsAutomaticUploadEnabled          = $testParams.AppAnalyticsAutomaticUploadEnabled
                            CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                            ErrorReportingEnabled                       = $testParams.ErrorReportingEnabled
                            ErrorReportingAutomaticUploadEnabled        = $testParams.ErrorReportingAutomaticUploadEnabled
                            DownloadErrorReportingUpdatesEnabled        = $testParams.DownloadErrorReportingUpdatesEnabled
                            DaysToKeepLogs                              = $testParams.DaysToKeepLogs
                            LogMaxDiskSpaceUsageEnabled                 = $testParams.LogMaxDiskSpaceUsageEnabled
                            LogDiskSpaceUsageGB                         = $testParams.LogSpaceInGB
                            LogLocation                                 = $testParams.LogPath
                            LogCutInterval                              = $testParams.LogCutInterval
                            EventLogFloodProtectionEnabled              = $testParams.EventLogFloodProtectionEnabled
                            EventLogFloodProtectionThreshold            = $testParams.EventLogFloodProtectionThreshold
                            EventLogFloodProtectionTriggerPeriod        = $testParams.EventLogFloodProtectionTriggerPeriod
                            EventLogFloodProtectionQuietPeriod          = $testParams.EventLogFloodProtectionQuietPeriod
                            EventLogFloodProtectionNotifyInterval       = $testParams.EventLogFloodProtectionNotifyInterval
                            ScriptErrorReportingEnabled                 = $testParams.ScriptErrorReportingEnabled
                            ScriptErrorReportingRequireAuth             = $testParams.ScriptErrorReportingRequireAuth
                            ScriptErrorReportingDelay                   = $testParams.ScriptErrorReportingDelay
                        }
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Diagnostic configuration can be loaded and the log path is not set correctly" {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance                            = "Yes"
                        LogPath                                     = "L:\ULSLogs"
                        LogSpaceInGB                                = 10
                        AppAnalyticsAutomaticUploadEnabled          = $true
                        CustomerExperienceImprovementProgramEnabled = $true
                        ErrorReportingEnabled                       = $true
                        ErrorReportingAutomaticUploadEnabled        = $true
                        DownloadErrorReportingUpdatesEnabled        = $true
                        DaysToKeepLogs                              = 7
                        LogMaxDiskSpaceUsageEnabled                 = $true
                        LogCutInterval                              = 30
                        ScriptErrorReportingEnabled                 = $true
                        ScriptErrorReportingRequireAuth             = $true
                        ScriptErrorReportingDelay                   = 5
                        EventLogFloodProtectionEnabled              = $true
                        EventLogFloodProtectionThreshold            = 10
                        EventLogFloodProtectionTriggerPeriod        = 5
                        EventLogFloodProtectionQuietPeriod          = 5
                        EventLogFloodProtectionNotifyInterval       = 5
                    }

                    Mock -CommandName Get-SPDiagnosticConfig -MockWith {
                        return @{
                            AppAnalyticsAutomaticUploadEnabled          = $testParams.AppAnalyticsAutomaticUploadEnabled
                            CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                            ErrorReportingEnabled                       = $testParams.ErrorReportingEnabled
                            ErrorReportingAutomaticUploadEnabled        = $testParams.ErrorReportingAutomaticUploadEnabled
                            DownloadErrorReportingUpdatesEnabled        = $testParams.DownloadErrorReportingUpdatesEnabled
                            DaysToKeepLogs                              = $testParams.DaysToKeepLogs
                            LogMaxDiskSpaceUsageEnabled                 = $testParams.LogMaxDiskSpaceUsageEnabled
                            LogDiskSpaceUsageGB                         = $testParams.LogSpaceInGB
                            LogLocation                                 = "C:\incorrect\value"
                            LogCutInterval                              = $testParams.LogCutInterval
                            EventLogFloodProtectionEnabled              = $testParams.EventLogFloodProtectionEnabled
                            EventLogFloodProtectionThreshold            = $testParams.EventLogFloodProtectionThreshold
                            EventLogFloodProtectionTriggerPeriod        = $testParams.EventLogFloodProtectionTriggerPeriod
                            EventLogFloodProtectionQuietPeriod          = $testParams.EventLogFloodProtectionQuietPeriod
                            EventLogFloodProtectionNotifyInterval       = $testParams.EventLogFloodProtectionNotifyInterval
                            ScriptErrorReportingEnabled                 = $testParams.ScriptErrorReportingEnabled
                            ScriptErrorReportingRequireAuth             = $testParams.ScriptErrorReportingRequireAuth
                            ScriptErrorReportingDelay                   = $testParams.ScriptErrorReportingDelay
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Diagnostic configuration can be loaded and the log size is not set correctly" {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance                            = "Yes"
                        LogPath                                     = "L:\ULSLogs"
                        LogSpaceInGB                                = 10
                        AppAnalyticsAutomaticUploadEnabled          = $true
                        CustomerExperienceImprovementProgramEnabled = $true
                        ErrorReportingEnabled                       = $true
                        ErrorReportingAutomaticUploadEnabled        = $true
                        DownloadErrorReportingUpdatesEnabled        = $true
                        DaysToKeepLogs                              = 7
                        LogMaxDiskSpaceUsageEnabled                 = $true
                        LogCutInterval                              = 30
                        ScriptErrorReportingEnabled                 = $true
                        ScriptErrorReportingRequireAuth             = $true
                        ScriptErrorReportingDelay                   = 5
                        EventLogFloodProtectionEnabled              = $true
                        EventLogFloodProtectionThreshold            = 10
                        EventLogFloodProtectionTriggerPeriod        = 5
                        EventLogFloodProtectionQuietPeriod          = 5
                        EventLogFloodProtectionNotifyInterval       = 5
                    }

                    Mock -CommandName Get-SPDiagnosticConfig -MockWith {
                        return @{
                            AppAnalyticsAutomaticUploadEnabled          = $testParams.AppAnalyticsAutomaticUploadEnabled
                            CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                            ErrorReportingEnabled                       = $testParams.ErrorReportingEnabled
                            ErrorReportingAutomaticUploadEnabled        = $testParams.ErrorReportingAutomaticUploadEnabled
                            DownloadErrorReportingUpdatesEnabled        = $testParams.DownloadErrorReportingUpdatesEnabled
                            DaysToKeepLogs                              = $testParams.DaysToKeepLogs
                            LogMaxDiskSpaceUsageEnabled                 = $testParams.LogMaxDiskSpaceUsageEnabled
                            LogDiskSpaceUsageGB                         = 1
                            LogLocation                                 = $testParams.LogPath
                            LogCutInterval                              = $testParams.LogCutInterval
                            EventLogFloodProtectionEnabled              = $testParams.EventLogFloodProtectionEnabled
                            EventLogFloodProtectionThreshold            = $testParams.EventLogFloodProtectionThreshold
                            EventLogFloodProtectionTriggerPeriod        = $testParams.EventLogFloodProtectionTriggerPeriod
                            EventLogFloodProtectionQuietPeriod          = $testParams.EventLogFloodProtectionQuietPeriod
                            EventLogFloodProtectionNotifyInterval       = $testParams.EventLogFloodProtectionNotifyInterval
                            ScriptErrorReportingEnabled                 = $testParams.ScriptErrorReportingEnabled
                            ScriptErrorReportingRequireAuth             = $testParams.ScriptErrorReportingRequireAuth
                            ScriptErrorReportingDelay                   = $testParams.ScriptErrorReportingDelay
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should repair the diagnostic configuration" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPDiagnosticConfig
                }
            }

            Context -Name "Diagnostic configuration needs updating and the InstallAccount option is used" {
                BeforeAll {
                    $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                    $mockAccount = New-Object -TypeName "System.Management.Automation.PSCredential" `
                        -ArgumentList @("username", $mockPassword)
                    $testParams = @{
                        IsSingleInstance                            = "Yes"
                        LogPath                                     = "L:\ULSLogs"
                        LogSpaceInGB                                = 10
                        AppAnalyticsAutomaticUploadEnabled          = $true
                        CustomerExperienceImprovementProgramEnabled = $true
                        ErrorReportingEnabled                       = $true
                        ErrorReportingAutomaticUploadEnabled        = $true
                        DownloadErrorReportingUpdatesEnabled        = $true
                        DaysToKeepLogs                              = 7
                        LogMaxDiskSpaceUsageEnabled                 = $true
                        LogCutInterval                              = 30
                        ScriptErrorReportingEnabled                 = $true
                        ScriptErrorReportingRequireAuth             = $true
                        ScriptErrorReportingDelay                   = 5
                        EventLogFloodProtectionEnabled              = $true
                        EventLogFloodProtectionThreshold            = 10
                        EventLogFloodProtectionTriggerPeriod        = 5
                        EventLogFloodProtectionQuietPeriod          = 5
                        EventLogFloodProtectionNotifyInterval       = 5
                        InstallAccount                              = $mockAccount
                    }

                    Mock -CommandName Get-SPDiagnosticConfig -MockWith {
                        return @{
                            AppAnalyticsAutomaticUploadEnabled          = $testParams.AppAnalyticsAutomaticUploadEnabled
                            CustomerExperienceImprovementProgramEnabled = $testParams.CustomerExperienceImprovementProgramEnabled
                            ErrorReportingEnabled                       = $testParams.ErrorReportingEnabled
                            ErrorReportingAutomaticUploadEnabled        = $testParams.ErrorReportingAutomaticUploadEnabled
                            DownloadErrorReportingUpdatesEnabled        = $testParams.DownloadErrorReportingUpdatesEnabled
                            DaysToKeepLogs                              = $testParams.DaysToKeepLogs
                            LogMaxDiskSpaceUsageEnabled                 = $testParams.LogMaxDiskSpaceUsageEnabled
                            LogDiskSpaceUsageGB                         = 1
                            LogLocation                                 = $testParams.LogPath
                            LogCutInterval                              = $testParams.LogCutInterval
                            EventLogFloodProtectionEnabled              = $testParams.EventLogFloodProtectionEnabled
                            EventLogFloodProtectionThreshold            = $testParams.EventLogFloodProtectionThreshold
                            EventLogFloodProtectionTriggerPeriod        = $testParams.EventLogFloodProtectionTriggerPeriod
                            EventLogFloodProtectionQuietPeriod          = $testParams.EventLogFloodProtectionQuietPeriod
                            EventLogFloodProtectionNotifyInterval       = $testParams.EventLogFloodProtectionNotifyInterval
                            ScriptErrorReportingEnabled                 = $testParams.ScriptErrorReportingEnabled
                            ScriptErrorReportingRequireAuth             = $testParams.ScriptErrorReportingRequireAuth
                            ScriptErrorReportingDelay                   = $testParams.ScriptErrorReportingDelay
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should repair the diagnostic configuration" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPDiagnosticConfig
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
