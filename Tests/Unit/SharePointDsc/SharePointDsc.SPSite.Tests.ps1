[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPSite"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPSite - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Url = "http://site.sharepoint.com"
            OwnerAlias = "DEMO\User"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock -CommandName New-SPSite { }

        Context -Name "The site doesn't exist yet and should" {
            Mock -CommandName Get-SPSite { return $null }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new site from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPSite
            }
        }

        Context -Name "The site exists and is a host named site collection" {
            Mock -CommandName Get-SPSite { return @{
                HostHeaderIsSiteName = $true
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $false
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
            }}

            It "Should return the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The site exists and uses claims authentication" {
            Mock -CommandName Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $true
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
            }}
            Mock -CommandName New-SPClaimsPrincipal { return @{ Value = $testParams.OwnerAlias }}

            It "Should return the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock -CommandName Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $true
                }
                Url = $testParams.Url
                Owner = $null
            }}

            It "Should return the site data from the get method where a valid site collection admin does not exist" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
            
            Mock -CommandName Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $true
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
                SecondaryContact = @{ UserLogin = "DEMO\secondary" }
            }}

            It "Should return the site data from the get method where a secondary site contact exists" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
        }

        Context -Name "The site exists and uses classic authentication" {
            Mock -CommandName Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $false
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
            }}

            It "Should return the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock -CommandName Get-SPSite { return @{
                HostHeaderIsSiteName = $false
                WebApplication = @{ 
                    Url = $testParams.Url 
                    UseClaimsAuthentication = $false
                }
                Url = $testParams.Url
                Owner = @{ UserLogin = "DEMO\owner" }
                SecondaryContact = @{ UserLogin = "DEMO\secondary" }
            }}

            It "Should return the site data from the get method where a secondary site contact exists" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
        }
    }    
}