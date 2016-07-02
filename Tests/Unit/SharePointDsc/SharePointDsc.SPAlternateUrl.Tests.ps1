[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPAlternateUrl"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPAlternateUrl - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://test.constoso.local"
            Zone = "Default"
            Ensure = "Present"
            Url = "http://something.contoso.local"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock New-SPAlternateURL {}
        Mock Set-SPAlternateURL {}
        Mock Remove-SPAlternateURL {}
        
        Context "No alternate URL exists for the specified zone and web app, and there should be" {
            
            Mock Get-SPAlternateUrl {
                return @()
            }                                    

            it "returns an empty URL in the get method" {
                (Get-TargetResource @testParams).Url | Should BeNullOrEmpty 
            }

            it "return false from the test method" {
                Test-targetResource @testParams | Should Be $false
            }

            it "calls the new function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAlternateURL
            }
        }

        Context "A URL exists for the specified zone and web app, but the URL is wrong" {
            
            Mock Get-SPAlternateUrl {
                return @(
                    @{
                        IncomingUrl = $testParams.WebAppUrl
                        Zone = $testParams.Zone
                        PublicUrl = "http://wrong.url"
                    }
                )
            }

            it "returns the wrong URL in the get method" {
                (Get-TargetResource @testParams).Url | Should Not Be $testParams.Url 
            }

            it "returns false from the test method" {
                Test-targetResource @testParams | Should Be $false
            }

            it "calls the set cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPAlternateURL
            }
        }

        Context "A URL exists for the specified zone and web app, and it is correct" {
            
            Mock Get-SPAlternateUrl {
                return @(
                    @{
                        IncomingUrl = $testParams.WebAppUrl
                        Zone = $testParams.Zone
                        PublicUrl = $testParams.Url
                    }
                )
            }

            it "returns the correct URL in the get method" {
                (Get-TargetResource @testParams).Url | Should Be $testParams.Url 
            }

            it "returns true from the test method" {
                Test-targetResource @testParams | Should Be $true
            }
        }

        Context "A URL exists for the specified zone and web app, and it should not" {
            
            Mock Get-SPAlternateUrl {
                return @(
                    @{
                        IncomingUrl = $testParams.WebAppUrl
                        Zone = $testParams.Zone
                        PublicUrl = $testParams.Url
                    }
                )
            }
            $testParams.Ensure = "Absent"

            it "returns false from the test method" {
                Test-targetResource @testParams | Should Be $false
            }

            it "calls the remove cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPAlternateURL
            }
        }

        Context "A URL does not exist for the current zone, and it should not" {

            Mock Get-SPAlternateUrl {
                return @()
            } 

            it "returns the empty values in the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            it "returns true from the test method" {
                Test-targetResource @testParams | Should Be $true
            }
            $testParams.Remove("Url")
            it "still returns true from the test method with the URL property not providing" {
                Test-targetResource @testParams | Should Be $true
            }
            $testParams.Add("Url", "http://something.contoso.local")
        }
        
        Context "The default zone URL for a web app was changed using this resource" {
            
            Mock Get-SPAlternateUrl {
                return @()
            } -ParameterFilter { $WebApplication -eq $testParams.WebAppUrl }
            Mock Get-SPAlternateUrl {
                return @(
                    @{
                        IncomingUrl = $testParams.Url
                        Zone = $testParams.Zone
                        PublicUrl = $testParams.Url
                    }
                )
            } -ParameterFilter { $null -eq $WebApplication }
            $testParams.Ensure = "Present"
            
            it "should still return true in the test method despite the web app URL being different" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

