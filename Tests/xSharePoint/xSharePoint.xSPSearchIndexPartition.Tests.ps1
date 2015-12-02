[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPSearchIndexPartition"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSearchIndexPartition" {
    InModuleScope $ModuleName {
        $testParams = @{
            Index = "0"
            Servers = @($env:COMPUTERNAME)
            RootDirectory = "C:\SearchIndex\0"
            ServiceAppName = "Search Service Application"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint\Modules\xSharePoint.SearchTopology\xSharePoint.SearchTopology.psm1")
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        Mock New-PSSession {
            return $null
        }
        Mock New-Item { return @{} }
        Mock Start-Sleep {}
        Mock Get-SPEnterpriseSearchServiceApplication {
            return @{
                ActiveTopology = @{}
            }
        } 
        Mock New-SPEnterpriseSearchTopology { return @{} }

        $Global:xSharePointSearchRoleInstanceCallCount = 0
        Mock Get-SPEnterpriseSearchServiceInstance  {
            if ($Global:xSharePointSearchRoleInstanceCallCount -eq 2) {
                $Global:xSharePointSearchRoleInstanceCallCount = 0
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Online"
                }
            } else {
                $Global:xSharePointSearchRoleInstanceCallCount++
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Offline"
                }
            }
        }
        Mock Start-SPEnterpriseSearchServiceInstance { return $null }
        Mock New-SPEnterpriseSearchIndexComponent { return $null } -ModuleName "xSharePoint.SearchTopology"
        Mock Remove-SPEnterpriseSearchComponent { return $null } -ModuleName "xSharePoint.SearchTopology"
        Mock Set-SPEnterpriseSearchTopology { return $null } -ModuleName "xSharePoint.SearchTopology"

        Add-Type -TypeDefinition "public class IndexComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Int32 IndexPartitionOrdinal {get; set;}}"
        $indexComponent = New-Object IndexComponent
        $indexComponent.ServerName = $env:COMPUTERNAME
        $indexComponent.IndexPartitionOrdinal = 0
        
        Context "Search index doesn't exist and it should" {
            Mock Get-SPEnterpriseSearchComponent { return @() } -ModuleName "xSharePoint.SearchTopology"
            $Global:xSharePointSearchRoleInstanceCallCount = 0

            It "returns an empty server list from the get method" {
                $result = Get-TargetResource @testParams
                $result.Servers | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates the search index in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchIndexComponent -ModuleName "xSharePoint.SearchTopology"
            }
        }
        
        Context "Search index does exist and it should" {
            Mock Get-SPEnterpriseSearchComponent { return @($indexComponent) }
            Mock Get-SPEnterpriseSearchComponent { return @($indexComponent) } -ModuleName "xSharePoint.SearchTopology"

            It "returns present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Servers | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        $testParams.Servers = @("SharePoint2")

        Context "Search index exists and it shouldn't" {
            Mock Get-SPEnterpriseSearchComponent { return @($indexComponent) }
            Mock Get-SPEnterpriseSearchComponent { 
                Add-Type -TypeDefinition "public class IndexComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Int32 IndexPartitionOrdinal {get; set;}}"
                $indexComponent = New-Object IndexComponent
                $indexComponent.ServerName = $env:COMPUTERNAME
                $indexComponent.IndexPartitionOrdinal = 0
                return @($indexComponent) 
            } -ModuleName "xSharePoint.SearchTopology"

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "removes the search index in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchComponent -ModuleName "xSharePoint.SearchTopology"
            }
        }
    }
}