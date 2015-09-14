[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPCacheAccounts"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint")
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\Modules\xSharePoint.CacheAccounts\xSharePoint.CacheAccounts.psm1")

Describe "xSPCacheAccounts" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://test.sharepoint.com"
            SuperUserAlias = "DEMO\SuperUser"
            SuperReaderAlias = "DEMO\SuperReader"
        }

        Context "Validate get method" {
            It "Calls the service application picker with the appropriate type name" {
                Mock Invoke-xSharePointSPCmdlet { return @{
                    Properties = @{
                        SuperUserAlias = $testParams.SuperUserAlias
                        SuperReaderAlias = $testParams.SuperReaderAlias
                    }
                }} -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPWebApplication" }
                
                $results = Get-TargetResource @testParams
                $results.Count | Should Not BeNullOrEmpty

                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when no cache accounts exist" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the correct accounts are assigned" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        SuperUserAlias = $testParams.SuperUserAlias
                        SuperReaderAlias = $testParams.SuperReaderAlias
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the wrong super reader is defined" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        SuperUserAlias = $testParams.SuperUserAlias
                        SuperReaderAlias = "DEMO\WrongUser"
                    } 
                }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Fails when the wrong super user is defined" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        SuperUserAlias = "DEMO\WrongUser"
                        SuperReaderAlias = $testParams.SuperReaderAlias
                    } 
                }
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Sets accounts when no existing account is set" {
                Mock Invoke-xSharePointSPCmdlet { return @{
                    Properties = @{}
                } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPWebApplication" }
                Mock Set-xSharePointCacheReaderPolicy { return $null } -Verifiable 
                Mock Set-xSharePointCacheOwnerPolicy { return $null } -Verifiable 
                Mock Update-xSharePointObject { return $null } -Verifiable

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            It "Sets accounts when existing accounts are set" {
                Mock Invoke-xSharePointSPCmdlet { return @{
                    Properties = @{
                        SuperUserAlias = $testParams.SuperUserAlias
                        SuperReaderAlias = $testParams.SuperReaderAlias
                    }
                } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPWebApplication" }
                Mock Set-xSharePointCacheReaderPolicy { return $null } -Verifiable
                Mock Set-xSharePointCacheOwnerPolicy { return $null } -Verifiable
                Mock Update-xSharePointObject { return $null } -Verifiable

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}