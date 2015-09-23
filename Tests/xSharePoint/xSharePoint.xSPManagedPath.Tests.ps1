[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPManagedPath"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPManagedPath" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://sites.sharepoint.com"
            RelativeUrl = "teams"
            Explicit = $false
            HostHeader = $false
        }

        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        Mock Initialize-xSharePointPSSnapin { }
        Mock New-SPManagedPath { }

        Context "The managed path does not exist and should" {
            Mock Get-SPManagedPath { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a host header path in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPManagedPath
            }

            $testParams.HostHeader = $true
            It "creates a host header path in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPManagedPath
            }
            $testParams.HostHeader = $false
        }

        Context "The path exists but is of the wrong type" {
            Mock Get-SPManagedPath { return @{
                Name = $testParams.RelativeUrl
                Type = "ExplicitInclusion"
            } }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "The path exists and is the correct type" {
            Mock Get-SPManagedPath { return @{
                Name = $testParams.RelativeUrl
                Type = "WildcardInclusion"
            } }

            It "returns results from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}