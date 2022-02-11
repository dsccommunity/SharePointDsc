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
$script:DSCResourceName = 'SPWebApplication'
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
                Invoke-Command -Scriptblock $Global:SPDscHelper.InitializeScript -NoNewScope

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
                Mock -CommandName New-SPWebApplication -MockWith { }
                Mock -CommandName Remove-SPWebApplication -MockWith { }
                Mock -CommandName Get-SPManagedAccount -MockWith { }

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
            Context -Name "AllowLegacyEncryption used with other OS than Windows Server 2022" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        AllowLegacyEncryption  = $true
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPDscOSVersion -MockWith {
                        return @{
                            Major = 10
                            Minor = 0
                            Build = 17763
                        }
                    }
                }

                It "return AllowLegacyEncryption=Null from the get method" {
                    (Get-TargetResource @testParams).AllowLegacyEncryption | Should -BeNullOrEmpty
                }

                It "throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You cannot specify the AllowLegacyEncryption parameter when using Windows Server 2019 or earlier."
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16 -and
                $Global:SPDscHelper.CurrentStubBuildNumber.Build -gt 10000 -and
                $Global:SPDscHelper.CurrentStubBuildNumber.Build -lt 13000)
            {
                Context -Name "UseServerNameIndication used with SharePoint 2019" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name                    = "SharePoint Sites"
                            ApplicationPool         = "SharePoint Web Apps"
                            ApplicationPoolAccount  = "DEMO\ServiceAccount"
                            WebAppUrl               = "http://sites.sharepoint.com"
                            UseServerNameIndication = $true
                            Ensure                  = "Present"
                        }
                    }

                    It "return UseServerNameIndication=Null from the get method" {
                        (Get-TargetResource @testParams).UseServerNameIndication | Should -BeNullOrEmpty
                    }

                    It "retrieving Managed Account fails in the set method" {
                        { Set-TargetResource @testParams } | Should -Throw "The parameters AllowLegacyEncryption, CertificateThumbprint or UseServerNameIndication are only supported with SharePoint Server Subscription Edition."
                    }
                }
            }

            Context -Name "The specified Managed Account does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                    Mock -CommandName Get-SPDscContentService -MockWith {
                        return @{ Name = "PlaceHolder" }
                    }
                    Mock -CommandName Get-SPManagedAccount -MockWith {
                        Throw "No matching accounts were found"
                    }
                }

                It "retrieving Managed Account fails in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "The specified managed account was not found. Please make sure the managed account exists before continuing."
                }
            }

            Context -Name "The specified Managed Account does not exist and fails to resolve for unknown reason" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                    Mock -CommandName Get-SPDscContentService -MockWith {
                        return @{ Name = "PlaceHolder" }
                    }
                    Mock -CommandName Get-SPManagedAccount -MockWith {
                        Throw ""
                    }
                }

                It "retrieving Managed Account fails in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error occurred. Web application was not created. Error details:"
                }
            }

            Context -Name "The web application that uses NTLM doesn't exist but should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                    Mock -CommandName Get-SPDscContentService -MockWith {
                        return @{ Name = "PlaceHolder" }
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the new cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled New-SPWebApplication
                }

                It "Should call the new cmdlet from the set where anonymous authentication is requested" {
                    $testParams.Add("AllowAnonymous", $true)
                    Set-TargetResource @testParams

                    Assert-MockCalled New-SPWebApplication
                }
            }

            Context -Name "The web application that uses Kerberos doesn't exist but should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                    Mock -CommandName Get-SPDscContentService -MockWith {
                        return @{ Name = "PlaceHolder" }
                    }
                    Mock -CommandName Get-SPManagedAccount -MockWith { }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the new cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled New-SPWebApplication
                }
            }

            Context -Name "The web application does exist and should that uses Classic" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        UseClassic             = $true
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return @(@{
                                DisplayName      = $testParams.Name
                                ApplicationPool  = @{
                                    Name     = $testParams.ApplicationPool
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                ContentDatabases = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings      = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url              = $testParams.WebAppUrl
                                SiteDataServers  = @()
                            }) }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The web application does exist and should that uses NTLM" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{
                            DisableKerberos = $true
                            AllowAnonymous  = $false
                        }
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return @(@{
                                DisplayName      = $testParams.Name
                                ApplicationPool  = @{
                                    Name     = $testParams.ApplicationPool
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                ContentDatabases = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings      = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url              = $testParams.WebAppUrl
                                SiteDataServers  = @()
                            }) }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The web application does exist and should that uses Kerberos" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{
                            DisableKerberos = $false
                            AllowAnonymous  = $false
                        }
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return @(@{
                                DisplayName      = $testParams.Name
                                ApplicationPool  = @{
                                    Name     = $testParams.ApplicationPool
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                ContentDatabases = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings      = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url              = $testParams.WebAppUrl
                                SiteDataServers  = @()
                            }) }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A web application exists but shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Absent"
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{
                            DisplayName     = "Windows Authentication"
                            DisableKerberos = $true
                            AllowAnonymous  = $false
                        }
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return @(@{
                                DisplayName      = $testParams.Name
                                ApplicationPool  = @{
                                    Name     = $testParams.ApplicationPool
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                ContentDatabases = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings      = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url              = $testParams.WebAppUrl
                                SiteDataServers  = @()
                            }) }
                }

                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the web application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPWebApplication
                }
            }

            Context -Name "A web application doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Absent"
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The web application does exist and should that uses Claims" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{

                            DisplayName               = "TestProvider"
                            LoginProviderName         = "TestProvider"
                            ClaimProviderName         = "TestClaimProvider"
                            AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                                DisplayName             = $testParams.Name
                                ApplicationPool         = @{
                                    Name     = $testParams.ApplicationPool
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                UseClaimsAuthentication = $true
                                ContentDatabases        = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings             = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url                     = $testParams.WebAppUrl
                                SiteDataServers         = @()
                            }
                        ) }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The web application does exist and shouldn't that uses Claims" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Absent"
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{

                            DisplayName               = "TestProvider"
                            LoginProviderName         = "TestProvider"
                            ClaimProviderName         = "TestClaimProvider"
                            AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                                DisplayName             = $testParams.Name
                                ApplicationPool         = @{
                                    Name     = $testParams.ApplicationPool
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                UseClaimsAuthentication = $true
                                ContentDatabases        = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings             = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url                     = $testParams.WebAppUrl
                                SiteDataServers         = @()
                            }
                        ) }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "The web application doesn't exist and should that uses Claims" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                        DatabaseServer         = "sql.domain.local"
                        DatabaseName           = "SP_Content_01"
                        HostHeader             = "sites.sharepoint.com"
                        Path                   = "C:\inetpub\wwwroot\something"
                        Port                   = 80
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return @{
                            Name = $testParams.AuthenticationProvider
                        }
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{

                            DisplayName               = $testParams.AuthenticationProvider
                            LoginProviderName         = $testParams.AuthenticationProvider
                            ClaimProviderName         = "TestClaimProvider"
                            AuthenticationRedirectUrl = "/_trust/default.aspx?trust=$($testParams.AuthenticationProvider)"
                        }
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        @{
                            ApplicationPools = @(
                                @{
                                    Name = $testParams.ApplicationPool
                                },
                                @{
                                    Name = "Default App Pool"
                                },
                                @{
                                    Name = "SharePoint Token Service App Pool"
                                }
                            )
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return $null
                    }

                    Mock -CommandName New-SPWebApplication -MockWith {
                        return @(@{
                                DisplayName             = $testParams.Name
                                ApplicationPool         = @{
                                    Name     = $testParams.ApplicationPool
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                USeClaimsAuthentication = $true
                                ContentDatabases        = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings             = @(
                                    @{ Path = "C:\inetpub\wwwroot\something" }
                                )
                                Url                     = $testParams.WebAppUrl
                            }
                        )
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the new SPWebApplication cmdlet from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPWebApplication
                }
            }

            Context -Name "The web application doesn't exist and shouldn't that uses Claims" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Absent"
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{

                            DisplayName               = "TestProvider"
                            LoginProviderName         = "TestProvider"
                            ClaimProviderName         = "TestClaimProvider"
                            AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return $null
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The web application doesn't exists authentication method is specified with NTLM provider" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{
                            DisplayName     = "Windows Authentication"
                            DisableKerberos = $true
                            AllowAnonymous  = $false
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return $null
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "The web application does exist and authentication method is specified with Kerberos provider" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{
                            DisplayName     = "Windows Authentication"
                            DisableKerberos = $false
                            AllowAnonymous  = $false
                        }

                    }

                    Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                                DisplayName             = $testParams.Name
                                ApplicationPool         = @{
                                    Name     = $testParams.ApplicationPool
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                USeClaimsAuthentication = $false
                                ContentDatabases        = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings             = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url                     = $testParams.WebAppUrl
                                SiteDataServers         = @()
                            }
                        ) }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The web application does not exist and should that uses NTLM" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        Ensure                 = "Present"
                        DatabaseServer         = "sql.domain.local"
                        DatabaseName           = "SP_Content_01"
                        HostHeader             = "sites.sharepoint.com"
                        Path                   = "C:\inetpub\wwwroot\something"
                        Port                   = 80
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        return @{
                            ApplicationPools = @(
                                @{
                                    Name = $testParams.ApplicationPool
                                },
                                @{
                                    Name = "Default App Pool"
                                },
                                @{
                                    Name = "SharePoint Token Service App Pool"
                                }
                            )
                        }
                    }
                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{
                            DisplayName     = "Windows Authentication"
                            DisableKerberos = $true
                            AllowAnonymous  = $false
                        }
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return $null
                    }

                    Mock -CommandName New-SPWebapplication -MockWith {
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return false from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName New-SPWebApplication -Times 1
                }
            }

            Context -Name "The web application does exist and should, but has incorrect settings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        DatabaseName           = "SP_Content_00"
                        DatabaseServer         = "SQL01"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        SiteDataServers        = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppSiteDataServers -Property @{
                                Zone = "Default"
                                Uri  = "http://spwfe"
                            } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppSiteDataServers -Property @{
                                Zone = "Internet"
                                Uri  = "http://spwfe"
                            } -ClientOnly)
                        )
                        Ensure                 = "Present"
                    }

                    try
                    {
                        [Microsoft.SharePoint.Administration.SPWebService] | Out-Null
                    }
                    catch
                    {
                        Add-Type -TypeDefinition @"
                        namespace Microsoft.SharePoint.Administration
                        {
                            public class SPWebService {
                                public SPWebService() { }
                            }
                        }
"@
                    }

                    try
                    {
                        [Microsoft.SharePoint.Administration.SPApplicationPool] | Out-Null
                    }
                    catch
                    {
                        Add-Type -TypeDefinition @"
                        namespace Microsoft.SharePoint.Administration
                        {
                            public class SPApplicationPool {
                                public SPApplicationPool(System.String account, System.Object service) { }

                                public string CurrentIdentityType { get; set; }
                                public string Username { get; set; }
                                public void Update(bool force) { }
                                public void Provision() { }
                            }
                        }
"@
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{

                            DisplayName               = "TestProvider"
                            LoginProviderName         = "TestProvider"
                            ClaimProviderName         = "TestClaimProvider"
                            AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $sds = New-Object "System.Collections.Generic.Dictionary[[object],[System.Collections.Generic.List[System.Uri]]]"

                        $uriList = New-Object System.Collections.Generic.List[System.Uri](1)
                        $target = New-Object System.Uri("http://spbackend")
                        $target2 = New-Object System.Uri("http://spbackend2")
                        $uriList.Add($target)
                        $uriList.Add($target2)
                        $defaultZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Default"
                        $sds.Add($defaultZone, $uriList)
                        $intranetZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Intranet"
                        $sds.Add($intranetZone, $uriList)

                        $returnval = @(@{
                                DisplayName             = $testParams.Name
                                ApplicationPool         = @{
                                    Name     = "SharePoint Old AppPool"
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                UseClaimsAuthentication = $true
                                ContentDatabases        = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings             = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url                     = $testParams.WebAppUrl
                                SiteDataServers         = $sds
                            }
                        )
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $global:SPDscRanWebAppUpdate = $true
                        } -PassThru -Force | Add-Member -MemberType ScriptMethod `
                            -Name ProvisionGlobally `
                            -Value {
                        } -PassThru -Force

                        return $returnVal
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        $returnVal = @{
                            ApplicationPools = @(
                                @{
                                    Name = "SharePoint Old AppPool"
                                }
                            )
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscAntivirusUpdated = $true
                        } -PassThru
                        return $returnVal
                    }

                    Mock -CommandName Get-SPManagedAccount -MockWith {
                        return ""
                    }

                    Mock -CommandName Mount-SPContentDatabase -MockWith { }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                    $result.DatabaseName | Should -Be "SP_Content_01"
                    $result.ApplicationPool | Should -Be "SharePoint Old AppPool"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the new SPWebApplication cmdlet from the set method" {
                    $global:SPDscRanWebAppUpdate = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled Mount-SPContentDatabase
                    $global:SPDscRanWebAppUpdate | Should -Be $true
                }
            }

            Context -Name "Mounting of new database fails" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        DatabaseName           = "SP_Content_00"
                        DatabaseServer         = "SQL01"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        SiteDataServers        = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppSiteDataServers -Property @{
                                Zone = "Default"
                                Uri  = "http://spwfe"
                            } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppSiteDataServers -Property @{
                                Zone = "Internet"
                                Uri  = "http://spwfe"
                            } -ClientOnly)
                        )
                        Ensure                 = "Present"
                    }

                    try
                    {
                        [Microsoft.SharePoint.Administration.SPWebService] | Out-Null
                    }
                    catch
                    {
                        Add-Type -TypeDefinition @"
                        namespace Microsoft.SharePoint.Administration
                        {
                            public class SPWebService {
                                public SPWebService() { }
                            }
                        }
"@
                    }

                    try
                    {
                        [Microsoft.SharePoint.Administration.SPApplicationPool] | Out-Null
                    }
                    catch
                    {
                        Add-Type -TypeDefinition @"
                        namespace Microsoft.SharePoint.Administration
                        {
                            public class SPApplicationPool {
                                public SPApplicationPool(System.String account, System.Object service) { }

                                public string CurrentIdentityType { get; set; }
                                public string Username { get; set; }
                                public void Update(bool force) { }
                                public void Provision() { }
                            }
                        }
"@
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{

                            DisplayName               = "TestProvider"
                            LoginProviderName         = "TestProvider"
                            ClaimProviderName         = "TestClaimProvider"
                            AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $sds = New-Object "System.Collections.Generic.Dictionary[[object],[System.Collections.Generic.List[System.Uri]]]"

                        $uriList = New-Object System.Collections.Generic.List[System.Uri](1)
                        $target = New-Object System.Uri("http://spbackend")
                        $target2 = New-Object System.Uri("http://spbackend2")
                        $uriList.Add($target)
                        $uriList.Add($target2)
                        $defaultZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Default"
                        $sds.Add($defaultZone, $uriList)
                        $intranetZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Intranet"
                        $sds.Add($intranetZone, $uriList)

                        $returnval = @(@{
                                DisplayName             = $testParams.Name
                                ApplicationPool         = @{
                                    Name     = "SharePoint Old AppPool"
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                UseClaimsAuthentication = $true
                                ContentDatabases        = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings             = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url                     = $testParams.WebAppUrl
                                SiteDataServers         = $sds
                            }
                        )
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $global:SPDscRanWebAppUpdate = $true
                        } -PassThru -Force | Add-Member -MemberType ScriptMethod `
                            -Name ProvisionGlobally `
                            -Value {
                        } -PassThru -Force

                        return $returnVal
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        $returnVal = @{
                            ApplicationPools = @(
                                @{
                                    Name = "SharePoint Old AppPool"
                                }
                            )
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscAntivirusUpdated = $true
                        } -PassThru
                        return $returnVal
                    }

                    Mock -CommandName Get-SPManagedAccount -MockWith {
                        return ""
                    }

                    Mock -CommandName Mount-SPContentDatabase -MockWith {
                        throw
                    }
                }

                It "Should throw exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error occurred while mounting content database. Content database is not mounted. Error details:"
                }
            }

            Context -Name "Specified Managed Account does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                   = "SharePoint Sites"
                        ApplicationPool        = "SharePoint Web Apps"
                        ApplicationPoolAccount = "DEMO\ServiceAccount"
                        DatabaseName           = "SP_Content_00"
                        DatabaseServer         = "SQL01"
                        WebAppUrl              = "http://sites.sharepoint.com"
                        SiteDataServers        = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppSiteDataServers -Property @{
                                Zone = "Default"
                                Uri  = "http://spwfe"
                            } -ClientOnly),
                            (New-CimInstance -ClassName MSFT_SPWebAppSiteDataServers -Property @{
                                Zone = "Internet"
                                Uri  = "http://spwfe"
                            } -ClientOnly)
                        )
                        Ensure                 = "Present"
                    }

                    try
                    {
                        [Microsoft.SharePoint.Administration.SPWebService] | Out-Null
                    }
                    catch
                    {
                        Add-Type -TypeDefinition @"
                        namespace Microsoft.SharePoint.Administration
                        {
                            public class SPWebService {
                                public SPWebService() { }
                            }
                        }
"@
                    }

                    try
                    {
                        [Microsoft.SharePoint.Administration.SPApplicationPool] | Out-Null
                    }
                    catch
                    {
                        Add-Type -TypeDefinition @"
                        namespace Microsoft.SharePoint.Administration
                        {
                            public class SPApplicationPool {
                                public SPApplicationPool(System.String account, System.Object service) { }

                                public string CurrentIdentityType { get; set; }
                                public string Username { get; set; }
                                public void Update(bool force) { }
                                public void Provision() { }
                            }
                        }
"@
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{

                            DisplayName               = "TestProvider"
                            LoginProviderName         = "TestProvider"
                            ClaimProviderName         = "TestClaimProvider"
                            AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $sds = New-Object "System.Collections.Generic.Dictionary[[object],[System.Collections.Generic.List[System.Uri]]]"

                        $uriList = New-Object System.Collections.Generic.List[System.Uri](1)
                        $target = New-Object System.Uri("http://spbackend")
                        $target2 = New-Object System.Uri("http://spbackend2")
                        $uriList.Add($target)
                        $uriList.Add($target2)
                        $defaultZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Default"
                        $sds.Add($defaultZone, $uriList)
                        $intranetZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Intranet"
                        $sds.Add($intranetZone, $uriList)

                        $returnval = @(@{
                                DisplayName             = $testParams.Name
                                ApplicationPool         = @{
                                    Name     = "SharePoint Old AppPool"
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                UseClaimsAuthentication = $true
                                ContentDatabases        = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings             = @(
                                    @{
                                        Path           = "C:\inetpub\wwwroot\something"
                                        SecureBindings = @(
                                            @{
                                                Certificate             = @{
                                                    Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                }
                                                UseServerNameIndication = $false
                                                DisableLegacyTls        = $true
                                            }
                                        )
                                    }
                                )
                                Url                     = $testParams.WebAppUrl
                                SiteDataServers         = $sds
                            }
                        )
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $global:SPDscRanWebAppUpdate = $true
                        } -PassThru -Force | Add-Member -MemberType ScriptMethod `
                            -Name ProvisionGlobally `
                            -Value {
                        } -PassThru -Force

                        return $returnVal
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        $returnVal = @{
                            ApplicationPools = @(
                                @{
                                    Name = "SharePoint Old AppPool"
                                }
                            )
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscAntivirusUpdated = $true
                        } -PassThru
                        return $returnVal
                    }

                    Mock -CommandName Get-SPManagedAccount -MockWith {
                        return $null
                    }

                    Mock -CommandName Mount-SPContentDatabase -MockWith { }
                }

                It "Should throw exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified ApplicationPoolAccount '$($testParams.ApplicationPoolAccount)' is not a managed account"
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16 -and
                $Global:SPDscHelper.CurrentStubBuildNumber.Build -gt 13000)
            {
                Context -Name "The web application does not exist and uses the Certificate parameters (SPSE)" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name                    = "SharePoint Sites"
                            ApplicationPool         = "SharePoint Web Apps"
                            ApplicationPoolAccount  = "DEMO\ServiceAccount"
                            WebAppUrl               = "https://sites.sharepoint.com"
                            DatabaseServer          = "sql.domain.local"
                            DatabaseName            = "SP_Content_01"
                            Port                    = 80
                            HostHeader              = "sites.sharepoint.com"
                            AllowLegacyEncryption   = $true
                            CertificateThumbprint   = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                            UseServerNameIndication = $false
                            Path                    = "C:\inetpub\wwwroot\something"
                            Ensure                  = "Present"
                        }

                        Mock -CommandName Get-SPDscOSVersion -MockWith {
                            return @{
                                Major = 10
                                Minor = 0
                                Build = 20348
                            }
                        }

                        Mock -CommandName Get-SPDscContentService -MockWith {
                            return @{
                                ApplicationPools = @(
                                    @{
                                        Name = $testParams.ApplicationPool
                                    },
                                    @{
                                        Name = "Default App Pool"
                                    },
                                    @{
                                        Name = "SharePoint Token Service App Pool"
                                    }
                                )
                            }
                        }
                        Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                            return @{
                                DisplayName     = "Windows Authentication"
                                DisableKerberos = $true
                                AllowAnonymous  = $false
                            }
                        }

                        Mock -CommandName Get-SPCertificate -MockWith {
                            return @{
                                Thumbprint = $testParams.CertificateThumbprint
                            }
                        }

                        Mock -CommandName Get-SPWebApplication -MockWith {
                            return $null
                        }

                        Mock -CommandName New-SPWebApplication -MockWith {
                        }
                    }

                    It "Should return absent from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                    }

                    It "Should return false from the test method" {
                        Test-TargetResource @testParams | Should -Be $false
                    }

                    It "Should return false from the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled -CommandName New-SPWebApplication -Times 1
                    }
                }

                Context -Name "Specified CertificateThumbprint is not found while creating new web app (SPSE)" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name                    = "SharePoint Sites"
                            ApplicationPool         = "SharePoint Web Apps"
                            ApplicationPoolAccount  = "DEMO\ServiceAccount"
                            WebAppUrl               = "https://sites.sharepoint.com"
                            DatabaseServer          = "sql.domain.local"
                            DatabaseName            = "SP_Content_01"
                            Port                    = 80
                            HostHeader              = "sites.sharepoint.com"
                            AllowLegacyEncryption   = $true
                            CertificateThumbprint   = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                            UseServerNameIndication = $false
                            Path                    = "C:\inetpub\wwwroot\something"
                            Ensure                  = "Present"
                        }

                        Mock -CommandName Get-SPDscOSVersion -MockWith {
                            return @{
                                Major = 10
                                Minor = 0
                                Build = 20348
                            }
                        }

                        Mock -CommandName Get-SPDscContentService -MockWith {
                            return @{
                                ApplicationPools = @(
                                    @{
                                        Name = $testParams.ApplicationPool
                                    },
                                    @{
                                        Name = "Default App Pool"
                                    },
                                    @{
                                        Name = "SharePoint Token Service App Pool"
                                    }
                                )
                            }
                        }
                        Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                            return @{
                                DisplayName     = "Windows Authentication"
                                DisableKerberos = $true
                                AllowAnonymous  = $false
                            }
                        }

                        Mock -CommandName Get-SPCertificate -MockWith {
                            return $null
                        }

                        Mock -CommandName Get-SPWebApplication -MockWith {
                            return $null
                        }

                        Mock -CommandName New-SPWebApplication -MockWith {
                        }
                    }

                    It "Should call the new SPWebApplication cmdlet from the set method" {
                        { Set-TargetResource @testParams } | Should -Throw "No certificate found with the specified thumbprint: $($testParams.CertificateThumbprint). Make sure the certificate is added to Certificate Management first!"
                    }
                }

                Context -Name "Specified CertificateThumbprint is not found while updating web app (SPSE)" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name                    = "SharePoint Sites"
                            ApplicationPool         = "SharePoint Web Apps"
                            ApplicationPoolAccount  = "DEMO\ServiceAccount"
                            CertificateThumbprint   = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198E'
                            DatabaseName            = "SP_Content_00"
                            Port                    = 80
                            AllowLegacyEncryption   = $true
                            UseServerNameIndication = $true
                            WebAppUrl               = "https://sites.sharepoint.com"
                            Ensure                  = "Present"
                        }

                        try
                        {
                            [Microsoft.SharePoint.Administration.SPWebService] | Out-Null
                        }
                        catch
                        {
                            Add-Type -TypeDefinition @"
                            namespace Microsoft.SharePoint.Administration
                            {
                                public class SPWebService {
                                    public SPWebService() { }
                                }
                            }
"@
                        }

                        try
                        {
                            [Microsoft.SharePoint.Administration.SPApplicationPool] | Out-Null
                        }
                        catch
                        {
                            Add-Type -TypeDefinition @"
                            namespace Microsoft.SharePoint.Administration
                            {
                                public class SPApplicationPool {
                                    public SPApplicationPool(System.String account, System.Object service) { }

                                    public string CurrentIdentityType { get; set; }
                                    public string Username { get; set; }
                                    public void Update(bool force) { }
                                    public void Provision() { }
                                }
                        }
"@
                        }

                        Mock -CommandName Get-SPDscOSVersion -MockWith {
                            return @{
                                Major = 10
                                Minor = 0
                                Build = 20348
                            }
                        }

                        Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                            return @{

                                DisplayName               = "TestProvider"
                                LoginProviderName         = "TestProvider"
                                ClaimProviderName         = "TestClaimProvider"
                                AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                            }
                        }

                        Mock -CommandName Get-SPWebApplication -MockWith {
                            $sds = New-Object "System.Collections.Generic.Dictionary[[object],[System.Collections.Generic.List[System.Uri]]]"

                            $uriList = New-Object System.Collections.Generic.List[System.Uri](1)
                            $target = New-Object System.Uri("http://spbackend")
                            $target2 = New-Object System.Uri("http://spbackend2")
                            $uriList.Add($target)
                            $uriList.Add($target2)
                            $defaultZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Default"
                            $sds.Add($defaultZone, $uriList)
                            $intranetZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Intranet"
                            $sds.Add($intranetZone, $uriList)

                            $returnval = @(@{
                                    DisplayName             = $testParams.Name
                                    ApplicationPool         = @{
                                        Name     = $testParams.ApplicationPool
                                        Username = $testParams.ApplicationPoolAccount
                                    }
                                    UseClaimsAuthentication = $true
                                    ContentDatabases        = @(
                                        @{
                                            Name   = "SP_Content_00"
                                            Server = "sql.domain.local"
                                        }
                                    )
                                    IisSettings             = @(
                                        @{
                                            Path           = "C:\inetpub\wwwroot\something"
                                            SecureBindings = @(
                                                @{
                                                    Certificate             = @{
                                                        Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                    }
                                                    UseServerNameIndication = $false
                                                    DisableLegacyTls        = $true
                                                }
                                            )
                                        }
                                    )
                                    Url                     = $testParams.WebAppUrl
                                    SiteDataServers         = $sds
                                }
                            )
                            $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                                -Name Update `
                                -Value {
                                $global:SPDscRanWebAppUpdate = $true
                            } -PassThru -Force | Add-Member -MemberType ScriptMethod `
                                -Name ProvisionGlobally `
                                -Value {
                            } -PassThru -Force

                            return $returnVal
                        }

                        Mock -CommandName Get-SPDscContentService -MockWith {
                            $returnVal = @{
                                ApplicationPools = @(
                                    @{
                                        Name = "SharePoint Old AppPool"
                                    }
                                )
                            }
                            return $returnVal
                        }

                        Mock -CommandName Get-SPManagedAccount -MockWith {
                            return ""
                        }

                        Mock -CommandName Get-SPCertificate -MockWith {
                            return $null
                        }

                        Mock -CommandName Set-SPWebApplication -MockWith { }
                    }

                    It "Should call the new SPWebApplication cmdlet from the set method" {
                        { Set-TargetResource @testParams } | Should -Throw "No certificate found with the specified thumbprint: $($testParams.CertificateThumbprint). Make sure the certificate is added to Certificate Management first!"
                    }
                }

                Context -Name "The web application does exist and should, but has incorrect settings (SPSE)" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name                    = "SharePoint Sites"
                            ApplicationPool         = "SharePoint Web Apps"
                            ApplicationPoolAccount  = "DEMO\ServiceAccount"
                            CertificateThumbprint   = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198E'
                            DatabaseName            = "SP_Content_00"
                            Port                    = 80
                            AllowLegacyEncryption   = $true
                            UseServerNameIndication = $true
                            WebAppUrl               = "https://sites.sharepoint.com"
                            Ensure                  = "Present"
                        }

                        try
                        {
                            [Microsoft.SharePoint.Administration.SPWebService] | Out-Null
                        }
                        catch
                        {
                            Add-Type -TypeDefinition @"
                            namespace Microsoft.SharePoint.Administration
                            {
                                public class SPWebService {
                                    public SPWebService() { }
                                }
                            }
"@
                        }

                        try
                        {
                            [Microsoft.SharePoint.Administration.SPApplicationPool] | Out-Null
                        }
                        catch
                        {
                            Add-Type -TypeDefinition @"
                            namespace Microsoft.SharePoint.Administration
                            {
                                public class SPApplicationPool {
                                    public SPApplicationPool(System.String account, System.Object service) { }

                                    public string CurrentIdentityType { get; set; }
                                    public string Username { get; set; }
                                    public void Update(bool force) { }
                                    public void Provision() { }
                                }
                        }
"@
                        }

                        Mock -CommandName Get-SPDscOSVersion -MockWith {
                            return @{
                                Major = 10
                                Minor = 0
                                Build = 20348
                            }
                        }

                        Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                            return @{

                                DisplayName               = "TestProvider"
                                LoginProviderName         = "TestProvider"
                                ClaimProviderName         = "TestClaimProvider"
                                AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                            }
                        }

                        Mock -CommandName Get-SPWebApplication -MockWith {
                            $sds = New-Object "System.Collections.Generic.Dictionary[[object],[System.Collections.Generic.List[System.Uri]]]"

                            $uriList = New-Object System.Collections.Generic.List[System.Uri](1)
                            $target = New-Object System.Uri("http://spbackend")
                            $target2 = New-Object System.Uri("http://spbackend2")
                            $uriList.Add($target)
                            $uriList.Add($target2)
                            $defaultZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Default"
                            $sds.Add($defaultZone, $uriList)
                            $intranetZone = [Microsoft.SharePoint.Administration.SPUrlZone]"Intranet"
                            $sds.Add($intranetZone, $uriList)

                            $returnval = @(@{
                                    DisplayName             = $testParams.Name
                                    ApplicationPool         = @{
                                        Name     = $testParams.ApplicationPool
                                        Username = $testParams.ApplicationPoolAccount
                                    }
                                    UseClaimsAuthentication = $true
                                    ContentDatabases        = @(
                                        @{
                                            Name   = "SP_Content_00"
                                            Server = "sql.domain.local"
                                        }
                                    )
                                    IisSettings             = @(
                                        @{
                                            Path           = "C:\inetpub\wwwroot\something"
                                            SecureBindings = @(
                                                @{
                                                    Certificate             = @{
                                                        Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                                    }
                                                    UseServerNameIndication = $false
                                                    DisableLegacyTls        = $true
                                                }
                                            )
                                        }
                                    )
                                    Url                     = $testParams.WebAppUrl
                                    SiteDataServers         = $sds
                                }
                            )
                            $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                                -Name Update `
                                -Value {
                                $global:SPDscRanWebAppUpdate = $true
                            } -PassThru -Force | Add-Member -MemberType ScriptMethod `
                                -Name ProvisionGlobally `
                                -Value {
                            } -PassThru -Force

                            return $returnVal
                        }

                        Mock -CommandName Get-SPDscContentService -MockWith {
                            $returnVal = @{
                                ApplicationPools = @(
                                    @{
                                        Name = "SharePoint Old AppPool"
                                    }
                                )
                            }
                            return $returnVal
                        }

                        Mock -CommandName Get-SPManagedAccount -MockWith {
                            return ""
                        }

                        Mock -CommandName Get-SPCertificate -MockWith {
                            return ""
                        }

                        Mock -CommandName Set-SPWebApplication -MockWith { }
                    }

                    It "Should return present from the get method" {
                        $result = Get-TargetResource @testParams
                        $result.Ensure | Should -Be "Present"
                        $result.CertificateThumbprint | Should -Be "7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D"
                        $result.UseServerNameIndication | Should -Be $false
                        $result.AllowLegacyEncryption | Should -Be $false
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should -Be $false
                    }

                    It "Should call the new SPWebApplication cmdlet from the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled Set-SPWebApplication
                    }
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        $currentSDS = @()
                        $currentSDS += New-Object -TypeName PSObject -Property @{
                            Zone = "Default"
                            Uri  = "http://spbackend"
                        }
                        $currentSDS += New-Object -TypeName PSObject -Property @{
                            Zone = "Intranet"
                            Uri  = "http://spfrontend"
                        }

                        return @{
                            Name                    = "SharePoint Sites"
                            ApplicationPool         = "SharePoint Sites"
                            ApplicationPoolAccount  = "CONTOSO\svcSPWebApp"
                            AllowAnonymous          = $false
                            AllowLegacyEncryption   = $true
                            CertificateThumbprint   = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                            DatabaseName            = "SP_Content_01"
                            DatabaseServer          = "SQL.contoso.local\SQLINSTANCE"
                            WebAppUrl               = "http://example.contoso.local"
                            HostHeader              = "http://example.contoso.local"
                            Path                    = "C:\InetPub\wwwroot"
                            Port                    = 80
                            UseClassic              = $false
                            UseServerNameIndication = $false
                            SiteDataServers         = @(
                                @{
                                    Zone = "Default"
                                    Uri  = "http://spbackend"
                                }
                                @{
                                    Zone = "Intranet"
                                    Uri  = "http://spbackend2"
                                }
                            )
                            Ensure                  = "Present"
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $spWebApp = [PSCustomObject]@{
                            Name = "SharePoint Sites"
                            Url  = "http://example.contoso.local"
                        }
                        return $spWebApp
                    }

                    Mock -CommandName Read-TargetResource -MockWith { return "" }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    if ($null -eq (Get-Variable -Name 'ExtractionModeValue' -ErrorAction SilentlyContinue))
                    {
                        $Global:ExtractionModeValue = 1
                    }

                    if ($null -eq (Get-Variable -Name 'ComponentsToExtract' -ErrorAction SilentlyContinue))
                    {
                        $Global:ComponentsToExtract = @()
                    }

                    $result = @'
        SPWebApplication SharePointSites
        {
            AllowAnonymous          = $False;
            AllowLegacyEncryption   = $true;
            ApplicationPool         = "SharePoint Sites";
            ApplicationPoolAccount  = "CONTOSO\svcSPWebApp";
            CertificateThumbprint   = "7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D";
            DatabaseName            = "SP_Content_01";
            DatabaseServer          = $ConfigurationData.NonNodeData.DatabaseServer;
            Ensure                  = "Present";
            HostHeader              = "http://example.contoso.local";
            Name                    = "SharePoint Sites";
            Path                    = "C:\InetPub\wwwroot";
            Port                    = 80;
            PsDscRunAsCredential    = $Credsspfarm;
            SiteDataServers         = @(
                MSFT_SPWebAppSiteDataServers {
                    Zone = 'Default'
                    Uri = 'http://spbackend'
                }
                MSFT_SPWebAppSiteDataServers {
                    Zone = 'Intranet'
                    Uri = 'http://spbackend2'
                });
            UseClassic              = $False;
            UseServerNameIndication = $false;
            WebAppUrl               = "http://example.contoso.local";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Be $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
