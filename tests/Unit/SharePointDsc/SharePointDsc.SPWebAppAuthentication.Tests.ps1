[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPWebAppAuthentication'
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

                # Initialize tests

                # Mocks for all contexts
                Mock -CommandName Set-SPWebApplication { }

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
            Context -Name "The web application doesn't exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                    $result.WebAppUrl | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified Web Application $($testparams.WebAppUrl) does not exist"
                }
            }

            Context -Name "AuthenticationMethod=WindowsAuthentication used without WindowsAuthMethod parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "WindowsAuthentication"
                                    AuthenticationProvider = "INCORRECT"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You have to specify WindowsAuthMethod when using WindowsAuthentication"
                }
            }

            Context -Name "AuthenticationMethod=WindowsAuthentication used with AuthenticationProvider parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "WindowsAuthentication"
                                    WindowsAuthMethod      = "NTLM"
                                    AuthenticationProvider = "INCORRECT"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You cannot use AuthenticationProvider, MembershipProvider or RoleProvider when using WindowsAuthentication"
                }
            }

            Context -Name "AuthenticationMethod=WindowsAuthentication used with MembershipProvider parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                    MembershipProvider   = "INCORRECT"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You cannot use AuthenticationProvider, MembershipProvider or RoleProvider when using WindowsAuthentication"
                }
            }

            Context -Name "AuthenticationMethod=FBA used with AuthenticationProvider parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "FBA"
                                    AuthenticationProvider = "INCORRECT"
                                    MembershipProvider     = "INCORRECT"
                                    RoleProvider           = "INCORRECT"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You cannot use AuthenticationProvider when using FBA"
                }
            }

            Context -Name "AuthenticationMethod=FBA used with WindowsAuthMethod parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "INCORRECT"
                                    RoleProvider         = "INCORRECT"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You cannot use WindowsAuthMethod or UseBasicAuth when using FBA"
                }
            }

            Context -Name "AuthenticationMethod=Federated used with RoleProvider parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "INCORRECT"
                                    RoleProvider           = "INCORRECT"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You cannot use MembershipProvider or RoleProvider when using Federated"
                }
            }

            Context -Name "AuthenticationMethod=Federated used with WindowsAuthMethod parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "INCORRECT"
                                    WindowsAuthMethod      = "NTLM"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You cannot use WindowsAuthMethod or UseBasicAuth when using Federated"
                }
            }

            Context -Name "AuthenticationMethod=FBA and missing MembershipProvider parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "FBA"
                                    AuthenticationProvider = "INCORRECT"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You have to specify MembershipProvider and RoleProvider when using FBA"
                }
            }

            Context -Name "AuthenticationMethod=Federated and missing AuthenticationProvider parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "Federated"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You have to specify AuthenticationProvider when using Federated"
                }
            }

            Context -Name "No additional parameters are specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should throw exception in the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default | Should -BeNullOrEmpty
                    $result.Intranet | Should -BeNullOrEmpty
                    $result.Extranet | Should -BeNullOrEmpty
                    $result.Internet | Should -BeNullOrEmpty
                    $result.Custom | Should -BeNullOrEmpty
                }

                It "Should throw exception in the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You have to specify at least one parameter."
                }
            }

            Context -Name "WebApplication is Classic, but Default Zone config is Claims" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith { }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default[0].AuthenticationMethod | Should -Be "Classic"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified Web Application is using Classic Authentication and Claims Authentication is specified."
                }
            }

            Context -Name "WebApplication is Classic, but Intranet Zone config is Claims" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Intranet  = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Intranet"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith { }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified Web Application is using Classic Authentication and Claims Authentication is specified."
                }
            }

            Context -Name "WebApplication is Classic, but Internet Zone config is Claims" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Internet  = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Internet"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith { }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified Web Application is using Classic Authentication and Claims Authentication is specified."
                }
            }

            Context -Name "WebApplication is Classic, but Extranet Zone config is Claims" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Extranet  = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Extranet"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith { }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified Web Application is using Classic Authentication and Claims Authentication is specified."
                }
            }

            Context -Name "WebApplication is Classic, but Custom Zone config is Claims" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Custom    = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Custom"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith { }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified Web Application is using Classic Authentication and Claims Authentication is specified."
                }
            }

            Context -Name "Default Zone of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                    UseBasicAuth         = $true
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName            = "Windows Authentication"
                                ClaimProviderName      = 'AD'
                                DisableKerberos        = $true
                                UseBasicAuthentication = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Default[0].WindowsAuthMethod | Should -Be "NTLM"
                    $result.Default[1].AuthenticationMethod | Should -Be "FBA"
                    $result.Default[2].AuthenticationMethod | Should -Be "Federated"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Specified Federated AuthenticationProvider does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return $null }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified AuthenticationProvider ADFS does not exist"
                }
            }

            Context -Name "Default Zone of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Default   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                    UseBasicAuth         = $true
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName            = "Windows Authentication"
                                ClaimProviderName      = 'AD'
                                DisableKerberos        = $true
                                UseBasicAuthentication = $false
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Default[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Default[0].WindowsAuthMethod | Should -Be "NTLM"
                    $result.Default[1].AuthenticationMethod | Should -Be "FBA"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Set-SPWebApplication
                }
            }

            Context -Name "Intranet Zone of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Intranet  = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default", "Intranet"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Intranet[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Intranet[0].WindowsAuthMethod | Should -Be "NTLM"
                    $result.Intranet[1].AuthenticationMethod | Should -Be "FBA"
                    $result.Intranet[2].AuthenticationMethod | Should -Be "Federated"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Intranet Zone of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Intranet  = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default", "Intranet"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Intranet[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Intranet[0].WindowsAuthMethod | Should -Be "NTLM"
                    $result.Intranet[1].AuthenticationMethod | Should -Be "FBA"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Set-SPWebApplication
                }
            }

            Context -Name "Internet Zone of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Internet  = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default", "Internet"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Internet[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Internet[0].WindowsAuthMethod | Should -Be "NTLM"
                    $result.Internet[1].AuthenticationMethod | Should -Be "FBA"
                    $result.Internet[2].AuthenticationMethod | Should -Be "Federated"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Internet Zone of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Internet  = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default", "Internet"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Internet[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Internet[0].WindowsAuthMethod | Should -Be "NTLM"
                    $result.Internet[1].AuthenticationMethod | Should -Be "FBA"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Set-SPWebApplication
                }
            }

            Context -Name "Extranet Zone of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Extranet  = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default", "Extranet"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Extranet[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Extranet[0].WindowsAuthMethod | Should -Be "NTLM"
                    $result.Extranet[1].AuthenticationMethod | Should -Be "FBA"
                    $result.Extranet[2].AuthenticationMethod | Should -Be "Federated"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Extranet Zone of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Extranet  = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default", "Extranet"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Extranet[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Extranet[0].WindowsAuthMethod | Should -Be "NTLM"
                    $result.Extranet[1].AuthenticationMethod | Should -Be "FBA"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Set-SPWebApplication
                }
            }

            Context -Name "Custom Zone of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Custom    = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "NTLM"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default", "Custom"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Custom[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Custom[0].WindowsAuthMethod | Should -Be "NTLM"
                    $result.Custom[1].AuthenticationMethod | Should -Be "FBA"
                    $result.Custom[2].AuthenticationMethod | Should -Be "Federated"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Custom Zone of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Custom    = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "WindowsAuthentication"
                                    WindowsAuthMethod    = "Kerberos"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod   = "Federated"
                                    AuthenticationProvider = "ADFS"
                                } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                                    AuthenticationMethod = "FBA"
                                    MembershipProvider   = "MemberProvider"
                                    RoleProvider         = "RoleProvider"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Keys = "Default", "Custom"
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $false
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Custom[0].AuthenticationMethod | Should -Be "WindowsAuthentication"
                    $result.Custom[0].WindowsAuthMethod | Should -Be "Kerberos"
                    $result.Custom[1].AuthenticationMethod | Should -Be "FBA"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Set-SPWebApplication
                }
            }

            Context -Name "Default Zone Settings of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl       = "http://sharepoint.contoso.com"
                        DefaultSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $false
                                CustomSignInPage           = ""
                                EnableClientIntegration    = $true
                                RequireUseRemoteInterfaces = $true
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Default  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Intranet = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.DefaultSettings.AnonymousAuthentication | Should -Be $false
                    $result.DefaultSettings.CustomSignInPage | Should -Be ""
                    $result.DefaultSettings.EnableClientIntegration | Should -Be $true
                    $result.DefaultSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Default Zone Settings of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl       = "http://sharepoint.contoso.com"
                        DefaultSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $true
                                CustomSignInPage           = "/signin"
                                EnableClientIntegration    = $false
                                RequireUseRemoteInterfaces = $false
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            IisSettings = @{
                                Default  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Intranet = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $global:SPWebAppUpdateExecuted = $true
                        } -PassThru -Force

                        return $returnval
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.DefaultSettings.AnonymousAuthentication | Should -Be $false
                    $result.DefaultSettings.CustomSignInPage | Should -Be ""
                    $result.DefaultSettings.EnableClientIntegration | Should -Be $true
                    $result.DefaultSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    $global:SPWebAppUpdateExecuted = $false
                    Set-TargetResource @testParams
                    $global:SPWebAppUpdateExecuted | Should -Be $true
                }
            }

            Context -Name "Intranet Zone Settings of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        IntranetSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $false
                                CustomSignInPage           = ""
                                EnableClientIntegration    = $true
                                RequireUseRemoteInterfaces = $true
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Default  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Intranet = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.IntranetSettings.AnonymousAuthentication | Should -Be $false
                    $result.IntranetSettings.CustomSignInPage | Should -Be ""
                    $result.IntranetSettings.EnableClientIntegration | Should -Be $true
                    $result.IntranetSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Intranet Zone Settings of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        IntranetSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $true
                                CustomSignInPage           = "/signin"
                                EnableClientIntegration    = $false
                                RequireUseRemoteInterfaces = $false
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            IisSettings = @{
                                Default  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Intranet = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $global:SPWebAppUpdateExecuted = $true
                        } -PassThru -Force

                        return $returnval
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.IntranetSettings.AnonymousAuthentication | Should -Be $false
                    $result.IntranetSettings.CustomSignInPage | Should -Be ""
                    $result.IntranetSettings.EnableClientIntegration | Should -Be $true
                    $result.IntranetSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    $global:SPWebAppUpdateExecuted = $false
                    Set-TargetResource @testParams
                    $global:SPWebAppUpdateExecuted | Should -Be $true
                }
            }

            Context -Name "Internet Zone Settings of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        InternetSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $false
                                CustomSignInPage           = ""
                                EnableClientIntegration    = $true
                                RequireUseRemoteInterfaces = $true
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Default  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Internet = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.InternetSettings.AnonymousAuthentication | Should -Be $false
                    $result.InternetSettings.CustomSignInPage | Should -Be ""
                    $result.InternetSettings.EnableClientIntegration | Should -Be $true
                    $result.InternetSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Internet Zone Settings of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        InternetSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $true
                                CustomSignInPage           = "/signin"
                                EnableClientIntegration    = $false
                                RequireUseRemoteInterfaces = $false
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            IisSettings = @{
                                Default  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Internet = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $global:SPWebAppUpdateExecuted = $true
                        } -PassThru -Force

                        return $returnval
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.InternetSettings.AnonymousAuthentication | Should -Be $false
                    $result.InternetSettings.CustomSignInPage | Should -Be ""
                    $result.InternetSettings.EnableClientIntegration | Should -Be $true
                    $result.InternetSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    $global:SPWebAppUpdateExecuted = $false
                    Set-TargetResource @testParams
                    $global:SPWebAppUpdateExecuted | Should -Be $true
                }
            }

            Context -Name "Extranet Zone Settings of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        ExtranetSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $false
                                CustomSignInPage           = ""
                                EnableClientIntegration    = $true
                                RequireUseRemoteInterfaces = $true
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Default  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Extranet = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.ExtranetSettings.AnonymousAuthentication | Should -Be $false
                    $result.ExtranetSettings.CustomSignInPage | Should -Be ""
                    $result.ExtranetSettings.EnableClientIntegration | Should -Be $true
                    $result.ExtranetSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Extranet Zone Settings of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        ExtranetSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $true
                                CustomSignInPage           = "/signin"
                                EnableClientIntegration    = $false
                                RequireUseRemoteInterfaces = $false
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            IisSettings = @{
                                Default  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Extranet = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $global:SPWebAppUpdateExecuted = $true
                        } -PassThru -Force

                        return $returnval
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.ExtranetSettings.AnonymousAuthentication | Should -Be $false
                    $result.ExtranetSettings.CustomSignInPage | Should -Be ""
                    $result.ExtranetSettings.EnableClientIntegration | Should -Be $true
                    $result.ExtranetSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    $global:SPWebAppUpdateExecuted = $false
                    Set-TargetResource @testParams
                    $global:SPWebAppUpdateExecuted | Should -Be $true
                }
            }

            Context -Name "Custom Zone Settings of Web application is configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl      = "http://sharepoint.contoso.com"
                        CustomSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $false
                                CustomSignInPage           = ""
                                EnableClientIntegration    = $true
                                RequireUseRemoteInterfaces = $true
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @{
                            IisSettings = @{
                                Default = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Custom  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            },
                            @{
                                DisplayName = "ADFS"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.CustomSettings.AnonymousAuthentication | Should -Be $false
                    $result.CustomSettings.CustomSignInPage | Should -Be ""
                    $result.CustomSettings.EnableClientIntegration | Should -Be $true
                    $result.CustomSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Custom Zone Settings of Web application is not configured as specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl      = "http://sharepoint.contoso.com"
                        CustomSettings = (New-CimInstance -ClassName MSFT_SPWebAppZoneSettings -Property @{
                                AnonymousAuthentication    = $true
                                CustomSignInPage           = "/signin"
                                EnableClientIntegration    = $false
                                RequireUseRemoteInterfaces = $false
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            IisSettings = @{
                                Default = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                                Custom  = @{
                                    AllowAnonymous                                   = $false
                                    ClaimsAuthenticationRedirectionUrl               = ""
                                    EnableClientIntegration                          = $true
                                    ClientObjectModelRequiresUseRemoteAPIsPermission = $true
                                }
                            }
                        }
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $global:SPWebAppUpdateExecuted = $true
                        } -PassThru -Force

                        return $returnval
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @(
                            @{
                                DisplayName       = "Windows Authentication"
                                ClaimProviderName = 'AD'
                                DisableKerberos   = $true
                            },
                            @{
                                DisplayName        = "Forms Authentication"
                                ClaimProviderName  = 'Forms'
                                RoleProvider       = "RoleProvider"
                                MembershipProvider = "MemberProvider"
                            }
                        )
                    }

                    Mock -CommandName New-SPAuthenticationProvider -MockWith { return @{ } }
                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return @{ } }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.CustomSettings.AnonymousAuthentication | Should -Be $false
                    $result.CustomSettings.CustomSignInPage | Should -Be ""
                    $result.CustomSettings.EnableClientIntegration | Should -Be $true
                    $result.CustomSettings.RequireUseRemoteInterfaces | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should run the Set-SPWebApplication cmdlet in the set method" {
                    $global:SPWebAppUpdateExecuted = $false
                    Set-TargetResource @testParams
                    $global:SPWebAppUpdateExecuted | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
