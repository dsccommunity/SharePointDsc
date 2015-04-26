[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPServiceAppPool"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPServiceAppPool" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Service pool"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            ServiceAccount = "DEMO\svcSPServiceApps"
        }

        Context "Validate test method" {
            It "Fails when service app pool is not found" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the pool exists and has the correct service account" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ProcessAccountName = $testParams.ServiceAccount
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the service app pool is found but uses the wrong service account" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ProcessAccountName = "Wrong account name"
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }    
}