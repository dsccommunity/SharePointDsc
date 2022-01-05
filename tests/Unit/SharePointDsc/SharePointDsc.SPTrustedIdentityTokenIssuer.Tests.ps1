[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPTrustedIdentityTokenIssuer'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Mocks for all contexts
                Mock -CommandName Get-ChildItem -MockWith {
                    return @(
                        @{
                            Thumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        }
                    )
                } -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

                Mock -CommandName New-SPTrustedIdentityTokenIssuer -MockWith {
                    $sptrust = [pscustomobject]@{
                        Name               = $testParams.Name
                        ClaimProviderName  = ""
                        ProviderSignOutUri = ""
                    }
                    $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                    return $sptrust
                }

                Mock -CommandName New-SPClaimTypeMapping -MockWith {
                    return [pscustomobject]@{
                        InputClaimType = $testParams.IdentifierClaim
                    }
                }

                Mock -CommandName Get-SPClaimProvider -MockWith {
                    return [pscustomobject]@(@{
                            DisplayName = $testParams.ClaimProviderName
                        })
                }

                try
                {
                    [Microsoft.SharePoint.Administration.SPUrlZone]
                }
                catch
                {
                    Add-Type -TypeDefinition @"
        namespace Microsoft.SharePoint.Administration {
            public enum SPUrlZone { Default, Intranet, Internet, Custom, Extranet };
        }
"@
                }

                try
                {
                    [Microsoft.SharePoint.Administration.SPTrustedAuthenticationProvider]
                }
                catch
                {
                    Add-Type -TypeDefinition @"
        namespace Microsoft.SharePoint.Administration {
            public class SPTrustedAuthenticationProvider {}
        }
"@
                }

                function Add-SPDscEvent
                {
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType,

                        [Parameter()]
                        [System.UInt32]
                        $EventID
                    )
                }
            }

            # Test contexts
            Context -Name "The SAML SPTrustedLoginProvider does not exist but should, using a signing certificate in the certificate store" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        Realm                        = "https://sharepoint.contoso.com"
                        SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Present"
                    }
                }

                It "Should return absent from the get method" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the SPTrustedIdentityTokenIssuer" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPTrustedIdentityTokenIssuer
                }
            }

            Context -Name "The SAML SPTrustedLoginProvider does not exist but should, using a signing certificate in the file path" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                       = "Contoso"
                        Description                = "Contoso"
                        Realm                      = "https://sharepoint.contoso.com"
                        SignInUrl                  = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim            = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings             = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateFilePath = "F:\Data\DSC\FakeSigning.cer"
                        ClaimProviderName          = "LDAPCP"
                        ProviderSignOutUri         = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                     = "Present"
                    }

                    Mock -CommandName New-Object -MockWith {
                        return @(
                            @{
                                Thumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                            }
                        )
                    } -ParameterFilter { $TypeName -eq 'System.Security.Cryptography.X509Certificates.X509Certificate2' }
                }

                It "Should return absent from the get method" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the SPTrustedIdentityTokenIssuer" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPTrustedIdentityTokenIssuer
                }
            }

            Context -Name "The SPTrustedLoginProvider is desired, but both parameters SigningCertificateThumbprint and SigningCertificateFilePath are set while exactly 1 should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        Realm                        = "https://sharepoint.contoso.com"
                        SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        SigningCertificateFilePath   = "F:\Data\DSC\FakeSigning.cer"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Present"
                    }
                }

                It "should fail validation of signing certificate parameters in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time."
                }
            }

            Context -Name "The SPTrustedLoginProvider is desired, but none of parameters SigningCertificateThumbprint and SigningCertificateFilePath is set while exactly 1 should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "Contoso"
                        Description        = "Contoso"
                        Realm              = "https://sharepoint.contoso.com"
                        SignInUrl          = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim    = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings     = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        ClaimProviderName  = "LDAPCP"
                        ProviderSignOutUri = "https://adfs.contoso.com/adfs/ls/"
                        Ensure             = "Present"
                    }
                }

                It "should fail validation of signing certificate parameters in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "At least one of the following parameters must be specified: SigningCertificateThumbprint, SigningCertificateFilePath."
                }
            }

            Context -Name "The SPTrustedLoginProvider is desired, but the thumbprint of the signing certificate in parameter SigningCertificateThumbprint is invalid" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        Realm                        = "https://sharepoint.contoso.com"
                        SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "XX123ABCFACEXX"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Present"
                    }
                }

                It "should fail validation of parameter SigningCertificateThumbprint in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter SigningCertificateThumbprint does not match valid format '^[A-Fa-f0-9]{40}$'."
                }
            }

            Context -Name "The SPTrustedLoginProvider is desired, but the private key of the signing certificate is present in certificate store while it should not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        Realm                        = "https://sharepoint.contoso.com"
                        SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Present"
                    }

                    Mock -CommandName Get-ChildItem -MockWith {
                        return @(
                            @{
                                Thumbprint    = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                                HasPrivateKey = $true
                            }
                        )
                    } -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
                }

                It "should fail validation of certificate in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "SharePoint requires that the private key of the signing certificate is not installed in the certificate store."
                }
            }

            Context -Name "A SAML SPTrustedLoginProvider is desired, but parameters for both OIDC and SAML trusts are set" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        Realm                        = "https://sharepoint.contoso.com"
                        $DefaultClientIdentifier     = "fae5bd07-be63-4a64-a28c-7931a4ebf62b"
                        SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Present"
                    }
                }

                It "should fail validation of certificate in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameters Realm (for SAML trust) and DefaultClientIdentifier (for OIDC trust) cannot be both set."
                }
            }

            Context -Name "A SPTrustedLoginProvider is desired, but neither property Realm nor DefaultClientIdentifier set" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Present"
                    }
                }

                It "should fail validation of certificate in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "At least one of the following parameters must be specified: " + `
                        "Realm (for SAML trust), DefaultClientIdentifier (for OIDC trust)."
                }
            }

            Context -Name "A SAML SPTrustedLoginProvider is desired, but property SignInUrl is not set" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        Realm                        = "https://sharepoint.contoso.com"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Present"
                    }
                }

                It "should fail validation of certificate in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter Realm was set but SignInUrl is not set. Parameter SignInUrl required when Realm is set."
                }
            }

            Context -Name "A OIDC SPTrustedLoginProvider is desired, but not all required OIDC properties are set" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        $DefaultClientIdentifier     = "fae5bd07-be63-4a64-a28c-7931a4ebf62b"
                        $SignOutUrl                  = "https://adfs.contoso.com/adfs/oauth2/logout"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        Ensure                       = "Present"
                    }
                }

                It "should fail validation of certificate in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter DefaultClientIdentifier was set but AuthorizationEndPointUri, RegisteredIssuerName or SignOutUrl are not set." + `
                        "Parameters AuthorizationEndPointUri, RegisteredIssuerName, DefaultClientIdentifier and SignOutUrl are required when DefaultClientIdentifier is set"
                }
            }

            Context -Name "The SAML SPTrustedLoginProvider does not exist but should, with a claims provider that exists on the farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        Realm                        = "https://sharepoint.contoso.com"
                        SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Present"
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name              = $testParams.Name
                            ClaimProviderName = $testParams.ClaimProviderName
                        }
                        $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                        return $sptrust
                    }
                }

                It "Should create the SPTrustedLoginProvider with claims provider set" {
                    Set-TargetResource @testParams
                    $getResults = Get-TargetResource @testParams
                    $getResults.ClaimProviderName | Should -Be $testParams.ClaimProviderName
                }
            }

            Context -Name "The OIDC SPTrustedLoginProvider does not exist but should, with a claims provider that exists on the farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        $DefaultClientIdentifier     = "fae5bd07-be63-4a64-a28c-7931a4ebf62b"
                        $AuthorizationEndPointUri    = "https://adfs.contoso.com/adfs/oauth2/authorize"
                        $SignOutUrl                  = "https://adfs.contoso.com/adfs/oauth2/logout"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        Ensure                       = "Present"
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name              = $testParams.Name
                            ClaimProviderName = $testParams.ClaimProviderName
                        }
                        $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                        return $sptrust
                    }
                }

                It "Should create the SPTrustedLoginProvider with claims provider set" {
                    Set-TargetResource @testParams
                    $getResults = Get-TargetResource @testParams
                    $getResults.ClaimProviderName | Should -Be $testParams.ClaimProviderName
                }
            }

            Context -Name "The SAML SPTrustedLoginProvider already exists and should not be changed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        Realm                        = "https://sharepoint.contoso.com"
                        SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
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
                }

                It "Should return present from the get method" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The OIDC SPTrustedLoginProvider already exists and should not be changed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        $DefaultClientIdentifier     = "fae5bd07-be63-4a64-a28c-7931a4ebf62b"
                        $AuthorizationEndPointUri    = "https://adfs.contoso.com/adfs/oauth2/authorize"
                        $SignOutUrl                  = "https://adfs.contoso.com/adfs/oauth2/logout"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        Ensure                       = "Present"
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name              = $testParams.Name
                            ClaimProviderName = $testParams.ClaimProviderName
                        }
                        return $sptrust
                    }
                }

                It "Should return present from the get method" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProvider already exists but should be removed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        # Realm                        = "https://sharepoint.contoso.com"
                        # SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Absent"
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name = $testParams.Name
                        }
                        $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                        return $sptrust
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $spWebApp = [pscustomobject]@{
                            Url = "http://webAppUrl"
                        }
                        $spWebApp | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                        $spWebApp | Add-Member -Name GetIisSettingsWithFallback -MemberType ScriptMethod -Value { }
                        return $spWebApp
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        $spAP = [pscustomobject]@{
                            LoginProviderName = ""
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
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the SPTrustedIdentityTokenIssuer" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPTrustedIdentityTokenIssuer
                }
            }

            Context -Name "The SAML SPTrustedLoginProvider is desired, but the IdentifierClaim parameter does not match a claim type in ClaimsMappings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        Realm                        = "https://sharepoint.contoso.com"
                        SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                        IdentifierClaim              = "IdentityClaimTypeNotSpecifiedInClaimsMappings"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                        Ensure                       = "Present"
                    }

                    Mock -CommandName New-SPClaimTypeMapping -MockWith {
                        return [pscustomobject]@{
                            InputClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        }
                    }
                }

                It "should fail validation of IdentifierClaim in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "IdentifierClaim does not match any claim type specified in ClaimsMappings."
                }
            }

            Context -Name "The OIDC SPTrustedLoginProvider is desired, but the IdentifierClaim parameter does not match a claim type in ClaimsMappings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "Contoso"
                        Description                  = "Contoso"
                        $DefaultClientIdentifier     = "fae5bd07-be63-4a64-a28c-7931a4ebf62b"
                        $AuthorizationEndPointUri    = "https://adfs.contoso.com/adfs/oauth2/authorize"
                        $SignOutUrl                  = "https://adfs.contoso.com/adfs/oauth2/logout"
                        IdentifierClaim              = "IdentityClaimTypeNotSpecifiedInClaimsMappings"
                        ClaimsMappings               = @(
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Email"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPClaimTypeMapping -Property @{
                                Name              = "Role"
                                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                            } -ClientOnly)
                        )
                        SigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                        ClaimProviderName            = "LDAPCP"
                        Ensure                       = "Present"
                    }

                    Mock -CommandName New-SPClaimTypeMapping -MockWith {
                        return [pscustomobject]@{
                            InputClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                        }
                    }
                }

                It "should fail validation of IdentifierClaim in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "IdentifierClaim does not match any claim type specified in ClaimsMappings."
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name                       = "Contoso"
                            Description                = "Contoso"
                            Realm                      = "https://sharepoint.contoso.com"
                            SignInUrl                  = "https://adfs.contoso.com/adfs/ls/"
                            IdentifierClaim            = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                            ClaimsMappings             = @(
                                @{
                                    Name              = "Email"
                                    IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                                }
                                @{
                                    Name              = "Role"
                                    IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                                    LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                                }
                            )
                            SigningCertificateFilePath = "F:\Data\DSC\FakeSigning.cer"
                            ClaimProviderName          = "LDAPCP"
                            ProviderSignOutUri         = "https://adfs.contoso.com/adfs/ls/"
                            Ensure                     = "Present"
                        }
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        $spIdentityProv = @(
                            @{
                                Name        = "Contoso"
                                Description = "Contoso"
                            }
                        )
                        return $spIdentityProv
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        \$members = \@\(\);
        \$members \+= MSFT_SPClaimTypeMapping {
                Name = "Email"
                IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
            };
        \$members \+= MSFT_SPClaimTypeMapping {
                LocalClaimType = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                Name = "Role"
                IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
            };
        SPTrustedIdentityTokenIssuer [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            ClaimProviderName          = "LDAPCP";
            ClaimsMappings             = "\$members";
            Description                = "Contoso";
            Ensure                     = "Present";
            IdentifierClaim            = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress";
            Name                       = "Contoso";
            ProviderSignOutUri         = "https://adfs.contoso.com/adfs/ls/";
            PsDscRunAsCredential       = \$Credsspfarm;
            Realm                      = "https://sharepoint.contoso.com";
            SigningCertificateFilePath = "F:\\Data\\DSC\\FakeSigning.cer";
            SignInUrl                  = "https://adfs.contoso.com/adfs/ls/";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
