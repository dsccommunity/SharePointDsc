[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPWebApplicationAppDomain"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPWebApplicationAppDomain - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            AppDomain = "contosointranetapps.com"
            WebApplication ="http://portal.contoso.com"
            Zone = "Default"
            Port = 80;
            SSL = $false
        }

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock New-SPWebApplicationAppDomain { }
        Mock Remove-SPWebApplicationAppDomain { }
        Mock Start-Sleep { }

        Context "No app domain settings have been configured for the specified web app and zone" {
            Mock Get-SPWebApplicationAppDomain { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates the new app domain entry" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPWebApplicationAppDomain
            }
        }

        Context "An app domain has been configured for the specified web app and zone but it's not correct" {
            Mock Get-SPWebApplicationAppDomain { 
                return @{
                    AppDomain = "wrong.domain"
                    UrlZone = $testParams.Zone
                    Port = $testParams.Port
                    IsSchemeSSL = $testParams.SSL
                }
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates the new app domain entry" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPWebApplicationAppDomain
                Assert-MockCalled New-SPWebApplicationAppDomain
            }
        }

        Context "The correct app domain has been configued for the requested web app and zone" {
            Mock Get-SPWebApplicationAppDomain { 
                return @{
                    AppDomain = $testParams.AppDomain
                    UrlZone = $testParams.Zone
                    Port = $testParams.Port
                    IsSchemeSSL = $testParams.SSL
                }
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        $testParams = @{
            AppDomain = "contosointranetapps.com"
            WebApplication ="http://portal.contoso.com"
            Zone = "Default"
        }

        Context "The functions operate without optional parameters included" {
            Mock Get-SPWebApplicationAppDomain { 
                return @{
                    AppDomain = "invalid.domain"
                    UrlZone = $testParams.Zone
                    Port = $testParams.Port
                    IsSchemeSSL = $testParams.SSL
                }
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates the new app domain entry" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPWebApplicationAppDomain
                Assert-MockCalled New-SPWebApplicationAppDomain
            }
        }
    }    
}


