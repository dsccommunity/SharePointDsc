[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPTimerJobState"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPTimerJobState - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "job-spapp-statequery"
            Enabled = $true
            Schedule = "hourly between 0 and 59"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Context "The server is not part of SharePoint farm" {
            Mock Get-SPFarm { throw "Unable to detect local farm" }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Context "The server is in a farm and the incorrect enabled settings have been applied" {
            Mock Get-SPTimerJob {
                $returnVal = @{
                    Name = "job-spapp-statequery"
                    IsDisabled = $true
                    Schedule = "hourly between 0 and 59"
                }
                return @($returnVal)
            }
            Mock Set-SPTimerJob { return $null }
            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "updates the timerjob settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPTimerJob
            }
        }

        Context "The server is in a farm and the incorrect schedule settings have been applied" {
            Mock Get-SPTimerJob {
                $returnVal = @{
                    Name = "job-spapp-statequery"
                    IsDisabled = $false
                    Schedule = "weekly at sat 23:00:00"
                }
                return @($returnVal)
            }
            Mock Set-SPTimerJob { return $null }
            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "updates the timer job settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPTimerJob
            }
        }

        Context "The server is in a farm and the incorrect schedule format has been used" {
            Mock Get-SPTimerJob {
                $returnVal = @{
                    Name = "job-spapp-statequery"
                    IsDisabled = $false
                    Schedule = "incorrect format"
                }
                return @($returnVal)
            }
            Mock Set-SPTimerJob { throw "Invalid Time: `"The time given was not given in the proper format. See: Get-Help Set-SPTimerJob -detailed`"" }
            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws an exception because the incorrect schedule format is used" {
                { Set-TargetResource @testParams } | Should throw "Incorrect schedule format used. New schedule will not be applied."
            }
        }

        Context "The server is in a farm and the correct settings have been applied" {
            Mock Get-SPTimerJob {
                $returnVal = @{
                    Name = "job-spapp-statequery"
                    IsDisabled = $false
                    Schedule = "hourly between 0 and 59"
                }
                return @($returnVal)
            }
            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}
