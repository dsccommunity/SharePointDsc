[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPAppCatalog"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPAppCatalog" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://sites.sharepoint.com"
            RelativeUrl = "teams"
            Explicit = $false
            HostHeader = $false
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock New-SPManagedPath { }

        Context "Service is not available" {
            Mock Get-SPManagedPath { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedPath
            }

        }

        Context "Catalog site does not exist" {
            Mock Get-SPManagedPath { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedPath
            }

        }

        Context "Catalog site wasn't created using catalog template" {
            Mock Get-SPManagedPath { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedPath
            }

        }

        Context "Save Settings at Web Application level" {
            Mock Get-SPManagedPath { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedPath
            }

        }


        Context "Save Settings at HNSC level" {
            Mock Get-SPManagedPath { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedPath
            }

        }


        Context "App Management Is Available. Settings are saved" {
            Mock Get-SPManagedPath { return @{
                Name = $testParams.RelativeUrl
                Type = "ExplicitInclusion"
            } }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "saves settings when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedPath
            }
        }
    }    
}


