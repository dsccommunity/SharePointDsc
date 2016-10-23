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
                                              -DscResource "SPSite"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts   
        Mock -CommandName New-SPSite -MockWith { }

        # Test contexts
        Context -Name "The site doesn't exist yet and should" -Fixture {
            $testParams = @{
                Url = "http://site.sharepoint.com"
                OwnerAlias = "DEMO\User"
            }

            Mock -CommandName Get-SPSite -MockWith { return $null }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new site from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPSite
            }
        }

        Context -Name "The site exists and is a host named site collection" -Fixture {
            $testParams = @{
                Url = "http://site.sharepoint.com"
                OwnerAlias = "DEMO\User"
            }
            
            Mock -CommandName Get-SPSite -MockWith { 
                return @{
                    HostHeaderIsSiteName = $true
                    WebApplication = @{ 
                        Url = $testParams.Url 
                        UseClaimsAuthentication = $false
                    }
                    Url = $testParams.Url
                    Owner = @{ UserLogin = "DEMO\owner" }
                }
            }

            It "Should return the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The site exists and uses claims authentication" -Fixture {
            $testParams = @{
                Url = "http://site.sharepoint.com"
                OwnerAlias = "DEMO\User"
            }
            
            Mock -CommandName Get-SPSite -MockWith { 
                return @{
                    HostHeaderIsSiteName = $false
                    WebApplication = @{ 
                        Url = $testParams.Url 
                        UseClaimsAuthentication = $true
                    }
                    Url = $testParams.Url
                    Owner = @{ UserLogin = "DEMO\owner" }
                }
            }

            Mock -CommandName New-SPClaimsPrincipal -MockWith { 
                return @{ 
                    Value = $testParams.OwnerAlias 
                }
            }

            It "Should return the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock -CommandName Get-SPSite -MockWith { 
                return @{
                    HostHeaderIsSiteName = $false
                    WebApplication = @{ 
                        Url = $testParams.Url 
                        UseClaimsAuthentication = $true
                    }
                    Url = $testParams.Url
                    Owner = $null
                }
            }

            It "Should return the site data from the get method where a valid site collection admin does not exist" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
            
            Mock -CommandName Get-SPSite -MockWith { 
                return @{
                    HostHeaderIsSiteName = $false
                    WebApplication = @{ 
                        Url = $testParams.Url 
                        UseClaimsAuthentication = $true
                    }
                    Url = $testParams.Url
                    Owner = @{ UserLogin = "DEMO\owner" }
                    SecondaryContact = @{ UserLogin = "DEMO\secondary" }
                }
            }

            It "Should return the site data from the get method where a secondary site contact exists" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
        }

        Context -Name "The site exists and uses classic authentication" -Fixture {
            $testParams = @{
                Url = "http://site.sharepoint.com"
                OwnerAlias = "DEMO\User"
            }
            
            Mock -CommandName Get-SPSite -MockWith { 
                return @{
                    HostHeaderIsSiteName = $false
                    WebApplication = @{ 
                        Url = $testParams.Url 
                        UseClaimsAuthentication = $false
                    }
                    Url = $testParams.Url
                    Owner = @{ UserLogin = "DEMO\owner" }
                }
            }

            It "Should return the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock -CommandName Get-SPSite -MockWith { 
                return @{
                    HostHeaderIsSiteName = $false
                    WebApplication = @{ 
                        Url = $testParams.Url 
                        UseClaimsAuthentication = $false
                    }
                    Url = $testParams.Url
                    Owner = @{ UserLogin = "DEMO\owner" }
                    SecondaryContact = @{ UserLogin = "DEMO\secondary" }
                }
            }

            It "Should return the site data from the get method where a secondary site contact exists" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
