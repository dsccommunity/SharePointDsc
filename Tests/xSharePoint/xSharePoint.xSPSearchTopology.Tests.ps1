[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPSearchTopology"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSearchTopology" {
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
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint\Modules\xSharePoint.SearchTopology\xSharePoint.SearchTopology.psm1")
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        Mock Start-Sleep {}
        Mock New-Item { return @{} }
        Mock Get-SPEnterpriseSearchServiceInstance  {
            return @{
                Server = @{
                    Address = $env:COMPUTERNAME
                }
                Status = "Online"
            }
        }
        Mock Get-SPEnterpriseSearchServiceApplication {
            return @{
                ActiveTopology = @{}
            }
        }

        Add-Type -TypeDefinition "public class AdminComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
        Add-Type -TypeDefinition "public class CrawlComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
        Add-Type -TypeDefinition "public class ContentProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
        Add-Type -TypeDefinition "public class AnalyticsProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
        Add-Type -TypeDefinition "public class QueryProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
        Add-Type -TypeDefinition "public class IndexComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Int32 IndexPartitionOrdinal {get; set;}}"

        $adminComponent = New-Object AdminComponent
        $adminComponent.ServerName = $env:COMPUTERNAME
        $adminComponent.ComponentId = [Guid]::NewGuid()

        $crawlComponent = New-Object CrawlComponent
        $crawlComponent.ServerName = $env:COMPUTERNAME
        $crawlComponent.ComponentId = [Guid]::NewGuid()

        $contentProcessingComponent = New-Object ContentProcessingComponent
        $contentProcessingComponent.ServerName = $env:COMPUTERNAME
        $contentProcessingComponent.ComponentId = [Guid]::NewGuid()

        $analyticsProcessingComponent = New-Object AnalyticsProcessingComponent
        $analyticsProcessingComponent.ServerName = $env:COMPUTERNAME
        $analyticsProcessingComponent.ComponentId = [Guid]::NewGuid()

        $queryProcessingComponent = New-Object QueryProcessingComponent
        $queryProcessingComponent.ServerName = $env:COMPUTERNAME
        $queryProcessingComponent.ComponentId = [Guid]::NewGuid()

        $indexComponent = New-Object IndexComponent
        $indexComponent.ServerName = $env:COMPUTERNAME
        $indexComponent.IndexPartitionOrdinal = 0

        Mock Start-SPEnterpriseSearchServiceInstance { return $null }
        Mock New-SPEnterpriseSearchTopology { return @{} }
        Mock New-SPEnterpriseSearchAdminComponent { return @{} } -ModuleName "xSharePoint.SearchTopology"
        Mock New-SPEnterpriseSearchCrawlComponent { return @{} } -ModuleName "xSharePoint.SearchTopology"
        Mock New-SPEnterpriseSearchContentProcessingComponent { return @{} } -ModuleName "xSharePoint.SearchTopology"
        Mock New-SPEnterpriseSearchAnalyticsProcessingComponent { return @{} } -ModuleName "xSharePoint.SearchTopology"
        Mock New-SPEnterpriseSearchQueryProcessingComponent { return @{} } -ModuleName "xSharePoint.SearchTopology"
        Mock New-SPEnterpriseSearchIndexComponent { return @{} } -ModuleName "xSharePoint.SearchTopology"
        Mock Set-SPEnterpriseSearchTopology { return @{} }
        Mock Remove-SPEnterpriseSearchComponent { return $null } -ModuleName "xSharePoint.SearchTopology"

        Context "No search topology has been applied" {
            Mock Get-SPEnterpriseSearchComponent {
                return @{}
            }
            Mock Get-SPEnterpriseSearchComponent {
                return @{}
            } -ModuleName "xSharePoint.SearchTopology"

            It "returns empty values from the get method" {
                $result = Get-TargetResource @testParams
                $result.Admin | Should BeNullOrEmpty
                $result.Crawler | Should BeNullOrEmpty
                $result.ContentProcessing | Should BeNullOrEmpty
                $result.AnalyticsProcessing | Should BeNullOrEmpty
                $result.QueryProcessing | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "sets the desired topology for the current server" {
                Set-TargetResource @testParams
            }
        }

        Context "No search topology exist and the search service instance isnt running" {
            Mock Get-SPEnterpriseSearchComponent {
                return @{}
            }
            Mock Get-SPEnterpriseSearchComponent {
                return @{}
            } -ModuleName "xSharePoint.SearchTopology"
            $Global:xSharePointSearchRoleInstanceCalLCount = 0
            Mock Get-SPEnterpriseSearchServiceInstance  {
                if ($Global:xSharePointSearchRoleInstanceCalLCount -eq 2) {
                    $Global:xSharePointSearchRoleInstanceCalLCount = 0
                    return @{
                        Status = "Online"
                    }
                } else {
                    $Global:xSharePointSearchRoleInstanceCalLCount++
                    return @{
                        Status = "Offline"
                    }
                }
            }

            It "sets the desired topology for the current server and starts the search service instance" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-SPEnterpriseSearchServiceInstance
            }

        }

        Context "A search topology has been applied but it is not correct" {

            Mock Get-SPEnterpriseSearchServiceInstance  {
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Online"
                }
            }
            Mock Get-SPEnterpriseSearchServiceInstance  {
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Online"
                }
            } -ModuleName "xSharePoint.SearchTopology"
        
            It "adds a missing admin component" {
                Mock Get-SPEnterpriseSearchComponent {
                    return @($crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchAdminComponent -ModuleName "xSharePoint.SearchTopology"
            }

            It "adds a missing crawl component" {
                Mock Get-SPEnterpriseSearchComponent {
                    return @($adminComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchCrawlComponent -ModuleName "xSharePoint.SearchTopology"
            }

            It "adds a missing content processing component" {
                Mock Get-SPEnterpriseSearchComponent {
                    return @($adminComponent, $crawlComponent, $analyticsProcessingComponent, $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchContentProcessingComponent -ModuleName "xSharePoint.SearchTopology"
            }

            It "adds a missing analytics processing component" {
                Mock Get-SPEnterpriseSearchComponent {
                    return @($adminComponent, $crawlComponent, $contentProcessingComponent, $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchAnalyticsProcessingComponent -ModuleName "xSharePoint.SearchTopology"
            }

            It "adds a missing query processing component" {
                Mock Get-SPEnterpriseSearchComponent {
                    return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchQueryProcessingComponent -ModuleName "xSharePoint.SearchTopology"
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
            
            Mock Get-SPEnterpriseSearchComponent {
                return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent)
            }
            Mock Get-SPEnterpriseSearchComponent {
                Add-Type -TypeDefinition "public class AdminComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
                Add-Type -TypeDefinition "public class CrawlComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
                Add-Type -TypeDefinition "public class ContentProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
                Add-Type -TypeDefinition "public class AnalyticsProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
                Add-Type -TypeDefinition "public class QueryProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"

                $adminComponent = New-Object AdminComponent
                $adminComponent.ServerName = $env:COMPUTERNAME
                $adminComponent.ComponentId = [Guid]::NewGuid()

                $crawlComponent = New-Object CrawlComponent
                $crawlComponent.ServerName = $env:COMPUTERNAME
                $crawlComponent.ComponentId = [Guid]::NewGuid()

                $contentProcessingComponent = New-Object ContentProcessingComponent
                $contentProcessingComponent.ServerName = $env:COMPUTERNAME
                $contentProcessingComponent.ComponentId = [Guid]::NewGuid()

                $analyticsProcessingComponent = New-Object AnalyticsProcessingComponent
                $analyticsProcessingComponent.ServerName = $env:COMPUTERNAME
                $analyticsProcessingComponent.ComponentId = [Guid]::NewGuid()

                $queryProcessingComponent = New-Object QueryProcessingComponent
                $queryProcessingComponent.ServerName = $env:COMPUTERNAME
                $queryProcessingComponent.ComponentId = [Guid]::NewGuid()

                return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent)
            } -ModuleName "xSharePoint.SearchTopology"

            It "Removes components that shouldn't be on this server" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchComponent -Times 5 -ModuleName "xSharePoint.SearchTopology"
            }

            
        }

        Context "The correct topology on this server exists" {
            Mock Get-SPEnterpriseSearchComponent {
                return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent, $indexComponent)
            }
            Mock Get-SPEnterpriseSearchComponent {
                Add-Type -TypeDefinition "public class AdminComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
                Add-Type -TypeDefinition "public class CrawlComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
                Add-Type -TypeDefinition "public class ContentProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
                Add-Type -TypeDefinition "public class AnalyticsProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
                Add-Type -TypeDefinition "public class QueryProcessingComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;}}"
                Add-Type -TypeDefinition "public class IndexComponent { public string ServerName { get; set; } public System.Guid ComponentId {get; set;} public System.Int32 IndexPartitionOrdinal {get; set;}}"

                $adminComponent = New-Object AdminComponent
                $adminComponent.ServerName = $env:COMPUTERNAME
                $adminComponent.ComponentId = [Guid]::NewGuid()

                $crawlComponent = New-Object CrawlComponent
                $crawlComponent.ServerName = $env:COMPUTERNAME
                $crawlComponent.ComponentId = [Guid]::NewGuid()

                $contentProcessingComponent = New-Object ContentProcessingComponent
                $contentProcessingComponent.ServerName = $env:COMPUTERNAME
                $contentProcessingComponent.ComponentId = [Guid]::NewGuid()

                $analyticsProcessingComponent = New-Object AnalyticsProcessingComponent
                $analyticsProcessingComponent.ServerName = $env:COMPUTERNAME
                $analyticsProcessingComponent.ComponentId = [Guid]::NewGuid()

                $queryProcessingComponent = New-Object QueryProcessingComponent
                $queryProcessingComponent.ServerName = $env:COMPUTERNAME
                $queryProcessingComponent.ComponentId = [Guid]::NewGuid()

                $indexComponent = New-Object IndexComponent
                $indexComponent.ServerName = $env:COMPUTERNAME
                $indexComponent.IndexPartitionOrdinal = 0

                return @($adminComponent, $crawlComponent, $contentProcessingComponent, $analyticsProcessingComponent, $queryProcessingComponent, $indexComponent)
            } -ModuleName "xSharePoint.SearchTopology"

            Mock Get-SPEnterpriseSearchServiceInstance  {
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

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}