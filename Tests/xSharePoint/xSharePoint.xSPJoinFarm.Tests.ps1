[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPJoinFarm"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPJoinFarm" {
    InModuleScope $ModuleName {
        $testParams = @{
            FarmConfigDatabaseName = "SP_Config"
            DatabaseServer = "DatabaseServer\Instance"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Passphrase = "passphrase"
            WaitTime = 60
            WaitCount = 60
        }

        Context "Validate test method" {
            It "Fails when local server is not in a farm" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when local server is in a farm" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        FarmName = "SP_Config"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}