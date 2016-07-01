[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPWebAppProxyGroup"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPWebAppProxyGroup - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
               
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")

        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
               
              
        
        
        Context "WebApplication does not exist" {
            $testParams = @{
                WebAppUrl              = "https://web.contoso.com"
                ServiceAppProxyGroup      = "Web1ProxyGroup"
            }

            Mock get-spwebapplication {}

            It "return null property from the get method" {
                (Get-TargetResource @testParams).WebAppUrl | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

        }

        Context "WebApplication Proxy Group connection matches desired config" {
            $testParams = @{
                WebAppUrl              = "https://web.contoso.com"
                ServiceAppProxyGroup      = "Web1ProxyGroup"
            }

            Mock get-spwebapplication { return @{ ServiceApplicationProxyGroup = @{ name = "Web1ProxyGroup"}} }

            It "return values from the get method" {
                (Get-TargetResource @testParams).ServiceAppProxyGroup | Should Be "Web1ProxyGroup"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "WebApplication Proxy Group connection does not match desired config" {
            $testParams = @{
                WebAppUrl              = "https://web.contoso.com"
                ServiceAppProxyGroup      = "Default"
            }

            Mock get-spwebapplication { return @{ ServiceApplicationProxyGroup = @{ name = "Web1ProxyGroup"}} }
            Mock set-spwebapplication { }
            
            It "return values from the get method" {
                (Get-TargetResource @testParams).ServiceAppProxyGroup | Should Be "Web1ProxyGroup"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false 
            }
            
            It "updates the webapplication from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPWebApplication
            }
        }
       
       
       


    }
}
