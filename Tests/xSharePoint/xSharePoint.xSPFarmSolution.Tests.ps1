[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
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
            Verbose         = $true
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
            Mock WaitFor-SolutionJob { } -Verifiable

            $getResults = Get-TargetResource @testParams

            It "returns the expected empty values from the get method" {
                $getResults.Ensure | Should Be "Absent"
                $getResults.Version | Should Be "0.0.0.0"
                $getResults.Deployed | Should Be $false
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "uploads and installes the solution to the farm" {
                Set-TargetResource @testParams

                Assert-MockCalled Add-SPSolution 
                Assert-MockCalled Install-SPSolution
                Assert-MockCalled WaitFor-SolutionJob 
            }
        }

        Context "The solution is installed, but should not be"{

            $testParams.Ensure = "Absent"

            Mock Get-SPSolution {
                return [pscustomobject]@{
                    Deployed                = $true
                    Properties              = @{ Version = "1.0.0.0" }
                    DeployedWebApplications = @( [pscustomobject]@{Url="http://app1"}, [pscustomobject]@{Url="http://app2"})
                    ContainsGlobalAssembly  = $true
                }
            } -Verifiable

            Mock Uninstall-SPSolution { } -Verifiable
            Mock WaitFor-SolutionJob { } -Verifiable
            Mock Remove-SPSolution { } -Verifiable
            

            $getResults = Get-TargetResource @testParams

            It "returns the expected values from the get method" {
                $getResults.Ensure | Should Be "Present"
                $getResults.Version | Should Be "1.0.0.0"
                $getResults.Deployed | Should Be $true
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "uninstalles and removes the solution from the web apps and the farm" {
                Set-TargetResource @testParams

                Assert-MockCalled Uninstall-SPSolution
                Assert-MockCalled WaitFor-SolutionJob 
                Assert-MockCalled Remove-SPSolution 
            }
        }

        Context "The solution isn't installed, and should not be"{

            $testParams = @{
                Name            = "SomeSolution"
                LiteralPath     = "\\server\share\file.wsp"
                Deployed        = $false
                Ensure          = "Absent"
                Version         = "0.0.0.0"
                WebApplications = @()
            }

            Mock Get-SPSolution { $null } -Verifiable

            $getResults = Get-TargetResource @testParams

            It "returns the expected empty values from the get method" {
                $getResults.Ensure | Should Be "Absent"
                $getResults.Version | Should Be "0.0.0.0"
                $getResults.Deployed | Should Be $false
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The solution is installed, but needs update"{

            $testParams.Version = "1.1.0.0"
            $testParams.Ensure = "Present"

            Mock Get-SPSolution {
                $s = [pscustomobject]@{
                    Deployed                = $true
                    Properties              = @{ Version = "1.0.0.0" }
                    DeployedWebApplications = @( [pscustomobject]@{Url="http://app1"}, [pscustomobject]@{Url="http://app2"})
                    ContainsGlobalAssembly  = $true
                } 
                $s | Add-Member -Name Update -MemberType ScriptMethod  -Value { }
                return $s
            }        

            $getResults = Get-TargetResource @testParams

            Mock Update-SPSolution { } -Verifiable
            Mock WaitFor-SolutionJob { } -Verifiable
            Mock Install-SPFeature { } -Verifiable

            $getResults = Get-TargetResource @testParams

            It "returns the expected values from the get method" {
                $getResults.Ensure | Should Be "Present"
                $getResults.Version | Should Be "1.0.0.0"
                $getResults.Deployed | Should Be $true
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "updates the solution in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Update-SPSolution
                Assert-MockCalled Install-SPFeature
                Assert-MockCalled WaitFor-SolutionJob 
            }
        }

        Context "The solution is installed, and should be"{
            
            $testParams.Version = "1.0.0.0"
            $testParams.Ensure = "Present"

            Mock Get-SPSolution {
                return [pscustomobject]@{
                    Deployed                = $true
                    Properties              = @{ Version = "1.0.0.0" }
                    DeployedWebApplications = @( [pscustomobject]@{Url="http://app1"}, [pscustomobject]@{Url="http://app2"})
                    ContainsGlobalAssembly  = $true
                }
            }        

            $getResults = Get-TargetResource @testParams

            It "returns the expected values from the get method" {
                $getResults.Ensure | Should Be "Present"
                $getResults.Version | Should Be "1.0.0.0"
                $getResults.Deployed | Should Be $true
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The solution exists but is not deloyed, and needs update"{
        
            $testParams.Version = "1.1.0.0"
            $testParams.Ensure = "Present"

            $solution = [pscustomobject]@{
                    Deployed                = $false
                    Properties              = @{ Version = "1.0.0.0" }
                    DeployedWebApplications = @( [pscustomobject]@{Url="http://app1"}, [pscustomobject]@{Url="http://app2"})
                    ContainsGlobalAssembly  = $true
                } 
            $solution | Add-Member -Name Update -MemberType ScriptMethod  -Value { }

            Mock Get-SPSolution { $solution }      

            $getResults = Get-TargetResource @testParams

            Mock Remove-SPSolution { } -Verifiable
            Mock Add-SPSolution { $solution } -Verifiable

            Mock Install-SPSolution { } -Verifiable
            Mock WaitFor-SolutionJob { } -Verifiable

            $getResults = Get-TargetResource @testParams

            It "returns the expected values from the get method" {
                $getResults.Ensure | Should Be "Present"
                $getResults.Version | Should Be "1.0.0.0"
                $getResults.Deployed | Should Be $false
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "updates the solution in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Remove-SPSolution
                Assert-MockCalled Add-SPSolution
                Assert-MockCalled Install-SPSolution
                Assert-MockCalled WaitFor-SolutionJob 
            }
        }
    }   
}
