[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPConfigWizard"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Test contexts
        Context -Name "Upgrade required for Language Pack" -Fixture {
            $testParams = @{
                Ensure = "Present"
            }

            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
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

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should run Start-Process in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }
        }

        Context -Name "Upgrade required for Cumulative Update" -Fixture {
            $testParams = @{
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
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

            It "Should return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should run Start-Process in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }
        }

        Context -Name "Current date outside Upgrade Days" -Fixture {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "mon"
            }
            
            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
            Mock -CommandName Get-Date -MockWith {
                 return $testDate 
            }

            It "Should return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should run Start-Process in the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context -Name "Current date outside Upgrade Time" -Fixture {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "3:00am to 5:00am"
            }
            
            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
            Mock -CommandName Get-Date -MockWith {
                 return $testDate
            }

            It "Should return null from the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context -Name "Upgrade Time incorrectly formatted" -Fixture {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "error 3:00am to 5:00am"
            }
            
            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
            Mock -CommandName Get-Date -MockWith {
                 return $testDate 
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw "Time window incorrectly formatted."
            }
        }

        Context -Name "Start time Upgrade Time incorrectly formatted" -Fixture {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "3:00xm to 5:00am"
            }
            
            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
            Mock -CommandName Get-Date -MockWith {
                 return $testDate 
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error converting start time"
            }
        }

        Context -Name "End time Upgrade Time incorrectly formatted" -Fixture {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "3:00am to 5:00xm"
            }
            
            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
            Mock -CommandName Get-Date -MockWith {
                 return $testDate
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error converting end time"
            }
        }

        Context -Name "Start time of Upgrade Time larger than end time" -Fixture {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "3:00pm to 5:00am"
            }
            
            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00
            Mock -CommandName Get-Date -MockWith {
                 return $testDate 
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error: Start time cannot be larger than end time"
            }
        }

        Context -Name "ExitCode of process is not 0" -Fixture {
            $testParams = @{
                Ensure              = "Present"
            }

            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
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

            It "Should return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SharePoint Post Setup Configuration Wizard failed, exit code was"
            }
        }

        Context -Name "Ensure is set to Absent, Config Wizard not required" -Fixture {
            $testParams = @{
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
                return 0
            }

            Mock -CommandName Start-Process -MockWith { 
                return @{ 
                    ExitCode = 0 
                }
            }

            It "Should return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should return null from the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
