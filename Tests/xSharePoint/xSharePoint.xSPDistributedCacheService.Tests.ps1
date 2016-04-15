[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPDistributedCacheService"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPDistributedCacheService" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "AppFabricCache"
            Ensure = "Present"
            CacheSizeInMB = 1024
            ServiceAccount = "DOMAIN\user"
            CreateFirewallRules = $true
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        $RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
        Import-Module "$RepoRoot\Tests\Stubs\DistributedCache\DistributedCache.psm1" -WarningAction SilentlyContinue
        Mock Use-CacheCluster { }
        Mock Get-WmiObject { return @{ StartName = $testParams.ServiceAccount } }
        Mock Get-NetFirewallRule { return @{} }
        Mock Get-NetFirewallRule { return @{} } 
        Mock Enable-NetFirewallRule { }  
        Mock New-NetFirewallRule { }  
        Mock Disable-NetFirewallRule { } 
        Mock Add-SPDistributedCacheServiceInstance { } 
        Mock Update-SPDistributedCacheSize { } 
        Mock Get-SPManagedAccount { return @{} } 
        Mock Add-xSharePointUserToLocalAdmin { } 
        Mock Test-xSharePointUserIsLocalAdmin { return $false }
        Mock Remove-xSharePointUserToLocalAdmin { }
        Mock Restart-Service { }
        Mock Get-SPFarm { return @{ 
            Services = @(@{ 
                Name = "AppFabricCachingService"
                ProcessIdentity = New-Object Object |            
                                    Add-Member NoteProperty ManagedAccount $null -PassThru |
                                    Add-Member NoteProperty CurrentIdentityType $null -PassThru |             
                                    Add-Member ScriptMethod Update {} -PassThru | 
                                    Add-Member ScriptMethod Deploy {} -PassThru  
            }) 
        } }
        Mock Stop-SPServiceInstance { $Global:xSharePointDCacheOnline = $false }
        Mock Start-SPServiceInstance { $Global:xSharePointDCacheOnline = $true }

        Mock Get-SPServiceInstance { 
                if ($Global:xSharePointDCacheOnline -eq $false) {
                    return @(New-Object Object |            
                                Add-Member NoteProperty TypeName "Distributed Cache" -PassThru |
                                Add-Member NoteProperty Status "Disabled" -PassThru |
                                Add-Member NoteProperty Service "SPDistributedCacheService Name=AppFabricCachingService" -PassThru |
                                Add-Member NoteProperty Server @{ Name = $env:COMPUTERNAME } -PassThru |             
                                Add-Member ScriptMethod Delete {} -PassThru)
                } else {
                    return @(New-Object Object |            
                                Add-Member NoteProperty TypeName "Distributed Cache" -PassThru |
                                Add-Member NoteProperty Status "Online" -PassThru |
                                Add-Member NoteProperty Service "SPDistributedCacheService Name=AppFabricCachingService" -PassThru |
                                Add-Member NoteProperty Server @{ Name = $env:COMPUTERNAME } -PassThru |             
                                Add-Member ScriptMethod Delete {} -PassThru)
                }
                
            }

        Context "Distributed cache is not configured" {
            Mock Use-CacheCluster { throw [Exception] "ERRPS001 Error in reading provider and connection string values." }
            $Global:xSharePointDCacheOnline = $false
            
            It "returns null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Sets up the cache correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPDistributedCacheServiceInstance 
            }
        }

        Context "Distributed cache is configured correctly and running as required" {
            $Global:xSharePointDCacheOnline = $true

            Mock Get-AFCacheHostConfiguration { return @{
                Size = $testParams.CacheSizeInMB
            }}
            Mock Get-CacheHost { return @{ PortNo = 22233 } }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Distributed cache is configured but the required firewall rules are not deployed" {
            $Global:xSharePointDCacheOnline = $true
            Mock Get-NetFirewallRule { return $null }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "shuts down the distributed cache service" {
                Set-TargetResource @testParams
                Assert-MockCalled Enable-NetFirewallRule 
            }
        }

        Context "Distributed cache is confgured but should not be running on this machine" {
            $Global:xSharePointDCacheOnline = $true
            $testParams.Ensure = "Absent"
            Mock Get-AFCacheHostConfiguration { return @{
                Size = $testParams.CacheSizeInMB
            }}
            Mock Get-CacheHost { return @{ PortNo = 22233 } }
            Mock Get-NetFirewallRule { return @{} } 
            Mock Remove-SPDistributedCacheServiceInstance { }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "shuts down the distributed cache service" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPDistributedCacheServiceInstance
                Assert-MockCalled Disable-NetFirewallRule 
            }
        }
    }    
}