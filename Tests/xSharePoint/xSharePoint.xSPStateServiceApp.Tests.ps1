[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPStateServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPStateServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "State Service App"
            DatabaseName = "SP_StateService"
        }

        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        Mock Initialize-xSharePointPSSnapin { }
        Mock New-SPStateServiceDatabase { return @{} }
        Mock New-SPStateServiceApplication { return @{} }
        Mock New-SPStateServiceApplicationProxy { return @{} }

        Context "the service app doesn't exist and should" {
            Mock Get-SPStateServiceApplication { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the get method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a state service app from the set method" {
                Set-TargetResource @testParams 

                Assert-MockCalled New-SPStateServiceApplication
            }
        }

        Context "the service app exists and should" {
            Mock Get-SPStateServiceApplication { return @{ DisplayName = $testParams.Name } }

            It "returns the current info from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}