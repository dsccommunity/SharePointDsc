[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPBCSServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPBCSServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test App"
            ApplicationPool = "Test App Pool"
            DatabaseName = "Test_DB"
            DatabaseServer = "TestServer\Instance"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
        }

        Context "Validate test method" {
            It "Fails when no service app exists" {
                Mock Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the service app exists" {
                Mock Get-TargetResource { 
                    return @{ 
                        Name = $testParams.Name 
                        ApplicationPool = $testParams.ApplicationPool
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the service app exists but has the wrong app pool" {
                Mock Get-TargetResource { 
                    return @{ 
                        Name = $testParams.Name 
                        ApplicationPool = "Wrong app pool"
                    } 
                }
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }
}