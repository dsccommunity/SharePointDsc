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
                                              -DscResource "SPFarmSolution"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName Update-SPSolution -MockWith { }
        Mock -CommandName Wait-SPDSCSolutionJob -MockWith { }
        Mock -CommandName Install-SPFeature -MockWith { }
        Mock -CommandName Install-SPSolution -MockWith { }
        Mock -CommandName Uninstall-SPSolution -MockWith { }
        Mock -CommandName Remove-SPSolution -MockWith { }

        # Test contexts
        Context -Name "The solution isn't installed, but should be" -Fixture {
            $testParams = @{
                Name            = "SomeSolution"
                LiteralPath     = "\\server\share\file.wsp"
                Deployed        = $true
                Ensure          = "Present"
                Version         = "1.0.0.0"
                WebApplications = @("http://app1", "http://app2")
            }

            $global:SPDscSolutionAdded = $false

            Mock -CommandName Get-SPSolution -MockWith { 
                if ($global:SPDscSolutionAdded)
                { 
                    return [pscustomobject] @{ } 
                }
                else
                {
                    return $null 
                }
            }

            Mock -CommandName Add-SPSolution -MockWith { 
                $solution = [pscustomobject] @{ Properties = @{ Version = "" }}
                $solution | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                $global:SPDscSolutionAdded = $true
                return $solution
            }

            $getResults = Get-TargetResource @testParams

            It "Should return the expected empty values from the get method" {
                $getResults.Ensure | Should Be "Absent"
                $getResults.Version | Should Be "0.0.0.0"
                $getResults.Deployed | Should Be $false
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "uploads and installes the solution to the farm" {
                Set-TargetResource @testParams

                Assert-MockCalled Add-SPSolution 
                Assert-MockCalled Install-SPSolution
                Assert-MockCalled Wait-SPDSCSolutionJob 
            }
        }

        Context -Name "The solution is installed, but should not be" -Fixture {
            $testParams = @{
                Name            = "SomeSolution"
                LiteralPath     = "\\server\share\file.wsp"
                Deployed        = $true
                Ensure          = "Absent"
                Version         = "1.0.0.0"
                WebApplications = @("http://app1", "http://app2")
            }

            Mock -CommandName Get-SPSolution -MockWith {
                return [pscustomobject]@{
                    Deployed                = $true
                    Properties              = @{ Version = "1.0.0.0" }
                    DeployedWebApplications = @( [pscustomobject]@{Url="http://app1"}, [pscustomobject]@{Url="http://app2"})
                    ContainsGlobalAssembly  = $true
                }
            }

            $getResults = Get-TargetResource @testParams

            It "Should return the expected values from the get method" {
                $getResults.Ensure | Should Be "Present"
                $getResults.Version | Should Be "1.0.0.0"
                $getResults.Deployed | Should Be $true
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "uninstalles and removes the solution from the web apps and the farm" {
                Set-TargetResource @testParams

                Assert-MockCalled Uninstall-SPSolution
                Assert-MockCalled Wait-SPDSCSolutionJob 
                Assert-MockCalled Remove-SPSolution 
            }
        }

        Context -Name "The solution isn't installed, and should not be" -Fixture {
            $testParams = @{
                Name            = "SomeSolution"
                LiteralPath     = "\\server\share\file.wsp"
                Deployed        = $false
                Ensure          = "Absent"
                Version         = "0.0.0.0"
                WebApplications = @()
            }

            Mock -CommandName Get-SPSolution -MockWith { $null }

            $getResults = Get-TargetResource @testParams

            It "Should return the expected empty values from the get method" {
                $getResults.Ensure | Should Be "Absent"
                $getResults.Version | Should Be "0.0.0.0"
                $getResults.Deployed | Should Be $false
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The solution is installed, but needs update" -Fixture {
            $testParams = @{
                Name            = "SomeSolution"
                LiteralPath     = "\\server\share\file.wsp"
                Deployed        = $true
                Ensure          = "Present"
                Version         = "1.1.0.0"
                WebApplications = @("http://app1", "http://app2")
            }

            Mock -CommandName Get-SPSolution -MockWith {
                $s = [pscustomobject]@{
                    Deployed                = $true
                    Properties              = @{ Version = "1.0.0.0" }
                    DeployedWebApplications = @( [pscustomobject]@{Url="http://app1"}, [pscustomobject]@{Url="http://app2"})
                    ContainsGlobalAssembly  = $true
                } 
                $s | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                return $s
            }        

            $getResults = Get-TargetResource @testParams

            It "Should return the expected values from the get method" {
                $getResults.Ensure | Should Be "Present"
                $getResults.Version | Should Be "1.0.0.0"
                $getResults.Deployed | Should Be $true
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the solution in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Update-SPSolution
                Assert-MockCalled Install-SPFeature
                Assert-MockCalled Wait-SPDSCSolutionJob 
            }
        }

        Context -Name "The solution is installed, and should be" -Fixture {
            $testParams = @{
                Name            = "SomeSolution"
                LiteralPath     = "\\server\share\file.wsp"
                Deployed        = $true
                Ensure          = "Present"
                Version         = "1.0.0.0"
                WebApplications = @("http://app1", "http://app2")
            }
        
            Mock -CommandName Get-SPSolution -MockWith {
                return [pscustomobject]@{
                    Deployed                = $true
                    Properties              = @{ Version = "1.0.0.0" }
                    DeployedWebApplications = @( [pscustomobject]@{Url="http://app1"}, [pscustomobject]@{Url="http://app2"})
                    ContainsGlobalAssembly  = $true
                }
            }        

            $getResults = Get-TargetResource @testParams

            It "Should return the expected values from the get method" {
                $getResults.Ensure | Should Be "Present"
                $getResults.Version | Should Be "1.0.0.0"
                $getResults.Deployed | Should Be $true
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The solution exists but is not deloyed, and needs update" -Fixture {
            $testParams = @{
                Name            = "SomeSolution"
                LiteralPath     = "\\server\share\file.wsp"
                Deployed        = $true
                Ensure          = "Present"
                Version         = "1.1.0.0"
                WebApplications = @()
            }

            $solution = [pscustomobject]@{
                    Deployed                = $false
                    Properties              = @{ Version = "1.0.0.0" }
                    DeployedWebApplications = @( [pscustomobject]@{Url="http://app1"}, [pscustomobject]@{Url="http://app2"})
                    ContainsGlobalAssembly  = $true
                } 
            $solution | Add-Member -Name Update -MemberType ScriptMethod  -Value { }

            Mock -CommandName Get-SPSolution -MockWith { $solution }
            Mock -CommandName Add-SPSolution -MockWith { $solution }

            $getResults = Get-TargetResource @testParams

            It "Should return the expected values from the get method" {
                $getResults.Ensure | Should Be "Present"
                $getResults.Version | Should Be "1.0.0.0"
                $getResults.Deployed | Should Be $false
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the solution in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Remove-SPSolution
                Assert-MockCalled Add-SPSolution
                Assert-MockCalled Install-SPSolution
                Assert-MockCalled Wait-SPDSCSolutionJob 
            }
        }

        Context -Name "A solution deployment can target a specific compatability level" -Fixture {
            $testParams = @{
                Name            = "SomeSolution"
                LiteralPath     = "\\server\share\file.wsp"
                Deployed        = $true
                Ensure          = "Present"
                Version         = "1.1.0.0"
                WebApplications = @()
                SolutionLevel   = "All"
            }

            $solution = [pscustomobject]@{
                    Deployed                = $false
                    Properties              = @{ Version = "1.0.0.0" }
                    DeployedWebApplications = @( [pscustomobject]@{Url="http://app1"}, [pscustomobject]@{Url="http://app2"})
                    ContainsGlobalAssembly  = $true
                } 
            $solution | Add-Member -Name Update -MemberType ScriptMethod  -Value { }

            Mock -CommandName Get-SPSolution -MockWith { $solution }    
            Mock -CommandName Add-SPSolution -MockWith { $solution }  

            It "deploys the solution using the correct compatability level" {
                Set-TargetResource @testParams

                Assert-MockCalled Install-SPSolution -ParameterFilter { $CompatibilityLevel -eq $testParams.SolutionLevel }
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
