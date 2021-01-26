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
                                    @{ Path = "C:\inetpub\wwwroot\something" }
                                )
                                Url              = $testParams.WebAppUrl
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
                                    @{ Path = "C:\inetpub\wwwroot\something" }
                                )
                                Url              = $testParams.WebAppUrl
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
                                    @{ Path = "C:\inetpub\wwwroot\something" }
                                )
                                Url              = $testParams.WebAppUrl
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
                                    @{ Path = "C:\inetpub\wwwroot\something" }
                                )
                                Url              = $testParams.WebAppUrl
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
                                    @{ Path = "C:\inetpub\wwwroot\something" }
                                )
                                Url                     = $testParams.WebAppUrl
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
                                    @{ Path = "C:\inetpub\wwwroot\something" }
                                )
                                Url                     = $testParams.WebAppUrl
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
                                    @{ Path = "C:\inetpub\wwwroot\something" }
                                )
                                Url                     = $testParams.WebAppUrl
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
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return false from the set method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name                   = "SharePoint Sites"
                            ApplicationPool        = "SharePoint Sites"
                            ApplicationPoolAccount = "CONTOSO\svcSPWebApp"
                            AllowAnonymous         = $false
                            DatabaseName           = "SP_Content_01"
                            DatabaseServer         = "SQL.contoso.local\SQLINSTANCE"
                            WebAppUrl              = "http://example.contoso.local"
                            HostHeader             = "http://example.contoso.local"
                            Path                   = "C:\InetPub\wwwroot"
                            Port                   = 80
                            UseClassic             = $false
                            Ensure                 = "Present"
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
            AllowAnonymous         = $False;
            ApplicationPool        = "SharePoint Sites";
            ApplicationPoolAccount = "CONTOSO\svcSPWebApp";
            DatabaseName           = "SP_Content_01";
            DatabaseServer         = $ConfigurationData.NonNodeData.DatabaseServer;
            Ensure                 = "Present";
            HostHeader             = "http://example.contoso.local";
            Name                   = "SharePoint Sites";
            Path                   = "C:\InetPub\wwwroot";
            Port                   = 80;
            PsDscRunAsCredential   = $Credsspfarm;
            UseClassic             = $False;
            WebAppUrl              = "http://example.contoso.local";
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
