[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPSearchTopology"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPSearchTopology - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            ServiceAppName          = "Search Service Application"
            Admin                   = @($env:COMPUTERNAME)
            Crawler                 = @($env:COMPUTERNAME)
            ContentProcessing       = @($env:COMPUTERNAME)
            AnalyticsProcessing     = @($env:COMPUTERNAME)
            QueryProcessing         = @($env:COMPUTERNAME)
            IndexPartition          = @($env:COMPUTERNAME)
            FirstPartitionDirectory = "I:\SearchIndexes\0"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        Mock -CommandName Start-Sleep {}
        Mock -CommandName New-Item { return @{} }
        Mock -CommandName Get-SPEnterpriseSearchServiceInstance  {
            return @{
                Server = @{
                    Address = $env:COMPUTERNAME
                }
                Status = "Online"
            }
        }
        Mock -CommandName Get-SPEnterpriseSearchServiceApplication {
            return @{
                ActiveTopology = @{}
            }
        }

        Add-Type -TypeDefinition "namespace Microsoft.Office.Server.Search.Administration.Topology { public class AdminComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Guid ServerId {get; set;}}}"
        Add-Type -TypeDefinition "namespace Microsoft.Office.Server.Search.Administration.Topology { public class CrawlComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Guid ServerId {get; set;}}}"
        Add-Type -TypeDefinition "namespace Microsoft.Office.Server.Search.Administration.Topology { public class ContentProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Guid ServerId {get; set;}}}"
        Add-Type -TypeDefinition "namespace Microsoft.Office.Server.Search.Administration.Topology { public class AnalyticsProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Guid ServerId {get; set;}}}"
        Add-Type -TypeDefinition "namespace Microsoft.Office.Server.Search.Administration.Topology { public class QueryProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Guid ServerId {get; set;}}}"
        Add-Type -TypeDefinition "namespace Microsoft.Office.Server.Search.Administration.Topology { public class IndexComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Int32 IndexPartitionOrdinal {get; set;} public System.Guid ServerId {get; set;}}}"

        $serverId = New-Guid

        $adminComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.AdminComponent
        $adminComponent.ServerName = $env:COMPUTERNAME
        $adminComponent.ServerId = $serverId
        $adminComponent.ComponentId = [Guid]::NewGuid()

        $crawlComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.CrawlComponent
        $crawlComponent.ServerName = $env:COMPUTERNAME
        $crawlComponent.ServerId = $serverId
        $crawlComponent.ComponentId = [Guid]::NewGuid()

        $contentProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.ContentProcessingComponent
        $contentProcessingComponent.ServerName = $env:COMPUTERNAME
        $contentProcessingComponent.ServerId = $serverId
        $contentProcessingComponent.ComponentId = [Guid]::NewGuid()

        $analyticsProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.AnalyticsProcessingComponent
        $analyticsProcessingComponent.ServerName = $env:COMPUTERNAME
        $analyticsProcessingComponent.ServerId = $serverId
        $analyticsProcessingComponent.ComponentId = [Guid]::NewGuid()

        $queryProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.QueryProcessingComponent
        $queryProcessingComponent.ServerName = $env:COMPUTERNAME
        $queryProcessingComponent.ServerId = $serverId
        $queryProcessingComponent.ComponentId = [Guid]::NewGuid()

        $indexComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.IndexComponent
        $indexComponent.ServerName = $env:COMPUTERNAME
        $indexComponent.ServerId = $serverId
        $indexComponent.IndexPartitionOrdinal = 0

        Mock -CommandName Start-SPEnterpriseSearchServiceInstance { return $null }
        Mock -CommandName New-SPEnterpriseSearchTopology { return @{} }
        Mock -CommandName New-SPEnterpriseSearchAdminComponent { return @{} } 
        Mock -CommandName New-SPEnterpriseSearchCrawlComponent { return @{} }
        Mock -CommandName New-SPEnterpriseSearchContentProcessingComponent { return @{} }
        Mock -CommandName New-SPEnterpriseSearchAnalyticsProcessingComponent { return @{} }
        Mock -CommandName New-SPEnterpriseSearchQueryProcessingComponent { return @{} }
        Mock -CommandName New-SPEnterpriseSearchIndexComponent { return @{} }
        Mock -CommandName Set-SPEnterpriseSearchTopology { return @{} }
        Mock -CommandName Remove-SPEnterpriseSearchComponent { return $null }

        Mock -CommandName Get-SPServer {
            return @(
                @{
                    Name = $env:COMPUTERNAME
                    Id = $serverId
                }
            )
        }

        Context -Name "No search topology has been applied" {
            Mock -CommandName Get-SPEnterpriseSearchComponent {
                return @{}
            }

            It "Should return empty values from the get method" {
                $result = Get-TargetResource @testParams
                $result.Admin | Should BeNullOrEmpty
                $result.Crawler | Should BeNullOrEmpty
                $result.ContentProcessing | Should BeNullOrEmpty
                $result.AnalyticsProcessing | Should BeNullOrEmpty
                $result.QueryProcessing | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the desired topology for the current server" {
                Set-TargetResource @testParams
            }
        }

        

        Context -Name "No search topology exist and the search service instance isnt running" {
            Mock -CommandName Get-SPEnterpriseSearchComponent {
                return @{}
            }
            $Global:SPDscSearchRoleInstanceCalLCount = 0
            Mock -CommandName Get-SPEnterpriseSearchServiceInstance  {
                if ($Global:SPDscSearchRoleInstanceCalLCount -eq 2) {
                    $Global:SPDscSearchRoleInstanceCalLCount = 0
                    return @{
                        Status = "Online"
                    }
                } else {
                    $Global:SPDscSearchRoleInstanceCalLCount++
                    return @{
                        Status = "Offline"
                    }
                }
            }

            It "Should set the desired topology for the current server and starts the search service instance" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-SPEnterpriseSearchServiceInstance
            }

        }

        Context -Name "A search topology has been applied but it is not correct" {

            Mock -CommandName Get-SPEnterpriseSearchServiceInstance  {
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Online"
                }
            }
        
            It "Should add a missing admin component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent {
                    return @($crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchAdminComponent
            }

            It "Should add a missing crawl component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent {
                    return @($adminComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchCrawlComponent
            }

            It "Should add a missing content processing component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent {
                    return @($adminComponent, $crawlComponent, $analyticsProcessingComponent, $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchContentProcessingComponent
            }

            It "Should add a missing analytics processing component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent {
                    return @($adminComponent, $crawlComponent, $contentProcessingComponent, $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchAnalyticsProcessingComponent
            }

            It "Should add a missing query processing component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent {
                    return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchQueryProcessingComponent
            }

            $testParams = @{
                ServiceAppName          = "Search Service Application"
                Admin                   = @("sharepoint2")
                Crawler                 = @("sharepoint2")
                ContentProcessing       = @("sharepoint2")
                AnalyticsProcessing     = @("sharepoint2")
                QueryProcessing         = @("sharepoint2")
                IndexPartition          = @("sharepoint2")
                FirstPartitionDirectory = "I:\SearchIndexes\0"
            }
            
            Mock -CommandName Get-SPEnterpriseSearchComponent {
                return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent)
            }
            Mock -CommandName Get-SPEnterpriseSearchComponent {
                $adminComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.AdminComponent
                $adminComponent.ServerName = $env:COMPUTERNAME
                $adminComponent.ServerId = $serverId
                $adminComponent.ComponentId = [Guid]::NewGuid()

                $crawlComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.CrawlComponent
                $crawlComponent.ServerName = $env:COMPUTERNAME
                $crawlComponent.ServerId = $serverId
                $crawlComponent.ComponentId = [Guid]::NewGuid()

                $contentProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.ContentProcessingComponent
                $contentProcessingComponent.ServerName = $env:COMPUTERNAME
                $contentProcessingComponent.ServerId = $serverId
                $contentProcessingComponent.ComponentId = [Guid]::NewGuid()

                $analyticsProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.AnalyticsProcessingComponent
                $analyticsProcessingComponent.ServerName = $env:COMPUTERNAME
                $analyticsProcessingComponent.ServerId = $serverId
                $analyticsProcessingComponent.ComponentId = [Guid]::NewGuid()

                $queryProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.QueryProcessingComponent
                $queryProcessingComponent.ServerName = $env:COMPUTERNAME
                $queryProcessingComponent.ServerId = $serverId
                $queryProcessingComponent.ComponentId = [Guid]::NewGuid()

                return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent)
            }

            It "Should remove components that shouldn't be on this server" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchComponent -Times 5
            }

            
        }

        Context -Name "The correct topology on this server exists" {
            Mock -CommandName Get-SPEnterpriseSearchComponent {
                return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent, $indexComponent)
            }
            Mock -CommandName Get-SPEnterpriseSearchComponent {
                $adminComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.AdminComponent
                $adminComponent.ServerName = $env:COMPUTERNAME
                $adminComponent.ServerId = $serverId
                $adminComponent.ComponentId = [Guid]::NewGuid()

                $crawlComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.CrawlComponent
                $crawlComponent.ServerName = $env:COMPUTERNAME
                $crawlComponent.ServerId = $serverId
                $crawlComponent.ComponentId = [Guid]::NewGuid()

                $contentProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.ContentProcessingComponent
                $contentProcessingComponent.ServerName = $env:COMPUTERNAME
                $contentProcessingComponent.ServerId = $serverId
                $contentProcessingComponent.ComponentId = [Guid]::NewGuid()

                $analyticsProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.AnalyticsProcessingComponent
                $analyticsProcessingComponent.ServerName = $env:COMPUTERNAME
                $analyticsProcessingComponent.ServerId = $serverId
                $analyticsProcessingComponent.ComponentId = [Guid]::NewGuid()

                $queryProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.QueryProcessingComponent
                $queryProcessingComponent.ServerName = $env:COMPUTERNAME
                $queryProcessingComponent.ServerId = $serverId
                $queryProcessingComponent.ComponentId = [Guid]::NewGuid()

                $indexComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.IndexComponent
                $indexComponent.ServerName = $env:COMPUTERNAME
                $indexComponent.ServerId = $serverId
                $indexComponent.IndexPartitionOrdinal = 0

                return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent, $indexComponent)
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceInstance  {
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Online"
                }
            }

            $testParams = @{
                ServiceAppName          = "Search Service Application"
                Admin                   = @($env:COMPUTERNAME)
                Crawler                 = @($env:COMPUTERNAME)
                ContentProcessing       = @($env:COMPUTERNAME)
                AnalyticsProcessing     = @($env:COMPUTERNAME)
                QueryProcessing         = @($env:COMPUTERNAME)
                IndexPartition          = @($env:COMPUTERNAME)
                FirstPartitionDirectory = "I:\SearchIndexes\0"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "No search service application exists" {
            Mock -CommandName Get-SPEnterpriseSearchServiceApplication { return $null }
            Mock -CommandName Get-SPEnterpriseSearchComponent {
                return @{}
            }

            It "Should return empty values from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the desired topology for the current server" {
                { Set-TargetResource @testParams } | Should Throw 
            }
        }
    }
}