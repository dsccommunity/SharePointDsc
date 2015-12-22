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
            WebApp = "https://content.sharepoint.contoso.com"
            AppCatalogUrl = "/sites/AppCatalog"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Context "Update-SPAppCatalogConfiguration fails due to service or invalid template" {
            Mock Update-SPAppCatalogConfiguration { throw 'Exception' }
            Mock Get-SPWebApplication { return @{
                Features = @{[Guid]::Parse("f8bea737-255e-4758-ab82-e34bb46f5111") = @{
                                        Properties = @{
                                        "__AppCatSiteId" = @{Value = "/sites/AppCatalog"} 
                                        }
                                    }
                                }
                            
                    }
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPWebApplication
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception when executed" {
                {Set-TargetResource @testParams}| Should throw
        
            }

        }

        Context "Save Settings at Web Application level" {
            Mock Update-SPAppCatalogConfiguration { }
            Mock Get-SPWebApplication {
              
            }
            It "save settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Update-SPAppCatalogConfiguration
            }

        }
        Context "Settings match" {
            Mock Update-SPAppCatalogConfiguration { throw 'Exception' }
            Mock Get-SPWebApplication { return @{
                Features = @{[Guid]::Parse("f8bea737-255e-4758-ab82-e34bb46f5828") = @{
                                        Properties = @{
                                        "__AppCatSiteId" = @{Value = "/sites/AppCatalog"} 
                                        }
                                    }
                                }
                            
                    }
            }
            Mock Get-SPSite {
            return @{
                ServerRelativeUrl="/sites/AppCatalog"
                }
            }

            It "returns value from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }


        }

    }    
}


