[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPManagedPath"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPManagedPath" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://sites.sharepoint.com"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            RelativeUrl = "teams"
            Explicit = $false
            HostHeader = $false
        }

        Context "Validate test method" {
            It "Fails when path is not found" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the path is found and is the correct type" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.RelativeUrl
                        PathType = "WildcardInclusion"
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the path is found and is not the correct type" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.RelativeUrl
                        PathType = "ExplicitInclusion"
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }    
}