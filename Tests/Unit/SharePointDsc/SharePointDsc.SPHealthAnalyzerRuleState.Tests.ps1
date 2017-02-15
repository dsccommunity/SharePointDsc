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
                                              -DscResource "SPHealthAnalyzerRuleState"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        Add-Type -TypeDefinition "namespace Microsoft.SharePoint { public class SPQuery { public string Query { get; set; } } }"

        # Mocks for all contexts   
        Mock -CommandName Get-SPFarm -MockWith { 
            return @{} 
        }

        Mock -CommandName Get-SPWebapplication -MockWith { 
            return @{ 
                Url = ""
                IsAdministrationWebApplication=$true 
            } 
        }

        # Test contexts
        Context -Name "The server is not part of SharePoint farm" -Fixture {
            $testParams = @{
                Name = "Drives are at risk of running out of free space."
                Enabled = $true
                RuleScope   = "All Servers"
                Schedule = "Daily"
                FixAutomatically = $false
            }

            Mock -CommandName Get-SPFarm -MockWith { throw "Unable to detect local farm" }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Context -Name "The server is in a farm, but no central admin site is found" -Fixture {
            $testParams = @{
                Name = "Drives are at risk of running out of free space."
                Enabled = $true
                RuleScope   = "All Servers"
                Schedule = "Daily"
                FixAutomatically = $false
            }
            
            Mock -CommandName Get-SPWebapplication -MockWith { 
                return $null 
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "No Central Admin web application was found. Health Analyzer Rule settings will not be applied"
            }
        }

        Context -Name "The server is in a farm, CA found, but no health analyzer rules list is found" -Fixture {
            $testParams = @{
                Name = "Drives are at risk of running out of free space."
                Enabled = $true
                RuleScope   = "All Servers"
                Schedule = "Daily"
                FixAutomatically = $false
            }
            
            Mock -CommandName Get-SPWeb -MockWith { 
                return @{ 
                    Lists = $null 
                } 
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Could not find Health Analyzer Rules list. Health Analyzer Rule settings will not be applied"
            }
        }

        Context -Name "The server is in a farm, CA found, Health Rules list found, but no rules match the specified rule name" -Fixture {
            $testParams = @{
                Name = "Drives are at risk of running out of free space."
                Enabled = $true
                RuleScope   = "All Servers"
                Schedule = "Daily"
                FixAutomatically = $false
            }

            Mock -CommandName Get-SPWeb -MockWith {
                $web = @{
                    Lists = @{
                        BaseTemplate = "HealthRules"
                    } | Add-Member -MemberType ScriptMethod -Name GetItems -Value { 
                            return ,@()
                        } -PassThru
                }
                return $web
            }

            Mock -CommandName Get-SPFarm -MockWith { return @{} }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Could not find specified Health Analyzer Rule. Health Analyzer Rule settings will not be applied"
            }
        }

        Context -Name "The server is in a farm, CA/Health Rules list/Health Rule found, but the incorrect settings have been applied" -Fixture {
            $testParams = @{
                Name = "Drives are at risk of running out of free space."
                Enabled = $true
                RuleScope   = "All Servers"
                Schedule = "Daily"
                FixAutomatically = $false
            }
            
            Mock -CommandName Get-SPWeb -MockWith {
                $web = @{
                    Lists = @{
                        BaseTemplate = "HealthRules"
                    } | Add-Member -MemberType ScriptMethod -Name GetItems -Value { 
                            $itemcol = @(@{
                                HealthRuleCheckEnabled = $false;
                                HealthRuleScope = "Any Server";
                                HealthRuleSchedule = "Weekly";
                                HealthRuleAutoRepairEnabled = $true
                            } | Add-Member -MemberType ScriptMethod -Name Update -Value { 
                                $Global:SPDscHealthRulesUpdated = $true 
                            } -PassThru )
                            return ,$itemcol
                        } -PassThru
                }
                return $web
            }
            
            It "Should return values from the get method" {
                $result = Get-TargetResource @testParams
                $result.Enabled | Should Be $false
                $result.RuleScope | Should Be 'Any Server'
                $result.Schedule| Should Be 'Weekly'
                $result.FixAutomatically | Should Be $true
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscHealthRulesUpdated = $false
            It "set the configured values for the specific Health Analyzer Rule" {
                Set-TargetResource @testParams
                $Global:SPDscHealthRulesUpdated | Should Be $true
            }
        }

        Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
            $testParams = @{
                Name = "Drives are at risk of running out of free space."
                Enabled = $true
                RuleScope   = "All Servers"
                Schedule = "Daily"
                FixAutomatically = $false
            }
            
            Mock -CommandName Get-SPWeb -MockWith {
                $web = @{
                    Lists = @{
                        BaseTemplate = "HealthRules"
                    } | Add-Member -MemberType ScriptMethod -Name GetItems -Value { 
                            $itemcol = @(@{
                                HealthRuleCheckEnabled = $true;
                                HealthRuleScope = "All Servers";
                                HealthRuleSchedule = "Daily";
                                HealthRuleAutoRepairEnabled = $false
                            } | Add-Member -MemberType ScriptMethod -Name Update -Value { 
                                $Global:SPDscHealthRulesUpdated = $true 
                            } -PassThru )
                            return ,$itemcol
                        } -PassThru
                }
                return $web
            }

            It "Should return values from the get method" {
                $result = Get-TargetResource @testParams
                $result.Enabled | Should Be $true
                $result.RuleScope | Should Be 'All Servers'
                $result.Schedule| Should Be 'Daily'
                $result.FixAutomatically | Should Be $false
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
