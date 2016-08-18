[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPConfigWizard"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPConfigWizard - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Ensure               = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")

        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))
        Mock Get-SPDSCInstalledProductVersion { return @{ FileMajorPart = $majorBuildNumber } }

        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Context "Upgrade required for Language Pack" {
            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "LanguagePackInstalled")
                {
                    return 1
                }
            }

            Mock Start-Process { return @{ ExitCode = 0 }}

            It "should return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should run Start-Process in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }
        }

        Context "Upgrade required for Cumulative Update" {
            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            Mock Start-Process { @{ ExitCode = 0 }}

            It "should return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should run Start-Process in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }
        }

        Context "Current date outside Upgrade Days" {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "mon"
            }
            
            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }

            It "should return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should run Start-Process in the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context "Current date outside Upgrade Time" {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "3:00am to 5:00am"
            }
            
            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }

            It "should return null from the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context "Upgrade Time incorrectly formatted" {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "error 3:00am to 5:00am"
            }
            
            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }

            It "should return exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw "Time window incorrectly formatted."
            }
        }

        Context "Start time Upgrade Time incorrectly formatted" {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "3:00xm to 5:00am"
            }
            
            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }

            It "should return exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error converting start time"
            }
        }

        Context "End time Upgrade Time incorrectly formatted" {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "3:00am to 5:00xm"
            }
            
            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }

            It "should return exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error converting end time"
            }
        }

        Context "Start time of Upgrade Time larger than end time" {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "sun"
                DatabaseUpgradeTime = "3:00pm to 5:00am"
            }
            
            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "B2B_UPGRADE"
                }
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }

            It "should return exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error: Start time cannot be larger than end time"
            }
        }

        Context "ExitCode of process is not 0" {
            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "LanguagePackInstalled")
                {
                    return 1
                }
            }

            Mock Start-Process { @{ ExitCode = -1 }}

            It "should return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SharePoint Post Setup Configuration Wizard failed, exit code was"
            }
        }

        Context "Ensure is set to Absent, Config Wizard not required" {
            $testParams = @{
                Ensure = "Absent"
            }

            Mock Get-SPDSCRegistryKey {
                return 0
            }

            Mock Start-Process { @{ ExitCode = 0 }}

            It "should return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "should return null from the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }
    }
}
