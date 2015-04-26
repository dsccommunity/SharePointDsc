[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPSearchServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSearchServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Search Service Application"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            ApplicationPool = "SharePoint Search Services"
        }

        Context "Validate test method" {
            It "Fails when service app is not found" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the path is found and is the correct type" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ApplicationPool = $testParams.ApplicationPool
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the service app is found but uses the wrong app pool" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ApplicationPool = "Wrong App Pool"
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }    
}