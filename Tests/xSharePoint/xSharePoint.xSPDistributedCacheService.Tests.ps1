[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPDistributedCacheService"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPDistributedCacheService" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "AppFabricCache"
            Ensure = "Present"
            CacheSizeInMB = 1024
            ServiceAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            createFirewallRules = $true
        }

        Context "Validate test method" {
            It "Fails when no cache is present locally but should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when cache is present and size is correct" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        HostName = $env:COMPUTERNAME
                        Port = 22233
                        CacheSizeInMB = $testParams.CacheSizeInMB
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when cache is present but size is not correct" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        HostName = $env:COMPUTERNAME
                        Port = 22233
                        CacheSizeInMB = 1
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }

            $testParams.ENsure = "Absent"

            It "Fails when cache is present but not should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        HostName = $env:COMPUTERNAME
                        Port = 22233
                        CacheSizeInMB = 1
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when cache is not present and should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}