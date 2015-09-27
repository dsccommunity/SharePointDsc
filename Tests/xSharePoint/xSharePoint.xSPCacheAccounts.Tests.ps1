[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPCacheAccounts"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPCacheAccounts" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://test.sharepoint.com"
            SuperUserAlias = "DEMO\SuperUser"
            SuperReaderAlias = "DEMO\SuperReader"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock Set-xSharePointCacheReaderPolicy {}
        Mock Set-xSharePointCacheOwnerPolicy {}
        Mock Update-xSharePointObject {}

        Context "The web application specified does not exist" {
            Mock Get-SPWebApplication { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws and exception where set is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context "The specified cache accounts have not been configured" {
            Mock Get-SPWebApplication { return @{
                Properties = @{ }
            }}

            It "returns empty strings from the Get method" {
                $results = Get-TargetResource @testParams
                $results.SuperUserAlias | Should BeNullOrEmpty
                $results.SuperReaderAlias | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Updates the accounts when set is called" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-xSharePointCacheReaderPolicy
                Assert-MockCalled Set-xSharePointCacheOwnerPolicy
                Assert-MockCalled Update-xSharePointObject
            }
        }

        Context "The cache accounts have been configured correctly" {
            Mock Get-SPWebApplication { return @{
                Properties = @{
                    portalsuperuseraccount = $testParams.SuperUserAlias
                    portalsuperreaderaccount = $testParams.SuperReaderAlias
                }
            }}

            It "returns the values from the get method" {
                $results = Get-TargetResource @testParams
                $results.SuperUserAlias | Should Not BeNullOrEmpty
                $results.SuperReaderAlias | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Cache accounts have been configured, but the reader account is wrong" {
            Mock Get-SPWebApplication { return @{
                Properties = @{
                    portalsuperuseraccount = $testParams.SuperUserAlias
                    portalsuperreaderaccount = "WRONG\AccountName"
                }
            }}

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "sets the correct accounts to the web app again" {
                Set-TargetResource @testParams
                Assert-MockCalled Update-xSharePointObject
            }
        }

        Context "Cache accounts have been configured, but the super account is wrong" {
            Mock Get-SPWebApplication { return @{
                Properties = @{
                    portalsuperuseraccount = "WRONG\AccountName"
                    portalsuperreaderaccount = $testParams.SuperReaderAlias
                }
            }}

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "sets the correct accounts to the web app again" {
                Set-TargetResource @testParams
                Assert-MockCalled Update-xSharePointObject
            }
        }
    }    
}