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
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPCacheAccounts" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://test.sharepoint.com"
            SuperUserAlias = "DEMO\SuperUser"
            SuperReaderAlias = "DEMO\SuperReader"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
        }

        Context "Validate test method" {
            It "Fails when no cache accounts exist" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the correct accounts are assigned" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        portalsuperuseraccount = $testParams.SuperUserAlias
                        portalsuperreaderaccount = $testParams.SuperReaderAlias
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the wrong super reader is defined" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        portalsuperuseraccount = $testParams.SuperUserAlias
                        portalsuperreaderaccount = "DEMO\WrongUser"
                    } 
                }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Fails when the wrong super user is defined" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        portalsuperuseraccount = "DEMO\WrongUser"
                        portalsuperreaderaccount = $testParams.SuperReaderAlias
                    } 
                }
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }    
}