[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPInstall"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPInstall" {
    InModuleScope $ModuleName {
        $testParams = @{
            BinaryDir = "C:\SPInstall"
            ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
        }

        Context "Validate test method" {
            It "Passes when SharePoint is installed" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        SharePointInstalled = $true
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when SharePoint is not installed" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        SharePointInstalled = $false
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }    
}