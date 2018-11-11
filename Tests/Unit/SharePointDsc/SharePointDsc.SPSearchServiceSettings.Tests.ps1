[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
                                              -DscResource "SPSearchServiceSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @("DOMAIN\username", $mockPassword)

        # Mocks for all contexts

        # Test contexts

        Context -Name "When the configured settings are correct" -Fixture {
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

            It "Should return the specified values in the get method" {
                $result = Get-TargetResource @testParams
                $result.PerformanceLevel | Should Be "Maximum"
                $result.ContactEmail | Should Be "sharepoint@contoso.com"
                $result.WindowsServiceAccount.UserName | Should Be "DOMAIN\username"
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When the PerformanceLevel is incorrect" -Fixture {
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

            Mock -CommandName Set-SPEnterpriseSearchService -MockWith {}

            It "Should return the configured values from the Get method" {
                $result = Get-TargetResource @testParams
                $result.PerformanceLevel | Should Be "Reduced"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should configure the desired values in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPEnterpriseSearchService
            }
        }

        Context -Name "When the WindowsServiceAccount is incorrect" -Fixture {
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

            Mock -CommandName Set-SPEnterpriseSearchService -MockWith {}

            It "Should return the configured values from the Get method" {
                $result = Get-TargetResource @testParams
                $result.WindowsServiceAccount.UserName | Should Be "DOMAIN\wrongusername"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should configure the desired values in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPEnterpriseSearchService
            }
        }

        Context -Name "When the ContactEmail is incorrect" -Fixture {
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

            Mock -CommandName Set-SPEnterpriseSearchService -MockWith {}

            It "Should return the configured values from the Get method" {
                $result = Get-TargetResource @testParams
                $result.ContactEmail | Should Be "incorrect@contoso.com"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should configure the desired values in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPEnterpriseSearchService
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
