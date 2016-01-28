[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPFarmSolution"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPFarmSolution" {
    
    InModuleScope $ModuleName {
    
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }

        $testParams = @{
            Name            = "SomeSolution"
            LiteralPath     = "\\server\share\file.wsp"
            Deployed        = $true
            Ensure          = "Present"
            Version         = "1.0.0.0"
            WebApplications = @("http://app1", "http://app2")
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Context "The solution isn't installed, but should be" {
            $global:SolutionAdded = $false
            Mock Get-SPSolution { 
                if ($global:SolutionAdded) { 
                    return [pscustomobject] @{ } 
                }else{
                    return $null 
                }
            } -Verifiable
            Mock Add-SPSolution { 
                $solution = [pscustomobject] @{ Properties = @{ Version = "" }}
                $solution | Add-Member -Name Update -MemberType ScriptMethod  -Value { }
                $global:SolutionAdded = $true
                return $solution
            } -Verifiable
            Mock Install-SPSolution { } -Verifiable
            Mock WaitFor-SolutionJob { }

            $getResults = Get-TargetResource @testParams

            It "returns Ensure 'Absent' from the get method" {
                $getResults.Ensure | Should Be "Absent"
            }

            It "returns Version '0.0.0.0' from the get method" {
                $getResults.Version | Should Be "0.0.0.0"
            }

            It "returns Deployed 'false' from the get method" {
                $getResults.Deployed | Should Be $false
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "uploads the solution to the farm" {
                Set-TargetResource @testParams

                Assert-MockCalled Add-SPSolution 
            }
        }

        Context "The solution is installed, but should not be"{
        }

        Context "The solution isn't installed, and should not be"{
        }

        Context "The solution is installed, but needs update"{
        }

        Context "The solution is installed, and should be"{
        }
    }   
}
