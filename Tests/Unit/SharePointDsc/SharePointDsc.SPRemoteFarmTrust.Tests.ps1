[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPRemoteFarmTrust"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPRemoteFarmTrust - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "SendingFarm"
            LocalWebAppUrl = "https://sharepoint.adventureworks.com"
            RemoteWebAppUrl = "https://sharepoint.contoso.com"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Mock Get-SPSite {
            return @{
                Url = $Identity
            }
        }
        Mock Get-SPServiceContext {
            return @{
                Site = $Site
            }
        }
        Mock Get-SPAuthenticationRealm {
            return "14757a87-4d74-4323-83b9-fb1e77e8f22f"
        }
        Mock Get-SPAppPrincipal {
            return @{
                Site = $Site
            }
        }
        Mock Set-SPAuthenticationRealm {}
        Mock Set-SPAppPrincipalPermission {}
        Mock Remove-SPAppPrincipalPermission {}
        Mock Remove-SPTrustedRootAuthority {}
        Mock Remove-SPTrustedSecurityTokenIssuer {}
        Mock New-SPTrustedSecurityTokenIssuer {
            return @{
                NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
            }
        }
        Mock New-SPTrustedRootAuthority {
            return @{
                NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
            }
        }


        Context "A remote farm trust doesn't exist, but should" {

            Mock Get-SPTrustedSecurityTokenIssuer {
                return $null
            }
            Mock Get-SPTrustedRootAuthority {
                return $null
            }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "adds the trust in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName New-SPTrustedSecurityTokenIssuer
                Assert-MockCalled -CommandName New-SPTrustedRootAuthority
            }
        }

        Context "A remote farm trust exists and should" {

            Mock Get-SPTrustedSecurityTokenIssuer {
                return @(
                    @{
                        NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                    }
                )
            }
            Mock Get-SPTrustedRootAuthority {
                return @{
                    NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                }
            }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        $testParams.Ensure = "Absent"

        Context "A remote farm trust exists and shouldn't" {

            Mock Get-SPTrustedSecurityTokenIssuer {
                return @(
                    @{
                        NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                    }
                )
            }
            Mock Get-SPTrustedRootAuthority {
                return @{
                    NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                }
            }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "removes the trust in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName Remove-SPTrustedSecurityTokenIssuer
                Assert-MockCalled -CommandName Remove-SPTrustedRootAuthority
            }
        }

        Context "A remote farm trust doesn't exist and shouldn't" {

            Mock Get-SPTrustedSecurityTokenIssuer {
                return $null
            }
            Mock Get-SPTrustedRootAuthority {
                return $null
            }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}
