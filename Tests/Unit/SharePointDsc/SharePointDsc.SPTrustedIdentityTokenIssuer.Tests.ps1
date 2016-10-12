[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPTrustedIdentityTokenIssuer"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPTrustedIdentityTokenIssuer - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name                         = "Contoso"
            Description                  = "Contoso"
            Realm                        = "https://sharepoint.contoso.com"
            SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
            IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
            ClaimsMappings               = @(
                (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                    Name = "Email"
                    IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                } -ClientOnly)
                (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                    Name = "Role"
                    IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                    LocalClaimType = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                } -ClientOnly)
            )
            SigningCertificateThumbPrint = "Mock Thumbrpint"
            ClaimProviderName            = "LDAPCP"
            ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
            Ensure                       = "Present"
        }

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }        
        
        Mock Get-ChildItem {
            return @(
                @{
                    Thumbprint = "Mock Thumbrpint"
                }
            )
        }

        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Context "The SPTrustedIdentityTokenIssuer does not exist, but it should be present" {
            Mock New-SPTrustedIdentityTokenIssuer {
                $sptrust = [pscustomobject]@{
                    Name              = $testParams.Name
                    ClaimProviderName = ""
                    ProviderSignOutUri = ""
                }
                $sptrust| Add-Member -Name Update -MemberType ScriptMethod  -Value { }
                return $sptrust
            }

            Mock New-SPClaimTypeMapping {
                return [pscustomobject]@{
                    MappedClaimType = $testParams.IdentifierClaim
                }
            }

            $getResults = Get-TargetResource @testParams

            It "returns absent from the get method" {
                $getResults.Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates the SPTrustedIdentityTokenIssuer" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPTrustedIdentityTokenIssuer
            }
        }
        
        Context "The SPTrustedIdentityTokenIssuer does not exist, but it should be present and claims provider specified exists on the farm" {
            Mock Get-SPClaimProvider {
                return [pscustomobject]@(@{
                    DisplayName = $testParams.ClaimProviderName
                })
            }
            
            Mock New-SPTrustedIdentityTokenIssuer {
                $sptrust = [pscustomobject]@{
                    Name              = $testParams.Name
                    ClaimProviderName = ""
                    ProviderSignOutUri = ""
                }
                $sptrust| Add-Member -Name Update -MemberType ScriptMethod  -Value { }
                return $sptrust
            }
            
            Mock Get-SPTrustedIdentityTokenIssuer {
                $sptrust = [pscustomobject]@{
                    Name              = $testParams.Name
                    ClaimProviderName = $testParams.ClaimProviderName
                    ProviderSignOutUri = ""
                }
                $sptrust| Add-Member -Name Update -MemberType ScriptMethod  -Value { }
                return $sptrust
            }
            
            Mock New-SPClaimTypeMapping {
                return [pscustomobject]@{
                    MappedClaimType = $testParams.IdentifierClaim
                }
            }
            
            Set-TargetResource @testParams
            $getResults = Get-TargetResource @testParams
            
            It "creates the SPTrustedIdentityTokenIssuer and sets claims provider" {
                $getResults.ClaimProviderName | Should Be $testParams.ClaimProviderName
            }
        }

        Context "The SPTrustedIdentityTokenIssuer already exists, and it should be present" {
            Mock Get-SPTrustedIdentityTokenIssuer {
                $sptrust = [pscustomobject]@{
                    Name              = $testParams.Name
                    ClaimProviderName = ""
                    ProviderSignOutUri = ""
                }
                return $sptrust
            }

            $getResults = Get-TargetResource @testParams

            It "returns present from the get method" {
                $getResults.Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "doe not create the SPTrustedIdentityTokenIssuer" {
                Set-TargetResource @testParams
            }
        }

        $testParams.Ensure = "Absent"

        Context "The SPTrustedIdentityTokenIssuer exists, but it should be absent" {
            Mock Get-SPTrustedIdentityTokenIssuer {
                $sptrust = [pscustomobject]@{
                    Name              = $testParams.Name
                }
                $sptrust| Add-Member -Name Update -MemberType ScriptMethod  -Value { }
                return $sptrust
            }

            Mock Remove-SPTrustedIdentityTokenIssuer { } -Verifiable

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "removes the SPTrustedIdentityTokenIssuer" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPTrustedIdentityTokenIssuer
            }
        }

        $testParams.Ensure = "Present"
        $originalIdentifierClaim = $testParams.IdentifierClaim
        $testParams.IdentifierClaim = "UnknownClaimType"

        Context "The IdentifierClaim does not match one of the claim types in ClaimsMappings" {
             Mock New-SPClaimTypeMapping {
                return [pscustomobject]@{
                    MappedClaimType = $originalIdentifierClaim
                }
            }

            It "validation of IdentifierClaim fails in the set method" {
                { Set-TargetResource @testParams } | Should Throw "IdentifierClaim does not match any claim type specified in ClaimsMappings."
            }
        }

        $testParams.IdentifierClaim = $originalIdentifierClaim
        $testParams.SigningCertificateThumbPrint = "UnknownSigningCertificateThumbPrint"

        Context "The certificate thumbprint does not match a certificate in certificate store LocalMachine\My" {
            It "validation of SigningCertificateThumbPrint fails in the set method" {
                { Set-TargetResource @testParams } | Should Throw "The certificate thumbprint does not match a certificate in certificate store LocalMachine\My."
            }
        }
    }
}

