[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPSite"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSite" {
    InModuleScope $ModuleName {
        $testParams = @{
            Url = "http://site.sharepoint.com"
            OwnerAlias = "DEMO\User"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock New-SPSite { }

        Context "The site doesn't exist yet and should" {
            Mock Get-SPSite { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new site from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPSite
            }
        }

        Context "The site exists and is a host named site collection" {
            Mock Get-SPSite { return @{
                HostHeaderIsSiteName = $true
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $false
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
            }}

            It "returns the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The site exists and uses claims authentication" {
            Mock Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $true
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
            }}
            Mock New-SPClaimsPrincipal { return @{ Value = $testParams.OwnerAlias }}

            It "returns the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $true
                }
                Url = $testParams.Url
                Owner = $null
            }}

            It "returns the site data from the get method where a valid site collection admin does not exist" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
            
            Mock Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $true
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
                SecondaryContact = @{ UserLogin = "DEMO\secondary" }
            }}

            It "returns the site data from the get method where a secondary site contact exists" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
        }

        Context "The site exists and uses classic authentication" {
            Mock Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $false
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
            }}

            It "returns the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $false
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
                SecondaryContact = @{ UserLogin = "DEMO\secondary" }
            }}

            It "returns the site data from the get method where a secondary site contact exists" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
        }
    }    
}