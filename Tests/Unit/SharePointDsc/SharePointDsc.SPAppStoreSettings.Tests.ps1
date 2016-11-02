[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPAppStoreSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        
        # Mocks for all contexts   
        Mock -CommandName Set-SPAppAcquisitionConfiguration -MockWith {}
        Mock -CommandName Set-SPOfficeStoreAppsDefaultActivation -MockWith {}

        # Test contexts
        Context -Name "The specified web application does not exist" -Fixture {
            $testParams = @{
                WebAppUrl          = "https://sharepoint.contoso.com"
                AllowAppPurchases  = $true
                AllowAppsForOffice = $true
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                return $null
            }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).WebAppUrl | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception when executed" {
                { Set-TargetResource @testParams } | Should Throw "Specified web application does not exist."
            }
        }

        Context -Name "The specified settings do not match" -Fixture {
            $testParams = @{
                WebAppUrl          = "https://sharepoint.contoso.com"
                AllowAppPurchases  = $true
                AllowAppsForOffice = $true
            }

            Mock -CommandName Get-SPAppAcquisitionConfiguration -MockWith {
                return @{
                    Enabled = $false
                }
            }
            Mock -CommandName Get-SPOfficeStoreAppsDefaultActivation -MockWith {
                return @{
                    Enable = $false
                }
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                return @{
                    Url = "https://sharepoint.contoso.com"
                }
            }

            It "Should return values from the get method" {
                $result = Get-TargetResource @testParams 
                $result.AllowAppPurchases | Should Be $false
                $result.AllowAppsForOffice | Should Be $false
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPAppAcquisitionConfiguration
                Assert-MockCalled Set-SPOfficeStoreAppsDefaultActivation
            }
        }
        
        Context -Name "The specified settings match" -Fixture {
            $testParams = @{
                WebAppUrl          = "https://sharepoint.contoso.com"
                AllowAppPurchases  = $true
                AllowAppsForOffice = $true
            }

            Mock -CommandName Get-SPAppAcquisitionConfiguration -MockWith {
                return @{
                    Enabled = $true
                }
            }
            Mock -CommandName Get-SPOfficeStoreAppsDefaultActivation -MockWith {
                return @{
                    Enable = $true
                }
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                return @{
                    Url = "https://sharepoint.contoso.com"
                }
            }

            It "Should return values from the get method" {
                $result = Get-TargetResource @testParams
                $result.AllowAppPurchases | Should Be $true
                $result.AllowAppsForOffice | Should Be $true
            }

            It "Should returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The specified setting does not match" -Fixture {
            $testParams = @{
                WebAppUrl          = "https://sharepoint.contoso.com"
                AllowAppPurchases  = $true
            }

            Mock -CommandName Get-SPAppAcquisitionConfiguration -MockWith {
                return @{
                    Enabled = $false
                }
            }
            Mock -CommandName Get-SPOfficeStoreAppsDefaultActivation -MockWith {
                return @{
                    Enable = $true
                }
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                return @{
                    Url = "https://sharepoint.contoso.com"
                }
            }

            It "Should return values from the get method" {
                $result = Get-TargetResource @testParams
                $result.AllowAppPurchases | Should Be $false
                $result.AllowAppsForOffice | Should Be $true
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPAppAcquisitionConfiguration
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
