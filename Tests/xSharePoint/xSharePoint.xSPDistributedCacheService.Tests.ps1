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
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint")
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPDistributedCacheService" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "AppFabricCache"
            Ensure = "Present"
            CacheSizeInMB = 1024
            ServiceAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            CreateFirewallRules = $true
        }
        
        Context "Validate get method" {
            It "Returns local cache settings correctly when it exists" {
                Mock Invoke-xSharePointDCCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Use-CacheCluster" }
                Mock Invoke-xSharePointDCCmdlet { return @{
                    PortNo = 22233
                } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-CacheHost" }
                Mock Invoke-xSharePointDCCmdlet { return @{
                    HostName = $env:COMPUTERNAME
                    Port = 22233
                    Size = $testParams.CacheSizeInMB
                } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-AFCacheHostConfiguration" }

                $result = Get-TargetResource @testParams

                $result.HostName | Should Be ([System.Net.Dns]::GetHostByName($env:computerName)).HostName
                $result.Port | Should Be 22233
                $result.CacheSizeInMB | Should Be $testParams.CacheSizeInMB
                
                Assert-VerifiableMocks
            }

            It "Returns local cache settings correctly when it does not exist" {
                Mock Invoke-xSharePointDCCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Use-CacheCluster" }
                Mock Invoke-xSharePointDCCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-CacheHost" }
                $result = Get-TargetResource @testParams

                $result | Should BeNullOrEmpty 
                
                Assert-VerifiableMocks
            }
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

            $testParams.Ensure = "Absent"

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

        Context "Validate set method" {

            $testParams.Ensure = "Present"

            It "Provisions distributed cache locally when is should be present, installing firewall when asked for" {
                Mock Enable-xSharePointDCIcmpFireWallRule { return $null } -Verifiable
                Mock Enable-xSharePointDCFireWallRule { return $null } -Verifiable

                Mock Add-xSharePointDistributedCacheServer { return $null } -Verifiable -ParameterFilter { $CacheSizeInMB -eq $testParams.CacheSizeInMB }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            $testParams.CreateFirewallRules = $false

            It "Provisions distributed cache locally when is should be present, not installing firewall" {
                Mock Add-xSharePointDistributedCacheServer { return $null } -Verifiable -ParameterFilter { $CacheSizeInMB -eq $testParams.CacheSizeInMB }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            $testParams.Ensure = "Absent"

            It "Removes distributed cache locally when is should not be present" {
                Mock Remove-xSharePointDistributedCacheServer { return $null } -Verifiable -ParameterFilter { $CacheSizeInMB -eq $testParams.CacheSizeInMB }
                Mock Disable-xSharePointDCFireWallRule { return $null } -Verifiable

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}