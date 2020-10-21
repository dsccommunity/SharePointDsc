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
$script:DSCResourceName = 'SPSearchServiceSettings'
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
                $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @("DOMAIN\username", $mockPassword)

                # Mocks for all contexts

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
            Context -Name "The server is not part of SharePoint farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance      = "Yes"
                        PerformanceLevel      = "Maximum"
                        ContactEmail          = "sharepoint@contoso.com"
                        WindowsServiceAccount = $mockCredential
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw "Unable to detect local farm"
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.PerformanceLevel | Should -BeNullOrEmpty
                    $result.ContactEmail | Should -BeNullOrEmpty
                    $result.WindowsServiceAccount | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }
            }

            Context -Name "No optional parameters are specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.PerformanceLevel | Should -BeNullOrEmpty
                    $result.ContactEmail | Should -BeNullOrEmpty
                    $result.WindowsServiceAccount | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method to say parameters are required" {
                    { Set-TargetResource @testParams } | Should -Throw "You have to specify at least one of the following parameters:"
                }
            }

            Context -Name "When the configured settings are correct" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance      = "Yes"
                        PerformanceLevel      = "Maximum"
                        ContactEmail          = "sharepoint@contoso.com"
                        WindowsServiceAccount = $mockCredential
                    }

                    Mock -CommandName Get-SPEnterpriseSearchService -MockWith {
                        return @{
                            ProcessIdentity  = "DOMAIN\username"
                            ContactEmail     = $testParams.ContactEmail
                            PerformanceLevel = $testParams.PerformanceLevel
                        }
                    }
                }

                It "Should return the specified values in the get method" {
                    $result = Get-TargetResource @testParams
                    $result.PerformanceLevel | Should -Be "Maximum"
                    $result.ContactEmail | Should -Be "sharepoint@contoso.com"
                    $result.WindowsServiceAccount.UserName | Should -Be "DOMAIN\username"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When the PerformanceLevel is incorrect" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance      = "Yes"
                        PerformanceLevel      = "Maximum"
                        ContactEmail          = "sharepoint@contoso.com"
                        WindowsServiceAccount = $mockCredential
                    }

                    Mock -CommandName Get-SPEnterpriseSearchService -MockWith {
                        return @{
                            ProcessIdentity  = "DOMAIN\username"
                            ContactEmail     = "sharepoint@contoso.com"
                            PerformanceLevel = "Reduced"
                        }
                    }

                    Mock -CommandName Set-SPEnterpriseSearchService -MockWith { }
                }

                It "Should return the configured values from the Get method" {
                    $result = Get-TargetResource @testParams
                    $result.PerformanceLevel | Should -Be "Reduced"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should configure the desired values in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPEnterpriseSearchService
                }
            }

            Context -Name "When the WindowsServiceAccount is incorrect" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance      = "Yes"
                        PerformanceLevel      = "Maximum"
                        ContactEmail          = "sharepoint@contoso.com"
                        WindowsServiceAccount = $mockCredential
                    }

                    Mock -CommandName Get-SPEnterpriseSearchService -MockWith {
                        return @{
                            ProcessIdentity  = "DOMAIN\wrongusername"
                            ContactEmail     = "sharepoint@contoso.com"
                            PerformanceLevel = "Maximum"
                        }
                    }

                    Mock -CommandName Set-SPEnterpriseSearchService -MockWith { }
                }

                It "Should return the configured values from the Get method" {
                    $result = Get-TargetResource @testParams
                    $result.WindowsServiceAccount.UserName | Should -Be "DOMAIN\wrongusername"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should configure the desired values in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPEnterpriseSearchService
                }
            }

            Context -Name "When the ContactEmail is incorrect" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance      = "Yes"
                        PerformanceLevel      = "Maximum"
                        ContactEmail          = "sharepoint@contoso.com"
                        WindowsServiceAccount = $mockCredential
                    }

                    Mock -CommandName Get-SPEnterpriseSearchService -MockWith {
                        return @{
                            ProcessIdentity  = "DOMAIN\username"
                            ContactEmail     = "incorrect@contoso.com"
                            PerformanceLevel = "Maximum"
                        }
                    }

                    Mock -CommandName Set-SPEnterpriseSearchService -MockWith { }
                }

                It "Should return the configured values from the Get method" {
                    $result = Get-TargetResource @testParams
                    $result.ContactEmail | Should -Be "incorrect@contoso.com"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should configure the desired values in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPEnterpriseSearchService
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
