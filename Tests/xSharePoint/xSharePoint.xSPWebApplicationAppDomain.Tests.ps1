[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebApplicationAppDomain"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWebApplicationAppDomain" {
    InModuleScope $ModuleName {
        $testParams = @{
            AppDomain = "contosointranetapps.com"
            Prefix = "app"
            WebApplication ="http://portal.contoso.com"
            Zone = "Default"
            Port=80;
            SSL=$false
        }
        $testParamsBasic = @{
            AppDomain = "contosointranetapps.com"
            Prefix = "app"
        }

        $returnMatch =@{
                AppDomain = "contosointranetapps.com"
                WebApplication = "http://portal.contoso.com"
                UrlZone = "Default"
                Port = "80"
                IsSchemeSSL=$false
                Prefix= "app"
        } 
        $returnNotMatch =@{
                AppDomain = "litwareintranetapps.com"
                WebApplication = "http://portal.contoso.com"
                UrlZone = "Default"
                Port = "80"
                IsSchemeSSL=$false
                Prefix= "app"
        } 

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock New-SPManagedPath { }

        Context "Subscription Service isn't available" {
            Mock Get-SPAppSiteSubscriptionName {  return $null }
            
            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception when executed" {
                Mock  Set-SPAppSiteSubscriptionName {throw 'Exception'}
                {Set-TargetResource @testParams}| Should Throw
               
            }
            It "subscription is available, but app isn't throws exception when executed" {
                Mock New-SPWebApplicationAppDomain  {throw 'Exception'}
                Mock Set-SPAppSiteSubscriptionName {}
                {Set-TargetResource @testParams}| Should Throw
                Assert-MockCalled Set-SPAppSiteSubscriptionName
            }

        }
        Context "App Management Is Available. adds new web app app domain Settings" {
            Mock Get-SPWebApplicationAppDomain { return $null}
            Mock New-SPWebApplicationAppDomain  {}
            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "saves settings when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPWebApplicationAppDomain 
            }
        }

        Context "App Management Is Available. updates web app app domain Settings" {
            Mock Get-SPWebApplicationAppDomain { return $returnNotMatch
            
            }
            Mock Remove-SPWebApplicationAppDomain{}
            Mock New-SPWebApplicationAppDomain  {}
            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "saves settings when executed" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPWebApplicationAppDomain 
                Assert-MockCalled New-SPWebApplicationAppDomain 
            }
        }
        Context "Basic: App Management Is Available. updates app domain Settings" {
            Mock Get-SPAppDomain { return $null            }
            Mock Set-SPAppDomain{}
            It "returns values from the get method" {
                Get-TargetResource @testParamsBasic | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPAppDomain
            }

            It "returns false from the test method" {
                Test-TargetResource @testParamsBasic | Should Be $false
            }

            It "saves settings when executed" {
                Set-TargetResource @testParamsBasic
                Assert-MockCalled Set-SPAppDomain
            }
        }

        
    }    
}


