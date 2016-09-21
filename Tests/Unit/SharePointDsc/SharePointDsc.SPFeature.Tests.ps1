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
                                              -DscResource "SPFeature"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts   
        Mock -CommandName Enable-SPFeature -MockWith {}
        Mock -CommandName Disable-SPFeature -MockWith {}

        # Test contexts
        Context -Name "A feature that is not installed in the farm should be turned on" -Fixture {
            $testParams = @{
                Name         = "DemoFeature"
                FeatureScope = "Farm"
                Url          = "http://site.sharepoint.com"
                Ensure       = "Present"
            }

            Mock -CommandName Get-SPFeature -MockWith { return $null } 

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "A farm scoped feature is not enabled and should be" -Fixture {
            $testParams = @{
                Name         = "DemoFeature"
                FeatureScope = "Farm"
                Url          = "http://site.sharepoint.com"
                Ensure       = "Present"
            }
            
            Mock -CommandName Get-SPFeature -MockWith { 
                return $null 
            } 

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should enable the feature in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Enable-SPFeature
            }
        }

        Context -Name "A site collection scoped feature is not enabled and should be" -Fixture {
            $testParams = @{
                Name         = "DemoFeature"
                FeatureScope = "Site"
                Url          = "http://site.sharepoint.com"
                Ensure       = "Present"
            }
            
            Mock -CommandName Get-SPFeature -MockWith { 
                return $null 
            } 

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should enable the feature in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Enable-SPFeature
            }
        }

        Context -Name "A farm scoped feature is enabled and should not be" -Fixture {
            $testParams = @{
                Name         = "DemoFeature"
                FeatureScope = "Farm"
                Url          = "http://site.sharepoint.com"
                Ensure       = "Absent"
            }
            
            Mock -CommandName Get-SPFeature -MockWith { 
                return @{} 
            } 

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should enable the feature in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Disable-SPFeature
            }
        }

        Context -Name "A site collection scoped feature is enabled and should not be" -Fixture {
            $testParams = @{
                Name         = "DemoFeature"
                FeatureScope = "Site"
                Url          = "http://site.sharepoint.com"
                Ensure       = "Absent"
            }
            
            Mock -CommandName Get-SPFeature -MockWith { 
                return @{}
            } 

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should enable the feature in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Disable-SPFeature
            }
        }

        Context -Name "A farm scoped feature is enabled and should be" -Fixture {
            $testParams = @{
                Name         = "DemoFeature"
                FeatureScope = "Farm"
                Url          = "http://site.sharepoint.com"
                Ensure       = "Present"
            }
            
            Mock -CommandName Get-SPFeature -MockWith { return @{} }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "A site collection scoped feature is enabled and should be" -Fixture {
            $testParams = @{
                Name         = "DemoFeature"
                FeatureScope = "Site"
                Url          = "http://site.sharepoint.com"
                Ensure       = "Present"
            }
            
            Mock -CommandName Get-SPFeature -MockWith { return @{} }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "A site collection scoped features is enabled but has the wrong version" -Fixture {
            $testParams = @{
                Name         = "DemoFeature"
                FeatureScope = "Site"
                Url          = "http://site.sharepoint.com"
                Version      = "1.1.0.0"
                Ensure       = "Present"
            }
                        
            Mock -CommandName Get-SPFeature -MockWith { return @{ Version = "1.0.0.0" } }

            It "Should return the version from the get method" {
                (Get-TargetResource @testParams).Version | Should Be "1.0.0.0"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "reactivates the feature in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Disable-SPFeature
                Assert-MockCalled Enable-SPFeature
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
