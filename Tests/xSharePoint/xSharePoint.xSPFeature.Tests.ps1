[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPFeature"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPFeature" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "DemoFeature"
            FeatureScope = "Farm"
            Url = "http://site.sharepoint.com"
            Ensure = "Present"
        }

        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        Mock Initialize-xSharePointPSSnapin { }
        Mock Enable-SPFeature {}
        Mock Disable-SPFeature {}

        Context "A feature that is not installed in the farm should be turned on" {
            Mock Get-SPFeature { return $null } -ParameterFilter { $Farm -ne $true }

            It "returns null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "A farm scoped feature is not enabled and should be" {
            Mock Get-SPFeature { return $null } -ParameterFilter { $Farm -eq $true }
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
            Mock Get-SPFeature { return $null } -ParameterFilter { $Site -eq $true }
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
            Mock Get-SPFeature { return @{} } -ParameterFilter { $Farm -eq $true }
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
            Mock Get-SPFeature { return @{} } -ParameterFilter { $Site -eq $true }
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
            Mock Get-SPFeature { return @{} } -ParameterFilter { $Farm -eq $true }
            $testParams.FeatureScope = "Farm"
            $testParams.Ensure = "Present"

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "A site collection scoped feature is enabled and should be" {
            Mock Get-SPFeature { return @{} }
            Mock Get-SPFeature { return @{} } -ParameterFilter { $Site -eq $testParams.Url }
            $testParams.FeatureScope = "Site"

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}