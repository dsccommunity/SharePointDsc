[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
    -DscResource "SPWebAppAuthentication"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts
        Mock -CommandName Set-SPWebApplication { }

        # Test contexts
        Context -Name "The web application doesn't exist" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Default   = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default | Should BeNullOrEmpty
                $result.Intranet | Should BeNullOrEmpty
                $result.Extranet | Should BeNullOrEmpty
                $result.Internet | Should BeNullOrEmpty
                $result.Custom | Should BeNullOrEmpty
                $result.WebAppUrl | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Specified Web Application $($testparams.WebAppUrl) does not exist"
            }
        }

        Context -Name "AuthenticationMethod=NTLM used with AuthenticationProvider parameter" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Default   = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod   = "NTLM"
                            AuthenticationProvider = "INCORRECT"
                        } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default | Should BeNullOrEmpty
                $result.Intranet | Should BeNullOrEmpty
                $result.Extranet | Should BeNullOrEmpty
                $result.Internet | Should BeNullOrEmpty
                $result.Custom | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You cannot use AuthenticationProvider, MembershipProvider or RoleProvider when using NTLM"
            }
        }

        Context -Name "AuthenticationMethod=Kerberos used with MembershipProvider parameter" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Default   = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "Kerberos"
                            MembershipProvider   = "INCORRECT"
                        } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default | Should BeNullOrEmpty
                $result.Intranet | Should BeNullOrEmpty
                $result.Extranet | Should BeNullOrEmpty
                $result.Internet | Should BeNullOrEmpty
                $result.Custom | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You cannot use AuthenticationProvider, MembershipProvider or RoleProvider when using Kerberos"
            }
        }

        Context -Name "AuthenticationMethod=FBA used with AuthenticationProvider parameter" -Fixture {
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default | Should BeNullOrEmpty
                $result.Intranet | Should BeNullOrEmpty
                $result.Extranet | Should BeNullOrEmpty
                $result.Internet | Should BeNullOrEmpty
                $result.Custom | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You cannot use AuthenticationProvider when using FBA"
            }
        }

        Context -Name "AuthenticationMethod=Federated used with RoleProvider parameter" -Fixture {
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default | Should BeNullOrEmpty
                $result.Intranet | Should BeNullOrEmpty
                $result.Extranet | Should BeNullOrEmpty
                $result.Internet | Should BeNullOrEmpty
                $result.Custom | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You cannot use MembershipProvider or RoleProvider when using Federated"
            }
        }

        Context -Name "AuthenticationMethod=FBA and missing MembershipProvider parameter" -Fixture {
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default | Should BeNullOrEmpty
                $result.Intranet | Should BeNullOrEmpty
                $result.Extranet | Should BeNullOrEmpty
                $result.Internet | Should BeNullOrEmpty
                $result.Custom | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You have to specify MembershipProvider and RoleProvider when using FBA"
            }
        }

        Context -Name "AuthenticationMethod=Federated and missing AuthenticationProvider parameter" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Default   = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "Federated"
                        } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default | Should BeNullOrEmpty
                $result.Intranet | Should BeNullOrEmpty
                $result.Extranet | Should BeNullOrEmpty
                $result.Internet | Should BeNullOrEmpty
                $result.Custom | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You have to specify AuthenticationProvider when using Federated"
            }
        }

        Context -Name "AuthenticationMethod=Federated and missing AuthenticationProvider parameter" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Default   = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
                        } -ClientOnly),
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "Kerberos"
                        } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default | Should BeNullOrEmpty
                $result.Intranet | Should BeNullOrEmpty
                $result.Extranet | Should BeNullOrEmpty
                $result.Internet | Should BeNullOrEmpty
                $result.Custom | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You cannot use both NTLM and Kerberos in the same zone"
            }
        }

        Context -Name "No zones are specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should throw exception in the get method" {
                $result = Get-TargetResource @testParams
                $result.Default | Should BeNullOrEmpty
                $result.Intranet | Should BeNullOrEmpty
                $result.Extranet | Should BeNullOrEmpty
                $result.Internet | Should BeNullOrEmpty
                $result.Custom | Should BeNullOrEmpty
            }

            It "Should throw exception in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You have to specify at least one zone."
            }
        }

        Context -Name "WebApplication is Classic, but Default Zone config is Claims" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Default   = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default[0].AuthenticationMethod | Should Be "Classic"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should run the Set-SPWebApplication cmdlet in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Specified Web Application is using Classic Authentication and Claims Authentication is specified."
            }
        }

        Context -Name "Default Zone of Web application is configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Default   = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default[0].AuthenticationMethod | Should Be "NTLM"
                $result.Default[1].AuthenticationMethod | Should Be "FBA"
                $result.Default[2].AuthenticationMethod | Should Be "Federated"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Specified Federated AuthenticationProvider does not exist" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Default   = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Specified AuthenticationProvider ADFS does not exist"
            }
        }

        Context -Name "Default Zone of Web application is not configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Default   = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Default[0].AuthenticationMethod | Should Be "NTLM"
                $result.Default[1].AuthenticationMethod | Should Be "FBA"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should run the Set-SPWebApplication cmdlet in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPWebApplication
            }
        }

        Context -Name "Intranet Zone of Web application is configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Intranet  = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Intranet[0].AuthenticationMethod | Should Be "NTLM"
                $result.Intranet[1].AuthenticationMethod | Should Be "FBA"
                $result.Intranet[2].AuthenticationMethod | Should Be "Federated"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Intranet Zone of Web application is not configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Intranet  = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Intranet[0].AuthenticationMethod | Should Be "NTLM"
                $result.Intranet[1].AuthenticationMethod | Should Be "FBA"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should run the Set-SPWebApplication cmdlet in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPWebApplication
            }
        }

        Context -Name "Internet Zone of Web application is configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Internet  = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Internet[0].AuthenticationMethod | Should Be "NTLM"
                $result.Internet[1].AuthenticationMethod | Should Be "FBA"
                $result.Internet[2].AuthenticationMethod | Should Be "Federated"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Internet Zone of Web application is not configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Internet  = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Internet[0].AuthenticationMethod | Should Be "NTLM"
                $result.Internet[1].AuthenticationMethod | Should Be "FBA"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should run the Set-SPWebApplication cmdlet in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPWebApplication
            }
        }

        Context -Name "Extranet Zone of Web application is configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Extranet  = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Extranet[0].AuthenticationMethod | Should Be "NTLM"
                $result.Extranet[1].AuthenticationMethod | Should Be "FBA"
                $result.Extranet[2].AuthenticationMethod | Should Be "Federated"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Extranet Zone of Web application is not configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Extranet  = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Extranet[0].AuthenticationMethod | Should Be "NTLM"
                $result.Extranet[1].AuthenticationMethod | Should Be "FBA"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should run the Set-SPWebApplication cmdlet in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPWebApplication
            }
        }

        Context -Name "Custom Zone of Web application is configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Custom    = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "NTLM"
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Custom[0].AuthenticationMethod | Should Be "NTLM"
                $result.Custom[1].AuthenticationMethod | Should Be "FBA"
                $result.Custom[2].AuthenticationMethod | Should Be "Federated"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Custom Zone of Web application is not configured as specified" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sharepoint.contoso.com"
                Custom    = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                            AuthenticationMethod = "Kerberos"
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
                        DisableKerberos = $false
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

            It "Should return null from the get method" {
                $result = Get-TargetResource @testParams
                $result.Custom[0].AuthenticationMethod | Should Be "Kerberos"
                $result.Custom[1].AuthenticationMethod | Should Be "FBA"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should run the Set-SPWebApplication cmdlet in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPWebApplication
            }
        }

    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
