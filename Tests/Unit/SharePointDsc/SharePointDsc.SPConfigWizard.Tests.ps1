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

            Mock Start-Process { @{ ExitCode = 0 }}

            It "return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "runs Start-Process in the set method" {
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

            It "return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "runs Start-Process in the set method" {
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

            It "return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "runs Start-Process in the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context "Current date outside Upgrade Time" {
            $testParams = @{
                Ensure              = "Present"
                DatabaseUpgradeDays = "mon"
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

            It "return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "runs Start-Process in the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
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

            It "return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throw exception in the set method" {
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

            It "return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "returns null from the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }
    }
}
