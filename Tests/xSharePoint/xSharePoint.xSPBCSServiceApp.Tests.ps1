[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\MSFT_xSPBCSServiceApp\MSFT_xSPBCSServiceApp.psm1")

Describe "xSPBCSServiceApp" {

    $testParams = @{
        Name = "Test App"
        ApplicationPool = "Test App Pool"
        DatabaseName = "Test_DB"
        DatabaseServer = "TestServer\Instance"
        InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
    }

    Context "Validate test method" {
        It "Fails when no service app exists" {
            Mock Get-TargetResource { return @{} } -ModuleName MSFT_xSPBCSServiceApp
            Test-TargetResource @testParams | Should Be $false
        }
        It "Passes when the service app exists" {
            Mock Get-TargetResource { 
                return @{ 
                    Name = $testParams.Name 
                    ApplicationPool = $testParams.ApplicationPool
                } 
            } -ModuleName MSFT_xSPBCSServiceApp
            Test-TargetResource @testParams | Should Be $false
        }
        It "Fails when the service app exists but has the wrong app pool" {
            Mock Get-TargetResource { 
                return @{ 
                    Name = $testParams.Name 
                    ApplicationPool = "Wrong app pool"
                } 
            } -ModuleName MSFT_xSPBCSServiceApp
            Test-TargetResource @testParams | Should Be $false
        }
    }
}