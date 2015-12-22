[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPHealthAnalyzerRuleState"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPHealthAnalyzerRuleState" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Drives are at risk of running out of free space."
            Enabled = $true
            RuleScope   = "All Servers"
            Schedule = "Daily"
            FixAutomatically = $false
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
                
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Add-Type -TypeDefinition "namespace Microsoft.SharePoint { public class SPQuery { public string Query { get; set; } } }"

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

        Context "The server is in a farm, but no central admin site is found" {
            Mock Get-SPwebapplication { return $null }

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "No Central Admin web application was found. Health Analyzer Rule  settings will not be applied"
            }
        }

        Context "The server is in a farm, CA found, but no health analyzer rules list is found" {
            Mock Get-SPwebapplication { return @{ Url = "";IsAdministrationWebApplication=$true } }
            Mock Get-SPWeb { return @{ Lists = $null } }

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Could not find Health Analyzer Rules list. Health Analyzer Rule settings will not be applied"
            }
        }


        Context "The server is in a farm, CA found, Health Rules list found, but no rules match the specified rule name" {
            Mock Get-SPwebapplication { return @{ Url = "";IsAdministrationWebApplication=$true } }
            Mock Get-SPWeb {
                $web = @{
                    Lists = @{
                        BaseTemplate = "HealthRules"
                    } | Add-Member ScriptMethod GetItems { 
                            return ,@()
                        } -PassThru
                }
                return $web
            }

            Mock Get-SPFarm { return @{} }

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Could not find specified Health Analyzer Rule. Health Analyzer Rule settings will not be applied"
            }
        }

        Context "The server is in a farm, CA/Health Rules list/Health Rule found, but the incorrect settings have been applied" {
            Mock Get-SPwebapplication { return @{ Url = "";IsAdministrationWebApplication=$true } }
            Mock Get-SPWeb {
                $web = @{
                    Lists = @{
                        BaseTemplate = "HealthRules"
                    } | Add-Member ScriptMethod GetItems { 
                            $itemcol = @(@{
                                HealthRuleCheckEnabled = $false;
                                HealthRuleScope = "Any Server";
                                HealthRuleSchedule = "Weekly";
                                HealthRuleAutoRepairEnabled = $true
                            } | Add-Member ScriptMethod Update { $Global:xSharePointHealthRulesUpdated = $true } -PassThru )
                            return ,$itemcol
                        } -PassThru
                }
                return $web
            }
            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                $result = Get-TargetResource @testParams
                $result.Enabled | Should Be $false
                $result.RuleScope | Should Be 'Any Server'
                $result.Schedule| Should Be 'Weekly'
                $result.FixAutomatically | Should Be $true
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSharePointHealthRulesUpdated = $false
            It "set the configured values for the specific Health Analyzer Rule" {
                Set-TargetResource @testParams
                $Global:xSharePointHealthRulesUpdated | Should Be $true
            }
        }

        Context "The server is in a farm and the correct settings have been applied" {
            Mock Get-SPwebapplication { return @{ Url = "";IsAdministrationWebApplication=$true } }
            Mock Get-SPWeb {
                $web = @{
                    Lists = @{
                        BaseTemplate = "HealthRules"
                    } | Add-Member ScriptMethod GetItems { 
                            $itemcol = @(@{
                                HealthRuleCheckEnabled = $true;
                                HealthRuleScope = "All Servers";
                                HealthRuleSchedule = "Daily";
                                HealthRuleAutoRepairEnabled = $false
                            } | Add-Member ScriptMethod Update { $Global:xSharePointHealthRulesUpdated = $true } -PassThru )
                            return ,$itemcol
                        } -PassThru
                }
                return $web
            }
            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                $result = Get-TargetResource @testParams
                $result.Enabled | Should Be $true
                $result.RuleScope | Should Be 'All Servers'
                $result.Schedule| Should Be 'Daily'
                $result.FixAutomatically | Should Be $false
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        }
    }
}
