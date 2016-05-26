[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPAppDomain"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "SPAppDomain" {
    InModuleScope $ModuleName {
        $testParams = @{
            AppDomain = "apps.contoso.com"
            Prefix = "apps"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
      
        Mock Set-SPAppDomain {}
        Mock Set-SPAppSiteSubscriptionName  {}

        Context "No app URLs have been configured locally" {
            Mock Get-SPAppDomain {  }
            Mock Get-SPAppSiteSubscriptionName  {  }   

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "saves settings when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPAppDomain
                Assert-MockCalled Set-SPAppSiteSubscriptionName  
            }
        }

        Context "Incorrect app URLs have been configured locally" {
            Mock Get-SPAppDomain { return "wrong.domain" }
            Mock Get-SPAppSiteSubscriptionName  { return "wrongprefix" }   

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "saves settings when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPAppDomain
                Assert-MockCalled Set-SPAppSiteSubscriptionName  
            }
        }

        Context "Correct app URLs have been configured locally" {
            Mock Get-SPAppDomain { return $testParams.AppDomain }
            Mock Get-SPAppSiteSubscriptionName  { $testParams.Prefix }   

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}


