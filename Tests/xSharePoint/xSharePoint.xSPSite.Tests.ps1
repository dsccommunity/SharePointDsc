[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPSite"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSite" {
    InModuleScope $ModuleName {
        $testParams = @{
            Url = "http://site.sharepoint.com"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            OwnerAlias = "DEMO\User"
        }

        Context "Validate test method" {
            It "Fails when site collection isn't found" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the site collection is found" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Url = $testParams.Url
                        OwnerAlias = $testParams.OwnerAlias
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}