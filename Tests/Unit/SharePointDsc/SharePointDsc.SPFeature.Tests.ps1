[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPFeature"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPFeature - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name         = "DemoFeature"
            FeatureScope = "Farm"
            Url          = "http://site.sharepoint.com"
            Ensure       = "Present"
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock Enable-SPFeature {}
        Mock Disable-SPFeature {}

        Context "A feature that is not installed in the farm should be turned on" {
            Mock Get-SPFeature { return $null } 

            It "returns null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "A farm scoped feature is not enabled and should be" {
            Mock Get-SPFeature { return $null } 
            $testParams.FeatureScope = "Farm"

            It "returns null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "enables the feature in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Enable-SPFeature
            }
        }

        Context "A site collection scoped feature is not enabled and should be" {
            Mock Get-SPFeature { return $null } 
            $testParams.FeatureScope = "Site"

            It "returns null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "enables the feature in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Enable-SPFeature
            }
        }

        Context "A farm scoped feature is enabled and should not be" {
            Mock Get-SPFeature { return @{} } 

            $testParams.FeatureScope = "Farm"
            $testParams.Ensure = "Absent"

            It "returns null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "enables the feature in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Disable-SPFeature
            }
        }

        Context "A site collection scoped feature is enabled and should not be" {
            Mock Get-SPFeature { return @{} } 

            $testParams.FeatureScope = "Site"

            It "returns null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "enables the feature in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Disable-SPFeature
            }
        }

        Context "A farm scoped feature is enabled and should be" {
            Mock Get-SPFeature { return @{} }

            $testParams.FeatureScope = "Farm"
            $testParams.Ensure = "Present"

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "A site collection scoped feature is enabled and should be" {
            Mock Get-SPFeature { return @{} }

            $testParams.FeatureScope = "Site"

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "A site collection scoped features is enabled but has the wrong version" {
            
            Mock Get-SPFeature { return @{ Version = "1.0.0.0" } }
            Mock Disable-SPFeature { } -Verifiable
            
            $testParams.FeatureScope = "Site"
            $testParams.Version      = "1.1.0.0"

            It "returns the version from the get method" {
                (Get-TargetResource @testParams).Version | Should Be "1.0.0.0"
            }
            
            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "reactivates the feature in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Disable-SPFeature -Times 1
                Assert-MockCalled Enable-SPFeature -Times 1
            }
        }
    }
}
