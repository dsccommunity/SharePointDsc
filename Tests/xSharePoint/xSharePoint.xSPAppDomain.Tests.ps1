[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPAppDomain"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPAppDomain" {
    InModuleScope $ModuleName {
        $testParams = @{
            AppDomain = "http://apps.contoso.com"
            Prefix = "apps"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
      
        Mock Set-SPAppDomain 
        Mock Set-SPAppSiteSubscriptionName  
        $sampleResultDifferent =  @{
            AppDomain = "http://apps2.contoso.com"
            Prefix= "apps2"
        }

        $sampleResultEquals =  @{
            AppDomain = "http://apps.contoso.com"
            Prefix= "apps"
        }

        Context "App Management Is Available. Settings are saved" {
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
        Context "App Management Is Available. Settings are a match" {
            Mock Get-SPAppDomain { return "http://apps.contoso.com" }
            Mock Get-SPAppSiteSubscriptionName  {  return "apps" }   
            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "saves settings when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPAppDomain
                Assert-MockCalled Set-SPAppSiteSubscriptionName  
            }
        }
    }    
}


