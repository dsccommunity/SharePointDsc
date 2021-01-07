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
$script:DSCResourceName = 'SPSearchCrawlRule'
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
                $getTypeFullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"

                # Mocks for all contexts
                Mock -CommandName Remove-SPEnterpriseSearchCrawlRule -MockWith { }
                Mock -CommandName New-SPEnterpriseSearchCrawlRule -MockWith { }
                Mock -CommandName Set-SPEnterpriseSearchCrawlRule -MockWith { }

                Mock -CommandName Get-SPServiceApplication -MockWith {
                    return @(
                        New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetType `
                                -Value {
                                New-Object -TypeName "Object" |
                                    Add-Member -MemberType NoteProperty `
                                        -Name FullName `
                                        -Value $getTypeFullName `
                                        -PassThru
                                } `
                                    -PassThru -Force)
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
            Context -Name "AuthenticationType=CertificateRuleAccess specified, but CertificateName missing" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Path                    = "http://www.contoso.com"
                        ServiceAppName          = "Search Service Application"
                        CrawlConfigurationRules = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                        AuthenticationType      = "CertificateRuleAccess"
                        Ensure                  = "Present"
                    }
                }

                It "Should return null from the Get method" {
                    { Get-TargetResource @testParams } | Should -Throw "When AuthenticationType=CertificateRuleAccess, the parameter CertificateName is required"
                }

                It "Should return false when the Test method is called" {
                    { Test-TargetResource @testParams } | Should -Throw "When AuthenticationType=CertificateRuleAccess, the parameter CertificateName is required"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "When AuthenticationType=CertificateRuleAccess, the parameter CertificateName is required"
                }
            }

            Context -Name "CertificateName specified, but AuthenticationType is not CertificateRuleAccess" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Path                    = "http://www.contoso.com"
                        ServiceAppName          = "Search Service Application"
                        CrawlConfigurationRules = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                        AuthenticationType      = "DefaultRuleAccess"
                        CertificateName         = "Test Certificate"
                        Ensure                  = "Present"
                    }
                }

                It "Should return null from the Get method" {
                    { Get-TargetResource @testParams } | Should -Throw "When specifying CertificateName, the AuthenticationType parameter is required"
                }

                It "Should return false when the Test method is called" {
                    { Test-TargetResource @testParams } | Should -Throw "When specifying CertificateName, the AuthenticationType parameter is required"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "When specifying CertificateName, the AuthenticationType parameter is required"
                }
            }

            Context -Name " AuthenticationType=NTLMAccountRuleAccess and AuthenticationCredentialsparameters not specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Path                    = "http://www.contoso.com"
                        ServiceAppName          = "Search Service Application"
                        CrawlConfigurationRules = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                        AuthenticationType      = "NTLMAccountRuleAccess"
                        Ensure                  = "Present"
                    }
                }

                It "Should return null from the Get method" {
                    { Get-TargetResource @testParams } | Should -Throw "When AuthenticationType is NTLMAccountRuleAccess or BasicAccountRuleAccess, the parameter AuthenticationCredentials is required"
                }

                It "Should return false when the Test method is called" {
                    { Test-TargetResource @testParams } | Should -Throw "When AuthenticationType is NTLMAccountRuleAccess or BasicAccountRuleAccess, the parameter AuthenticationCredentials is required"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "When AuthenticationType is NTLMAccountRuleAccess or BasicAccountRuleAccess, the parameter AuthenticationCredentials is required"
                }
            }

            Context -Name "AuthenticationCredentials parameters, but AuthenticationType is not NTLMAccountRuleAccess or BasicAccountRuleAccess" -Fixture {
                BeforeAll {
                    $User = "Domain01\User01"
                    $PWord = ConvertTo-SecureString -String "P@sSwOrd" -AsPlainText -Force
                    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

                    $testParams = @{
                        Path                      = "http://www.contoso.com"
                        ServiceAppName            = "Search Service Application"
                        CrawlConfigurationRules   = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                        AuthenticationType        = "DefaultRuleAccess"
                        AuthenticationCredentials = $Credential
                        Ensure                    = "Present"
                    }
                }

                It "Should return null from the Get method" {
                    { Get-TargetResource @testParams } | Should -Throw "When specifying AuthenticationCredentials, the AuthenticationType parameter is required"
                }

                It "Should return false when the Test method is called" {
                    { Test-TargetResource @testParams } | Should -Throw "When specifying AuthenticationCredentials, the AuthenticationType parameter is required"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "When specifying AuthenticationCredentials, the AuthenticationType parameter is required"
                }
            }

            Context -Name "ExclusionRule only with CrawlConfigurationRules=CrawlComplexUrls" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Path                    = "http://www.contoso.com"
                        ServiceAppName          = "Search Service Application"
                        CrawlConfigurationRules = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                        AuthenticationType      = "DefaultRuleAccess"
                        RuleType                = "ExclusionRule"
                        Ensure                  = "Present"
                    }
                }

                It "Should return null from the Get method" {
                    { Get-TargetResource @testParams } | Should -Throw "When RuleType=ExclusionRule, CrawlConfigurationRules cannot contain the values FollowLinksNoPageCrawl or CrawlAsHTTP"
                }

                It "Should return false when the Test method is called" {
                    { Test-TargetResource @testParams } | Should -Throw "When RuleType=ExclusionRule, CrawlConfigurationRules cannot contain the values FollowLinksNoPageCrawl or CrawlAsHTTP"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "When RuleType=ExclusionRule, CrawlConfigurationRules cannot contain the values FollowLinksNoPageCrawl or CrawlAsHTTP"
                }
            }

            Context -Name "ExclusionRule cannot be used with AuthenticationCredentials, CertificateName or AuthenticationType parameters" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Path                    = "http://www.contoso.com"
                        ServiceAppName          = "Search Service Application"
                        CrawlConfigurationRules = "CrawlComplexUrls"
                        AuthenticationType      = "DefaultRuleAccess"
                        RuleType                = "ExclusionRule"
                        Ensure                  = "Present"
                    }
                }

                It "Should return null from the Get method" {
                    { Get-TargetResource @testParams } | Should -Throw "When Type=ExclusionRule, parameters AuthenticationCredentials, CertificateName or AuthenticationType are not allowed"
                }

                It "Should return false when the Test method is called" {
                    { Test-TargetResource @testParams } | Should -Throw "When Type=ExclusionRule, parameters AuthenticationCredentials, CertificateName or AuthenticationType are not allowed"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "When Type=ExclusionRule, parameters AuthenticationCredentials, CertificateName or AuthenticationType are not allowed"
                }
            }

            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Path                    = "http://www.contoso.com"
                        ServiceAppName          = "Search Service Application"
                        RuleType                = "InclusionRule"
                        CrawlConfigurationRules = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                        AuthenticationType      = "DefaultRuleAccess"
                        Ensure                  = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPEnterpriseSearchCrawlRule
                }
            }

            Context -Name "When service applications exist in the current farm but the specific search app does not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Path                    = "http://www.contoso.com"
                        ServiceAppName          = "Search Service Application"
                        RuleType                = "InclusionRule"
                        CrawlConfigurationRules = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                        AuthenticationType      = "DefaultRuleAccess"
                        Ensure                  = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return @(@{
                                TypeName = "Some other service app type"
                            })
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPEnterpriseSearchCrawlRule
                }
            }

            Context -Name "When a crawl rule exists and is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Path                    = "http://www.contoso.com"
                        ServiceAppName          = "Search Service Application"
                        RuleType                = "InclusionRule"
                        CrawlConfigurationRules = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                        AuthenticationType      = "DefaultRuleAccess"
                        Ensure                  = "Present"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlRule -MockWith { return @{
                            Path               = "http://www.contoso.com"
                            Type               = "InclusionRule"
                            SuppressIndexing   = $true
                            FollowComplexUrls  = $true
                            CrawlAsHttp        = $true
                            AuthenticationType = "DefaultRuleAccess"
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When a crawl rule exists, but isn't configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Path                    = "http://www.contoso.com"
                        ServiceAppName          = "Search Service Application"
                        RuleType                = "InclusionRule"
                        CrawlConfigurationRules = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                        AuthenticationType      = "DefaultRuleAccess"
                        Ensure                  = "Present"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlRule -MockWith {
                        return @{
                            Path               = "http://www.contoso.com"
                            Type               = "InclusionRule"
                            SuppressIndexing   = $false
                            FollowComplexUrls  = $true
                            CrawlAsHttp        = $true
                            AuthenticationType = "DefaultRuleAccess"
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the update service app cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Set-SPEnterpriseSearchCrawlRule
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Path                    = "https://intranet.sharepoint.contoso.com"
                            ServiceAppName          = "Search Service Application"
                            Ensure                  = "Present"
                            RuleType                = "InclusionRule"
                            CrawlConfigurationRules = "FollowLinksNoPageCrawl", "CrawlComplexUrls", "CrawlAsHTTP"
                            AuthenticationType      = "DefaultRuleAccess"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = "Search Service Application"
                            Name        = "Search Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlRule -MockWith {
                        return @(
                            @{
                                Path = "https://intranet.sharepoint.contoso.com"
                            }
                        )
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPSearchCrawlRule [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            AuthenticationType      = "DefaultRuleAccess";
            CrawlConfigurationRules = \@\("FollowLinksNoPageCrawl","CrawlComplexUrls","CrawlAsHTTP"\);
            Ensure                  = "Present";
            Path                    = "https://intranet.sharepoint.contoso.com";
            PsDscRunAsCredential    = \$Credsspfarm;
            RuleType                = "InclusionRule";
            ServiceAppName          = "Search Service Application";
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
