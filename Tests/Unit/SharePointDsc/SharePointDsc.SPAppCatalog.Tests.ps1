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
                                              -DscResource "SPAppCatalog"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        $mockSiteId = [Guid]::NewGuid()
        
        # Test contexts 
        Context -Name "The specified site exists, but cannot be set as an app catalog as it is of the wrong template" -Fixture {
            $testParams = @{
                SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
            }

            Mock -CommandName Update-SPAppCatalogConfiguration -MockWith { throw 'Exception' }
            Mock -CommandName Get-SPSite -MockWith {
                return @{
                    WebApplication = @{
                        Features = @( @{} ) | Add-Member -MemberType ScriptMethod `
                                                         -Name "Item" `
                                                         -Value { return $null } `
                                                         -PassThru `
                                                         -Force
                    }
                    ID = $mockSiteId
                }
            }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).SiteUrl | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception when executed" {
                { Set-TargetResource @testParams } | Should throw
            }
        }

        Context -Name "The specified site exists but is not set as the app catalog for its web application" -Fixture {
            $testParams = @{
                SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
            }

            Mock -CommandName Update-SPAppCatalogConfiguration -MockWith { }
            Mock -CommandName Get-SPSite -MockWith {
                return @{
                    WebApplication = @{
                        Features = @( @{} ) | Add-Member -MemberType ScriptMethod `
                                                         -Name "Item" `
                                                         -Value { return $null } `
                                                         -PassThru `
                                                         -Force
                    }
                    ID = $mockSiteId
                }
            }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).SiteUrl | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the settings in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Update-SPAppCatalogConfiguration
            }

        }
        
        Context -Name "The specified site exists and is the current app catalog already" -Fixture {
            $testParams = @{
                SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
            }

            Mock -CommandName Get-SPSite -MockWith {
                return @{
                    WebApplication = @{
                        Features = @( @{} ) | Add-Member -MemberType ScriptMethod `
                                                         -Name "Item" `
                                                         -Value { 
                                                             return @{ 
                                                                ID = [guid]::NewGuid()
                                                                Properties = @{
                                                                    "__AppCatSiteId" = @{Value = $mockSiteId} 
                                                                }
                                                            } 
                                                         } `
                                                         -PassThru `
                                                         -Force
                    }
                    ID = $mockSiteId
                    Url = $testParams.SiteUrl
                }
            }

            It "Should return value from the get method" {
                (Get-TargetResource @testParams).SiteUrl | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The specified site exists and the resource tries to set the site using the farm account" -Fixture {

            $testParams = @{
                SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
            }

            Mock -CommandName Update-SPAppCatalogConfiguration -MockWith { 
                throw [System.UnauthorizedAccessException] "ACCESS IS DENIED"
            }
            Mock -CommandName Get-SPSite -MockWith {
                return @{
                    WebApplication = @{
                        Features = @( @{} ) | Add-Member -MemberType ScriptMethod `
                                                         -Name "Item" `
                                                         -Value { return $null } `
                                                         -PassThru `
                                                         -Force
                    }
                    ID = $mockSiteId
                }
            }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).SiteUrl | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw `
                    "This resource must be run as the farm account (not a setup account). " + `
                    "Please ensure either the PsDscRunAsCredential or InstallAccount " + `
                    "credentials are set to the farm account and run this resource again"
            } 
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
