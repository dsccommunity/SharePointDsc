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
                                              -DscResource "SPAlternateUrl"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts
        Mock -CommandName New-SPAlternateURL {}
        Mock -CommandName Set-SPAlternateURL {}
        Mock -CommandName Remove-SPAlternateURL {}
        
        # Test contexts 
        Context -Name "No alternate URL exists for the specified zone and web app, and there should be" -Fixture {
            $testParams = @{
                WebAppUrl = "http://test.constoso.local"
                Zone = "Default"
                Ensure = "Present"
                Url = "http://something.contoso.local"
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @()
            }                                    

            It "Should return an empty URL in the get method" {
                (Get-TargetResource @testParams).Url | Should BeNullOrEmpty 
            }

            It "Should return false from the test method" {
                Test-targetResource @testParams | Should Be $false
            }

            It "Should call the new function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAlternateURL
            }
        }

        Context -Name "A URL exists for the specified zone and web app, but the URL is wrong" -Fixture {
            $testParams = @{
                WebAppUrl = "http://test.constoso.local"
                Zone = "Default"
                Ensure = "Present"
                Url = "http://something.contoso.local"
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @(
                    @{
                        IncomingUrl = $testParams.WebAppUrl
                        Zone = $testParams.Zone
                        PublicUrl = "http://wrong.url"
                    }
                )
            }

            It "Should return the wrong URL in the get method" {
                (Get-TargetResource @testParams).Url | Should Not Be $testParams.Url 
            }

            It "Should return false from the test method" {
                Test-targetResource @testParams | Should Be $false
            }

            It "Should call the set cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPAlternateURL
            }
        }

        Context -Name "A URL exists for the specified zone and web app, and it is correct" -Fixture {
            $testParams = @{
                WebAppUrl = "http://test.constoso.local"
                Zone = "Default"
                Ensure = "Present"
                Url = "http://something.contoso.local"
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @(
                    @{
                        IncomingUrl = $testParams.WebAppUrl
                        Zone = $testParams.Zone
                        PublicUrl = $testParams.Url
                    }
                )
            }

            It "Should return the correct URL in the get method" {
                (Get-TargetResource @testParams).Url | Should Be $testParams.Url 
            }

            It "Should return true from the test method" {
                Test-targetResource @testParams | Should Be $true
            }
        }

        Context -Name "A URL exists for the specified zone and web app, and it should not" -Fixture {
            $testParams = @{
                WebAppUrl = "http://test.constoso.local"
                Zone = "Default"
                Ensure = "Absent"
                Url = "http://something.contoso.local"
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @(
                    @{
                        IncomingUrl = $testParams.WebAppUrl
                        Zone = $testParams.Zone
                        PublicUrl = $testParams.Url
                    }
                )
            }

            It "Should return false from the test method" {
                Test-targetResource @testParams | Should Be $false
            }

            It "Should call the remove cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPAlternateURL
            }
        }

        Context -Name "A URL does not exist for the current zone, and it should not" -Fixture {
            $testParams = @{
                WebAppUrl = "http://test.constoso.local"
                Zone = "Default"
                Ensure = "Absent"
                Url = "http://something.contoso.local"
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @()
            } 

            It "Should return the empty values in the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return true from the test method" {
                Test-targetResource @testParams | Should Be $true
            }

            $testParams = @{
                WebAppUrl = "http://test.constoso.local"
                Zone = "Default"
                Ensure = "Absent"
            }
            It "Should still return true from the test method with the URL property not provided" {
                Test-targetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "The default zone URL for a web app was changed using this resource" -Fixture {
            $testParams = @{
                WebAppUrl = "http://test.constoso.local"
                Zone = "Default"
                Ensure = "Present"
                Url = "http://something.contoso.local"
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @()
            } -ParameterFilter { $WebApplication -eq $testParams.WebAppUrl }
            Mock -CommandName Get-SPAlternateUrl  -MockWith {
                return @(
                    @{
                        IncomingUrl = $testParams.Url
                        Zone = $testParams.Zone
                        PublicUrl = $testParams.Url
                    }
                )
            } -ParameterFilter { $null -eq $WebApplication }
            
            It "Should still return true in the test method despite the web app URL being different" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
