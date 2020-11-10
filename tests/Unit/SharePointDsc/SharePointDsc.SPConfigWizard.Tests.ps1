[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPConfigWizard'
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
                Mock -CommandName Start-Sleep -MockWith { }
                Mock -CommandName Start-SPTimerJob -MockWith { }
                Mock -CommandName Get-SPTimerJob -MockWith {
                    return @{
                        LastRunTime = Get-Date
                    }
                }

                Mock -CommandName Remove-Item -MockWith { }
                Mock -CommandName Get-Content -MockWith { return "log info" }
                Mock -CommandName Get-SPDscServerPatchStatus -MockWith { return "UpgradeRequired" }

                function Add-SPDscEvent
                {
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType,

                        [Parameter()]
                        [System.UInt32]
                        $EventID
                    )
                }
            }

            # Test contexts
            Context -Name "Upgrade required for Language Pack" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "LanguagePackInstalled")
                        {
                            return 1
                        }
                    }

                    Mock -CommandName Start-Process -MockWith {
                        return @{
                            ExitCode = 0
                        }
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run Start-Process in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context -Name "Upgrade required for Cumulative Update" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "SetupType")
                        {
                            return "B2B_UPGRADE"
                        }
                    }

                    Mock -CommandName Start-Process -MockWith {
                        return @{
                            ExitCode = 0
                        }
                    }
                }

                It "Should return Ensure=Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run Start-Process in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context -Name "Config wizard should not be run, because not all servers have the binaries installed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "SetupType")
                        {
                            return "B2B_UPGRADE"
                        }
                    }

                    Mock -CommandName Get-SPDscServerPatchStatus -MockWith { return "UpgradeBlocked" }

                    Mock -CommandName Start-Process -MockWith { }
                }

                It "Should run Start-Process in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process -Times 0
                }
            }

            Context -Name "Current date outside Upgrade Days" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance    = "Yes"
                        DatabaseUpgradeDays = "mon"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "SetupType")
                        {
                            return "B2B_UPGRADE"
                        }
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return Ensure=Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run Start-Process in the set method" {
                    Set-TargetResource @testParams | Should -BeNullOrEmpty
                }
            }

            Context -Name "Current date outside Upgrade Time" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance    = "Yes"
                        DatabaseUpgradeDays = "sun"
                        DatabaseUpgradeTime = "3:00am to 5:00am"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "SetupType")
                        {
                            return "B2B_UPGRADE"
                        }
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return null from the set method" {
                    Set-TargetResource @testParams | Should -BeNullOrEmpty
                }
            }

            Context -Name "Upgrade Time incorrectly formatted" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance    = "Yes"
                        DatabaseUpgradeDays = "sun"
                        DatabaseUpgradeTime = "error 3:00am to 5:00am"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "SetupType")
                        {
                            return "B2B_UPGRADE"
                        }
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Time window incorrectly formatted."
                }
            }

            Context -Name "Start time Upgrade Time incorrectly formatted" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance    = "Yes"
                        DatabaseUpgradeDays = "sun"
                        DatabaseUpgradeTime = "3:00xm to 5:00am"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "SetupType")
                        {
                            return "B2B_UPGRADE"
                        }
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error converting start time"
                }
            }

            Context -Name "End time Upgrade Time incorrectly formatted" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance    = "Yes"
                        DatabaseUpgradeDays = "sun"
                        DatabaseUpgradeTime = "3:00am to 5:00xm"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "SetupType")
                        {
                            return "B2B_UPGRADE"
                        }
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error converting end time"
                }
            }

            Context -Name "Start time of Upgrade Time larger than end time" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance    = "Yes"
                        DatabaseUpgradeDays = "sun"
                        DatabaseUpgradeTime = "3:00pm to 5:00am"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "SetupType")
                        {
                            return "B2B_UPGRADE"
                        }
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error: Start time cannot be larger than end time"
                }
            }

            Context -Name "ExitCode of process is not 0" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        if ($Value -eq "LanguagePackInstalled")
                        {
                            return 1
                        }
                    }

                    Mock -CommandName Start-Process -MockWith { return
                        @{
                            ExitCode = -1
                        }
                    }
                }

                It "Should return Ensure=Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "SharePoint Post Setup Configuration Wizard failed, exit code was"
                }
            }

            Context -Name "Ensure is set to Absent, Config Wizard not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Ensure           = "Absent"
                    }

                    Mock -CommandName Get-SPDscRegistryKey -MockWith {
                        return 0
                    }

                    Mock -CommandName Start-Process -MockWith {
                        return @{
                            ExitCode = 0
                        }
                    }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should return null from the set method" {
                    Set-TargetResource @testParams | Should -BeNullOrEmpty
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
