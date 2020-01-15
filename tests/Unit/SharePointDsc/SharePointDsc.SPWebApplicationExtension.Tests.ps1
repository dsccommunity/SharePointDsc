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
$script:DSCResourceName = 'SPWebApplicationExtension'
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
            -DscResource $script:DSCResourceName `
            -ModuleVersion $moduleVersionFolder
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

Invoke-TestSetup -ModuleVersion $moduleVersion

try
{
    Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
        InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
            Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

            # Initialize tests

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

            # Mocks for all contexts
            Mock -CommandName New-SPAuthenticationProvider -MockWith { }
            Mock -CommandName New-SPWebApplicationExtension -MockWith { }
            Mock -CommandName Remove-SPWebApplication -MockWith { }
            Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { }
            Mock -CommandName Set-SPWebApplication -MockWith { }



            # Test contexts
            Context -Name "The parent web application does not exist" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://nosuchwebapplication.sharepoint.com"
                    Name      = "Intranet Zone"
                    Url       = "http://intranet.sharepoint.com"
                    Zone      = "Intranet"
                    Ensure    = "Present"
                }

                Mock -CommandName Get-SPWebapplication -MockWith { return $null }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "retrieving non-existent web application fails in the set method" {
                    { Set-TargetResource @testParams } | Should Throw "Web Application with URL $($testParams.WebAppUrl) does not exist"
                }
            }

            Context -Name "The web application extension that uses NTLM authentication doesn't exist but should" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://company.sharepoint.com"
                    Name      = "Intranet Zone"
                    Url       = "http://intranet.sharepoint.com"
                    Zone      = "Intranet"
                    Ensure    = "Present"
                }

                Mock -CommandName Get-SPWebapplication -MockWith {
                    return @{
                        DisplayName = "Company SharePoint"
                        URL         = "http://company.sharepoint.com"
                        IISSettings = @()
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should call the new cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled New-SPWebApplicationExtension
                }

                $testParams.Add("AllowAnonymous", $true)
                It "Should call the new cmdlet from the set where anonymous authentication is requested" {
                    Set-TargetResource @testParams

                    Assert-MockCalled New-SPWebApplicationExtension
                }
            }

            Context -Name "The web application extension that uses Kerberos doesn't exist but should" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://company.sharepoint.com"
                    Name      = "Intranet Zone"
                    Url       = "http://intranet.sharepoint.com"
                    Zone      = "Intranet"
                    Ensure    = "Present"
                }

                Mock -CommandName Get-SPWebapplication -MockWith {
                    return @{
                        DisplayName = "Company SharePoint"
                        URL         = "http://company.sharepoint.com"
                        IISSettings = @()
                    }
                }


                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should call the new cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled New-SPWebApplicationExtension
                }
            }

            Context -Name "The web application extension does exist and should use NTLM without AllowAnonymous" -Fixture {
                $testParams = @{
                    WebAppUrl  = "http://company.sharepoint.com"
                    Name       = "Intranet Zone"
                    Url        = "http://intranet.sharepoint.com"
                    HostHeader = "intranet.sharepoint.com"
                    Zone       = "Intranet"
                    Ensure     = "Present"
                }

                Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                    return @{
                        DisplayName     = "Windows Authentication"
                        DisableKerberos = $true
                    }
                }

                Mock -CommandName Get-SPWebapplication -MockWith {
                    $IISSettings = @(
                        @{ }
                        @{
                            SecureBindings = @{ }
                            ServerBindings = @{
                                HostHeader = "intranet.sharepoint.com"
                                Port       = 80
                            }
                            AllowAnonymous = $false
                        })

                    return (
                        @{
                            DisplayName = "Company SharePoint"
                            URL         = "http://company.sharepoint.com"
                            IISSettings = $IISSettings
                        } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true } -PassThru
                    )
                }

                Mock -CommandName Get-SPAlternateUrl -MockWith {
                    return @{
                        PublicURL = $testParams.Url
                    }
                }



                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return AllowAnonymous False from the get method" {
                    (Get-TargetResource @testParams).AllowAnonymous | Should Be $false
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "The web application extension does exist and should use NTLM without AllowAnonymous and with HTTPS" -Fixture {
                $testParams = @{
                    WebAppUrl  = "http://company.sharepoint.com"
                    Name       = "Intranet Zone"
                    Url        = "https://intranet.sharepoint.com"
                    HostHeader = "intranet.sharepoint.com"
                    UseSSL     = $true
                    Zone       = "Intranet"
                    Ensure     = "Present"
                }

                Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                    return @{
                        DisplayName     = "Windows Authentication"
                        DisableKerberos = $true
                    }
                }

                Mock -CommandName Get-SPWebapplication -MockWith {
                    $IISSettings = @(
                        @{ }
                        @{
                            SecureBindings = @{
                                HostHeader = "intranet.sharepoint.com"
                                Port       = 443
                            }
                            ServerBindings = @{ }
                            AllowAnonymous = $false
                        })

                    return (
                        @{
                            DisplayName = "Company SharePoint"
                            URL         = "http://company.sharepoint.com"
                            IISSettings = $IISSettings
                        } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true } -PassThru
                    )
                }

                Mock -CommandName Get-SPAlternateUrl -MockWith {
                    return @{
                        PublicURL = $testParams.Url
                    }
                }



                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return AllowAnonymous False from the get method" {
                    (Get-TargetResource @testParams).AllowAnonymous | Should Be $false
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "The web application extension does exist and should use NTLM and AllowAnonymous" -Fixture {
                $testParams = @{
                    WebAppUrl  = "http://company.sharepoint.com"
                    Name       = "Intranet Zone"
                    Url        = "http://intranet.sharepoint.com"
                    HostHeader = "intranet.sharepoint.com"
                    Zone       = "Intranet"
                    Ensure     = "Present"
                }

                Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                    return @{
                        DisplayName     = "Windows Authentication"
                        DisableKerberos = $true
                        AllowAnonymous  = $true
                    }
                }

                Mock -CommandName Get-SPWebapplication -MockWith {
                    $IISSettings = @(
                        @{ }
                        @{
                            SecureBindings = @{ }
                            ServerBindings = @{
                                HostHeader = "intranet.sharepoint.com"
                                Port       = 80
                            }
                            AllowAnonymous = $true
                        })

                    return (
                        @{
                            DisplayName = "Company SharePoint"
                            URL         = "http://company.sharepoint.com"
                            IISSettings = $IISSettings
                        } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true } -PassThru
                    )
                }

                Mock -CommandName Get-SPAlternateUrl -MockWith {
                    return @{
                        PublicURL = $testParams.Url
                    }
                }



                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return AllowAnonymous True from the get method" {
                    (Get-TargetResource @testParams).AllowAnonymous | Should Be $true
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "The web application extension does exist and should use Kerberos without AllowAnonymous" -Fixture {
                $testParams = @{
                    WebAppUrl  = "http://company.sharepoint.com"
                    Name       = "Intranet Zone"
                    Url        = "http://intranet.sharepoint.com"
                    HostHeader = "intranet.sharepoint.com"
                    Zone       = "Intranet"
                    Ensure     = "Present"
                }

                Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                    return @{
                        DisplayName     = "Windows Authentication"
                        DisableKerberos = $false
                    }
                }

                Mock -CommandName Get-SPWebapplication -MockWith {
                    $IISSettings = @(
                        @{ }
                        @{
                            SecureBindings = @{ }
                            ServerBindings = @{
                                HostHeader = "intranet.sharepoint.com"
                                Port       = 80
                            }
                            AllowAnonymous = $false
                        })

                    return (
                        @{
                            DisplayName = "Company SharePoint"
                            URL         = "http://company.sharepoint.com"
                            IISSettings = $IISSettings
                        } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true } -PassThru
                    )
                }

                Mock -CommandName Get-SPAlternateUrl -MockWith {
                    return @{
                        PublicURL = $testParams.Url
                    }
                }



                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return AllowAnonymous False from the get method" {
                    (Get-TargetResource @testParams).AllowAnonymous | Should Be $false
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "The web application extension does exist and should use Kerberos and AllowAnonymous" -Fixture {
                $testParams = @{
                    WebAppUrl  = "http://company.sharepoint.com"
                    Name       = "Intranet Zone"
                    Url        = "http://intranet.sharepoint.com"
                    HostHeader = "intranet.sharepoint.com"
                    Zone       = "Intranet"
                    Ensure     = "Present"
                }

                Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                    return @{
                        DisplayName     = "Windows Authentication"
                        DisableKerberos = $false
                        AllowAnonymous  = $true
                    }
                }

                Mock -CommandName Get-SPWebapplication -MockWith {
                    $IISSettings = @(
                        @{ }
                        @{
                            SecureBindings = @{ }
                            ServerBindings = @{
                                HostHeader = "intranet.sharepoint.com"
                                Port       = 80
                            }
                            AllowAnonymous = $true
                        })

                    return (
                        @{
                            DisplayName = "Company SharePoint"
                            URL         = "http://company.sharepoint.com"
                            IISSettings = $IISSettings
                        } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true } -PassThru
                    )
                }

                Mock -CommandName Get-SPAlternateUrl -MockWith {
                    return @{
                        PublicURL = $testParams.Url
                    }
                }


                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return AllowAnonymous True from the get method" {
                    (Get-TargetResource @testParams).AllowAnonymous | Should Be $true
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "The web application extension does exist and should with mismatched AllowAnonymous" -Fixture {
                $testParams = @{
                    WebAppUrl      = "http://company.sharepoint.com"
                    Name           = "Intranet Zone"
                    Url            = "http://intranet.sharepoint.com"
                    HostHeader     = "intranet.sharepoint.com"
                    Zone           = "Intranet"
                    AllowAnonymous = $true
                    Ensure         = "Present"
                }

                Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                    return @{
                        DisplayName     = "Windows Authentication"
                        DisableKerberos = $true
                    }
                }

                Mock -CommandName Get-SPWebapplication -MockWith {
                    $IISSettings = @(
                        @{ }
                        @{
                            SecureBindings = @{ }
                            ServerBindings = @{
                                HostHeader = "intranet.sharepoint.com"
                                Port       = 80
                            }
                            AllowAnonymous = $false
                        })

                    return (
                        @{
                            DisplayName = "Company SharePoint"
                            URL         = "http://company.sharepoint.com"
                            IISSettings = $IISSettings
                        } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true } -PassThru
                    )
                }

                Mock -CommandName Get-SPAlternateUrl -MockWith {
                    return @{
                        PublicURL = $testParams.Url
                    }
                }


                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return AllowAnonymous False from the get method" {
                    (Get-TargetResource @testParams).AllowAnonymous | Should Be $false
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should update the web application extension settings in the set method" {
                    $Global:WebAppUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:WebAppUpdateCalled | Should Be $true
                }
            }

            Context -Name "The web application extension exists but shouldn't" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://company.sharepoint.com"
                    Name      = "Intranet Zone"
                    Url       = "http://intranet.sharepoint.com"
                    Zone      = "Intranet"
                    Ensure    = "Absent"
                }

                Mock -CommandName Get-SPWebapplication -MockWith {
                    $IISSettings = @(
                        @{ }
                        @{
                            SecureBindings = @{ }
                            ServerBindings = @{
                                HostHeader = "intranet.sharepoint.com"
                                Port       = 80
                            }
                        })

                    return @{
                        DisplayName = "Company SharePoint"
                        URL         = "http://company.sharepoint.com"
                        IISSettings = $IISSettings
                    }
                }


                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should remove the web application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPWebApplication
                }
            }

            Context -Name "A web application extension doesn't exist and shouldn't" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://company.sharepoint.com"
                    Name      = "Intranet Zone"
                    Url       = "http://intranet.sharepoint.com"
                    Zone      = "Intranet"
                    Ensure    = "Absent"
                }

                Mock -CommandName Get-SPWebapplication -MockWith {

                    return @{
                        DisplayName = "Company SharePoint"
                        URL         = "http://company.sharepoint.com"
                        IISSettings = @()
                    }
                }



                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
