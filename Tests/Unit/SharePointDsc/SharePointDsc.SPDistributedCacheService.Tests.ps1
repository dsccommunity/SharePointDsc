[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPDistributedCacheService"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPDistributedCacheService - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "AppFabricCache"
            Ensure = "Present"
            CacheSizeInMB = 1024
            ServiceAccount = "DOMAIN\user"
            CreateFirewallRules = $true
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        $RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
        Import-Module "$RepoRoot\Tests\Unit\Stubs\DistributedCache\DistributedCache.psm1" -WarningAction SilentlyContinue
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
        Mock Add-SPDSCUserToLocalAdmin { } 
        Mock Test-SPDSCUserIsLocalAdmin { return $false }
        Mock Remove-SPDSCUserToLocalAdmin { }
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
        Mock Stop-SPServiceInstance { $Global:SPDSCDCacheOnline = $false }
        Mock Start-SPServiceInstance { $Global:SPDSCDCacheOnline = $true }

        Mock Get-SPServiceInstance {
            $spSvcInstance = [pscustomobject]@{
                Server = @{ Name = $env:COMPUTERNAME }
                Service = "SPDistributedCacheService Name=AppFabricCachingService"
            }
            $spSvcInstance = $spSvcInstance | Add-Member ScriptMethod Delete {} -PassThru
            $spSvcInstance = $spSvcInstance | Add-Member ScriptMethod GetType { 
                return @{ Name = "SPDistributedCacheServiceInstance" } 
            } -PassThru -Force

            if ($Global:SPDSCDCacheOnline -eq $false) 
            {
                $Global:SPDSCUPACheck = $true
                $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Disabled" -PassThru
            } 
            else
            {
                $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Online" -PassThru
            }
            return $spSvcInstance
        }

        Context "Distributed cache is not configured" {
            Mock Use-CacheCluster { throw [Exception] "ERRPS001 Error in reading provider and connection string values." }
            $Global:SPDSCDCacheOnline = $false
            
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
            $Global:SPDSCDCacheOnline = $true

            Mock Get-AFCacheHostConfiguration { return @{
                Size = $testParams.CacheSizeInMB
            }}
            Mock Get-CacheHost { return @{ PortNo = 22233 } }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Distributed cache is configured but the required firewall rules are not deployed" {
            $Global:SPDSCDCacheOnline = $true
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
            $Global:SPDSCDCacheOnline = $true
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