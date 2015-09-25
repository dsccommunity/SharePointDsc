[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPServiceAppPool"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPServiceAppPool" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Service pool"
            ServiceAccount = "DEMO\svcSPServiceApps"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        Mock Initialize-xSharePointPSSnapin { } -ModuleName "xSharePoint.Util"
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock New-SPServiceApplicationPool { }
        Mock Set-SPServiceApplicationPool { }

        Context "A service account pool does not exist but should" {
            Mock Get-SPServiceApplicationPool { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the set method to create a new service account pool" {
                Set-TargetResource @testParams
                
                Assert-MockCalled New-SPServiceApplicationPool 
            }
        }

        Context "A service account pool exists but has the wrong service account" {
            Mock Get-SPServiceApplicationPool { return @{
                Name = $testParams.Name
                ProcessAccountName = "WRONG\account"
            }}

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false                
            }

            It "calls the set method to update the service account pool" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPServiceApplicationPool 
            }
        }

        Context "A service account pool exists and uses the correct account" {
            Mock Get-SPServiceApplicationPool { return @{
                Name = $testParams.Name
                ProcessAccountName = $testParams.ServiceAccount
            }}

            It "retrieves the status from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}