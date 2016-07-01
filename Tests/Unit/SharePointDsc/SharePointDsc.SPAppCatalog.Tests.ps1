[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPAppCatalog"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPAppCatalog - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        $mockSiteId = [Guid]::NewGuid()
        
        Context "The specified site exists, but cannot be set as an app catalog as it is of the wrong template" {
            Mock Update-SPAppCatalogConfiguration { throw 'Exception' }
            Mock Get-SPSite {
                return @{
                    WebApplication = @{
                        Features = @( @{} ) | Add-Member ScriptMethod Item { return $null } -PassThru -Force
                    }
                    ID = $mockSiteId
                }
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception when executed" {
                { Set-TargetResource @testParams } | Should throw
            }
        }

        Context "The specified site exists but is not set as the app catalog for its web application" {
            Mock Update-SPAppCatalogConfiguration { }
            Mock Get-SPSite {
                return @{
                    WebApplication = @{
                        Features = @( @{} ) | Add-Member ScriptMethod Item { return $null } -PassThru -Force
                    }
                    ID = $mockSiteId
                }
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Updates the settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Update-SPAppCatalogConfiguration
            }

        }
        
        Context "The specified site exists and is the current app catalog already" {
            Mock Get-SPSite {
                return @{
                    WebApplication = @{
                        Features = @( @{} ) | Add-Member ScriptMethod Item { return @{ 
                            ID = [guid]::NewGuid()
                            Properties = @{
                                            "__AppCatSiteId" = @{Value = $mockSiteId} 
                                        }
                        } } -PassThru -Force
                    }
                    ID = $mockSiteId
                    Url = $testParams.SiteUrl
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


