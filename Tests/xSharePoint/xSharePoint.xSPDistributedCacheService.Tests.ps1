[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPDistributedCacheService"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\Modules\xSharePoint.DistributedCache\xSharePoint.DistributedCache.psm1")

Describe "xSPDistributedCacheService" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "AppFabricCache"
            Ensure = "Present"
            CacheSizeInMB = 1024
            ServiceAccount = "DOMAIN\user"
            CreateFirewallRules = $true
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        $RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
        Import-Module "$RepoRoot\Tests\Stubs\DistributedCache\DistributedCache.psm1" -WarningAction SilentlyContinue

        Mock Initialize-xSharePointPSSnapin { }
        Mock Initialize-xSharePointPSSnapin { } -ModuleName "xSharePoint.DistributedCache"
        Mock Use-CacheCluster { }
        Mock Get-WmiObject { return @{ StartName = $testParams.ServiceAccount } }
        Mock Get-NetFirewallRule { return @{} }
        Mock Get-NetFirewallRule { return @{} } -ModuleName "xSharePoint.DistributedCache"
        Mock Enable-NetFirewallRule { }  -ModuleName "xSharePoint.DistributedCache"
        Mock New-NetFirewallRule { }  -ModuleName "xSharePoint.DistributedCache"
        Mock Disable-NetFirewallRule { } -ModuleName "xSharePoint.DistributedCache"
        Mock Add-SPDistributedCacheServiceInstance { } -ModuleName "xSharePoint.DistributedCache"
        Mock Update-SPDistributedCacheSize { } -ModuleName "xSharePoint.DistributedCache"
        Mock Get-SPManagedAccount { return @{} } -ModuleName "xSharePoint.DistributedCache"
        Mock Get-SPFarm { return @{ 
            Services = @(@{ 
                Name = "AppFabricCachingService"
                ProcessIdentity = @{ ManagedAccount = $null }
            }) 
        } }  -ModuleName "xSharePoint.DistributedCache"
        Mock Update-xSharePointDistributedCacheService { } -ModuleName "xSharePoint.DistributedCache"


        Context "Distributed cache is not configured" {
            Mock Get-CacheHost { return $null }

            It "returns null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Sets up the cache correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPDistributedCacheServiceInstance -ModuleName "xSharePoint.DistributedCache"
            }
        }

        Context "Distributed cache is configured correctly and running as required" {
            Mock Get-AFCacheHostConfiguration { return @{
                Size = $testParams.CacheSizeInMB
            }}
            Mock Get-CacheHost { return @{ PortNo = 22233 } }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Distributed cache is configured but the required firewall rules are not deployed" {
            Mock Get-NetFirewallRule { return $null }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "shuts down the distributed cache service" {
                Set-TargetResource @testParams
                Assert-MockCalled Enable-NetFirewallRule -ModuleName "xSharePoint.DistributedCache"
            }
        }

        Context "Distributed cache is confgured but should not be running on this machine" {
            $testParams.Ensure = "Absent"
            Mock Get-AFCacheHostConfiguration { return @{
                Size = $testParams.CacheSizeInMB
            }}
            Mock Get-CacheHost { return @{ PortNo = 22233 } }
            Mock Remove-xSharePointDistributedCacheServer { }
            Mock Get-NetFirewallRule { return @{} } -ModuleName "xSharePoint.DistributedCache"

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "shuts down the distributed cache service" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-xSharePointDistributedCacheServer
                Assert-MockCalled Disable-NetFirewallRule -ModuleName "xSharePoint.DistributedCache"
            }
        }
    }    
}