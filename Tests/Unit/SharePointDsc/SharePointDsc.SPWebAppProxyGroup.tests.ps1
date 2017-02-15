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
                                              -DscResource "SPWebAppProxyGroup"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName Set-SPWebApplication -MockWith { }

        # Test contexts
        Context -Name "WebApplication does not exist" -Fixture {
            $testParams = @{
                WebAppUrl              = "https://web.contoso.com"
                ServiceAppProxyGroup      = "Web1ProxyGroup"
            }

            Mock -CommandName Get-SPWebApplication -MockWIth {}

            It "Should return null property from the get method" {
                (Get-TargetResource @testParams).WebAppUrl | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

        }

        Context -Name "WebApplication Proxy Group connection matches desired config" -Fixture {
            $testParams = @{
                WebAppUrl              = "https://web.contoso.com"
                ServiceAppProxyGroup      = "Web1ProxyGroup"
            }

            Mock -CommandName Get-SPWebApplication -MockWIth { 
                return @{ 
                    ServiceApplicationProxyGroup = @{ 
                        Name = "Web1ProxyGroup"
                    }
                }
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).ServiceAppProxyGroup | Should Be "Web1ProxyGroup"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "WebApplication Proxy Group connection does not match desired config" -Fixture {
            $testParams = @{
                WebAppUrl              = "https://web.contoso.com"
                ServiceAppProxyGroup      = "Default"
            }

            Mock -CommandName Get-SPWebApplication -MockWIth { 
                return @{ 
                    ServiceApplicationProxyGroup = @{ 
                        Name = "Web1ProxyGroup"
                    }
                } 
            }
            
            It "Should return values from the get method" {
                (Get-TargetResource @testParams).ServiceAppProxyGroup | Should Be "Web1ProxyGroup"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false 
            }
            
            It "Should update the webapplication from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPWebApplication
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
