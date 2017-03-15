[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPTrustedIdentityTokenIssuer"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts   
        Mock -CommandName Get-ChildItem -MockWith {
            return @(
                @{
                    Thumbprint = "123ABCFACE"
                }
            )
        }

        Mock -CommandName New-SPTrustedIdentityTokenIssuer -MockWith {
            $sptrust = [pscustomobject]@{
                Name              = $testParams.Name
                ClaimProviderName = ""
                ProviderSignOutUri = ""
            }
            $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
            return $sptrust
        }

        Mock -CommandName New-SPClaimTypeMapping -MockWith {
            return [pscustomobject]@{
                MappedClaimType = $testParams.IdentifierClaim
            }
        }

        Mock -CommandName Get-SPClaimProvider -MockWith {
            return [pscustomobject]@(@{
                DisplayName = $testParams.ClaimProviderName
            })
        }

        $CsharpCode = @"
namespace Microsoft.SharePoint.Administration {
    //public enum SPUrlZone { Default };
    
    public class SPTrustedAuthenticationProvider {
    }
}        
"@
        Add-Type -TypeDefinition $CsharpCode

        # Test contexts
        Context -Name "SPTrustedLoginProvider is created using a signing certificate in the certificate store" -Fixture {
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
                SigningCertificateThumbprint = "123ABCFACE"
                ClaimProviderName            = "LDAPCP"
                ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                Ensure                       = "Present"
            }

            It "Should return absent from the get method" {
                $getResults = Get-TargetResource @testParams
                $getResults.Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create the SPTrustedIdentityTokenIssuer" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPTrustedIdentityTokenIssuer
            }
        }

        Context -Name "SPTrustedLoginProvider is created using a signing certificate in the file path" -Fixture {
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
                SigningCertificateFilePath   = "F:\Data\DSC\FakeSigning.cer"
                ClaimProviderName            = "LDAPCP"
                ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                Ensure                       = "Present"
            }

            Mock -CommandName New-Object -MockWith {
                return @(
                    @{
                        Thumbprint = "123ABCFACE"
                    }
                )
            } -ParameterFilter { $TypeName -eq 'System.Security.Cryptography.X509Certificates.X509Certificate2' } -Verifiable

            It "Should return absent from the get method" {
                $getResults = Get-TargetResource @testParams
                $getResults.Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create the SPTrustedIdentityTokenIssuer" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPTrustedIdentityTokenIssuer
            }
        }

        Context -Name "Both parameters SigningCertificateThumbprint and SigningCertificateFilePath are set" -Fixture {
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
                SigningCertificateThumbprint = "123ABCFACE"
                SigningCertificateFilePath   = "F:\Data\DSC\FakeSigning.cer"
                ClaimProviderName            = "LDAPCP"
                ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                Ensure                       = "Present"
            }            

            It "should fail validation of signing certificate parameters in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time."
            }
        }
        
        Context -Name "SPTrustedLoginProvider is created with a claims provider that exists on the farm" -Fixture {
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
                SigningCertificateThumbprint = "123ABCFACE"
                ClaimProviderName            = "LDAPCP"
                ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                Ensure                       = "Present"
            }

            Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                $sptrust = [pscustomobject]@{
                    Name              = $testParams.Name
                    ClaimProviderName = $testParams.ClaimProviderName
                }
                $sptrust| Add-Member -Name Update -MemberType ScriptMethod -Value { }
                return $sptrust
            }
            
            It "Should create the SPTrustedLoginProvider with claims provider set" {
                Set-TargetResource @testParams
                $getResults = Get-TargetResource @testParams
                $getResults.ClaimProviderName | Should Be $testParams.ClaimProviderName
            }
        }

        Context -Name "SPTrustedLoginProvider already exists" -Fixture {
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
                SigningCertificateThumbprint = "123ABCFACE"
                ClaimProviderName            = "LDAPCP"
                ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                Ensure                       = "Present"
            }

            Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                $sptrust = [pscustomobject]@{
                    Name              = $testParams.Name
                    ClaimProviderName = $testParams.ClaimProviderName
                }
                return $sptrust
            }

            It "Should return present from the get method" {
                $getResults = Get-TargetResource @testParams
                $getResults.Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "SPTrustedLoginProvider already exists and must be removed" -Fixture {
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
                SigningCertificateThumbprint = "123ABCFACE"
                ClaimProviderName            = "LDAPCP"
                ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                Ensure                       = "Absent"
            }

            Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                $sptrust = [pscustomobject]@{
                    Name              = $testParams.Name
                }
                $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                return $sptrust
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                $spWebApp = [pscustomobject]@{
                    Url              = "http://webAppUrl"
                }
                $spWebApp | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                $spWebApp | Add-Member -Name GetIisSettingsWithFallback -MemberType ScriptMethod -Value { }
                return $spWebApp
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                $spAP = [pscustomobject]@{
                    LoginProviderName              = ""
                }
                $spAP | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                $spAP | Add-Member -MemberType ScriptMethod `
                                    -Name GetType `
                                    -Value {  
                                        return @{ 
                                            FullName = "Microsoft.SharePoint.Administration.SPTrustedAuthenticationProvider" 
                                        }  
                                    } -PassThru -Force 
                return $spAP
            }

            Mock -CommandName Remove-SPTrustedIdentityTokenIssuer -MockWith { }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should remove the SPTrustedIdentityTokenIssuer" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPTrustedIdentityTokenIssuer
            }
        }

        Context -Name "The IdentifierClaim does not match one of the claim types in ClaimsMappings" -Fixture {
            $testParams = @{
                Name                         = "Contoso"
                Description                  = "Contoso"
                Realm                        = "https://sharepoint.contoso.com"
                SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                IdentifierClaim              = "IdentityClaimTypeNotSpecifiedInClaimsMappings"
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
                SigningCertificateThumbprint = "123ABCFACE"
                ClaimProviderName            = "LDAPCP"
                ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                Ensure                       = "Present"
            }

            Mock -CommandName New-SPClaimTypeMapping -MockWith {
                return [pscustomobject]@{
                    MappedClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                }
            }

            It "should fail validation of IdentifierClaim in the set method" {
                { Set-TargetResource @testParams } | Should Throw "IdentifierClaim does not match any claim type specified in ClaimsMappings."
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
