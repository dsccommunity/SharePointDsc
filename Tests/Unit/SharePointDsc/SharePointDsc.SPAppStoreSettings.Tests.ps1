[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPAppStoreSettings"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPAppStoreSettings - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl          = "https://sharepoint.contoso.com"
            AllowAppPurchases  = $true
            AllowAppsForOffice = $true
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        $mockSiteId = [Guid]::NewGuid()
        
        Context "The specified web application does not exist" {
            Mock Get-SPWebApplication {
                return $null
            }

            It "returns null from the get method" {
                (Get-TargetResource @testParams).WebAppUrl | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception when executed" {
                { Set-TargetResource @testParams } | Should Throw "Specified web application does not exist."
            }
        }

        Context "The specified settings do not match" {
            Mock Get-SPAppAcquisitionConfiguration {
                return @{
                    Enabled = $false
                }
            }
            Mock Get-SPOfficeStoreAppsDefaultActivation {
                return @{
                    Enable = $false
                }
            }

            Mock Set-SPAppAcquisitionConfiguration {}
            Mock Set-SPOfficeStoreAppsDefaultActivation {}

            Mock Get-SPWebApplication {
                return @{
                    Url = "https://sharepoint.contoso.com"
                }
            }

            It "returns values from the get method" {
                (Get-TargetResource @testParams).AllowAppPurchases | Should Be $false
                (Get-TargetResource @testParams).AllowAppsForOffice | Should Be $false
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Updates the settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPAppAcquisitionConfiguration
                Assert-MockCalled Set-SPOfficeStoreAppsDefaultActivation
            }
        }
        
        Context "The specified settings match" {
            Mock Get-SPAppAcquisitionConfiguration {
                return @{
                    Enabled = $true
                }
            }
            Mock Get-SPOfficeStoreAppsDefaultActivation {
                return @{
                    Enable = $true
                }
            }

            Mock Get-SPWebApplication {
                return @{
                    Url = "https://sharepoint.contoso.com"
                }
            }

            It "returns values from the get method" {
                (Get-TargetResource @testParams).AllowAppPurchases | Should Be $true
                (Get-TargetResource @testParams).AllowAppsForOffice | Should Be $true
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The specified setting does not match" {
            $testParams = @{
                WebAppUrl          = "https://sharepoint.contoso.com"
                AllowAppPurchases  = $true
            }

            Mock Get-SPAppAcquisitionConfiguration {
                return @{
                    Enabled = $false
                }
            }
            Mock Get-SPOfficeStoreAppsDefaultActivation {
                return @{
                    Enable = $true
                }
            }

            Mock Set-SPAppAcquisitionConfiguration {}

            Mock Get-SPWebApplication {
                return @{
                    Url = "https://sharepoint.contoso.com"
                }
            }

            It "returns values from the get method" {
                (Get-TargetResource @testParams).AllowAppPurchases | Should Be $false
                (Get-TargetResource @testParams).AllowAppsForOffice | Should Be $true
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Updates the settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPAppAcquisitionConfiguration
            }
        }
    }    
}


