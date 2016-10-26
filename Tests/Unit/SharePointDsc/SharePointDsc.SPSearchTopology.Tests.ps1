[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPSearchTopology"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $mockPath = Join-Path -Path $Global:SPDscHelper.RepoRoot `
                              -ChildPath "Tests/Unit/SharePointDsc/SharePointDsc.SPSearchTopology.Mocks.cs"
        Add-Type -LiteralPath $mockPath

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

        # Mocks for all contexts   
        Mock -CommandName Start-Sleep -MockWith {}
        Mock -CommandName New-Item -MockWith { return @{} }
        Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith  {
            return @{
                Server = @{
                    Address = $env:COMPUTERNAME
                }
                Status = "Online"
            }
        }
        Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
            return @{
                ActiveTopology = @{}
            }
        }
        Mock -CommandName Start-SPEnterpriseSearchServiceInstance -MockWith { 
            return $null 
        }
        Mock -CommandName New-SPEnterpriseSearchTopology -MockWith { 
            return @{} 
        }
        Mock -CommandName New-SPEnterpriseSearchAdminComponent -MockWith { 
            return @{} 
        } 
        Mock -CommandName New-SPEnterpriseSearchCrawlComponent -MockWith { 
            return @{} 
        }
        Mock -CommandName New-SPEnterpriseSearchContentProcessingComponent -MockWith { 
            return @{} 
        }
        Mock -CommandName New-SPEnterpriseSearchAnalyticsProcessingComponent -MockWith { 
            return @{} 
        }
        Mock -CommandName New-SPEnterpriseSearchQueryProcessingComponent -MockWith { 
            return @{} 
        }
        Mock -CommandName New-SPEnterpriseSearchIndexComponent -MockWith { 
            return @{} 
        }
        Mock -CommandName Set-SPEnterpriseSearchTopology -MockWith { 
            return @{} 
        }
        Mock -CommandName Remove-SPEnterpriseSearchComponent -MockWith { 
            return $null 
        }
        Mock -CommandName Get-SPServer -MockWith {
            return @(
                @{
                    Name = $env:COMPUTERNAME
                    Id = $serverId
                }
            )
        }

        # Test contexts
        Context -Name "No search topology has been applied" -Fixture {
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

            Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
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

        Context -Name "No search topology exist and the search service instance isnt running" -Fixture {
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
            
            Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                return @{}
            }
            $Global:SPDscSearchRoleInstanceCalLCount = 0
            Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith {
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

        Context -Name "A search topology has been applied but it is not correct" -Fixture {
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
            
            Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith {
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Online"
                }
            }
        
            It "Should add a missing admin component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                    return @(
                        $crawlComponent, 
                        $contentProcessingComponent, 
                        $analyticsProcessingComponent, 
                        $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchAdminComponent
            }

            It "Should add a missing crawl component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                    return @(
                        $adminComponent, 
                        $contentProcessingComponent, 
                        $analyticsProcessingComponent, 
                        $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchCrawlComponent
            }

            It "Should add a missing content processing component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                    return @(
                        $adminComponent, 
                        $crawlComponent, 
                        $analyticsProcessingComponent, 
                        $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchContentProcessingComponent
            }

            It "Should add a missing analytics processing component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                    return @(
                        $adminComponent, 
                        $crawlComponent,
                        $contentProcessingComponent, 
                        $queryProcessingComponent)
                }
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchAnalyticsProcessingComponent
            }

            It "Should add a missing query processing component" {
                Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                    return @(
                        $adminComponent, 
                        $crawlComponent, 
                        $contentProcessingComponent, 
                        $analyticsProcessingComponent)
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
            
            Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                return @(
                    $adminComponent, 
                    $crawlComponent, 
                    $contentProcessingComponent, 
                    $analyticsProcessingComponent, 
                    $queryProcessingComponent)
            }

            It "Should remove components that shouldn't be on this server" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchComponent -Times 5
            }
        }

        Context -Name "The correct topology on this server exists" -Fixture {
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

            Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                return @(
                    $adminComponent, 
                    $crawlComponent, 
                    $contentProcessingComponent, 
                    $analyticsProcessingComponent, 
                    $queryProcessingComponent, 
                    $indexComponent)
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceInstance  {
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Online"
                }
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "No search service application exists" -Fixture {
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

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith { 
                return $null 
            }
            Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
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

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
