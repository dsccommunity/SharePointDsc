[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPSearchTopology'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -Scriptblock $Global:SPDscHelper.InitializeScript -NoNewScope

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
                Mock -CommandName Start-Sleep -MockWith { }
                Mock -CommandName New-Item -MockWith { return @{ } }
                Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith {
                    return @{
                        Server     = @{
                            Address = $env:COMPUTERNAME
                        }
                        Components = @(
                            @{
                                IndexLocation = @("C:\Program Files\Fake", "C:\Program Files\Fake2")
                            },
                            @{
                                IndexLocation = @("C:\Program Files\Fake3")
                            }
                        )
                        Status     = "Online"
                    }
                }
                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{
                        ActiveTopology = @{ }
                    }
                }
                Mock -CommandName Start-SPEnterpriseSearchServiceInstance -MockWith {
                    return $null
                }
                Mock -CommandName New-SPEnterpriseSearchTopology -MockWith {
                    $returnval = @{ }
                    $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                        -Name AddComponent `
                        -Value { } `
                        -PassThru `
                        -Force
                    return $returnval
                }
                Mock -CommandName New-SPEnterpriseSearchAdminComponent -MockWith {
                    return @{ }
                }
                Mock -CommandName New-SPEnterpriseSearchCrawlComponent -MockWith {
                    return @{ }
                }
                Mock -CommandName New-SPEnterpriseSearchContentProcessingComponent -MockWith {
                    return @{ }
                }
                Mock -CommandName New-SPEnterpriseSearchAnalyticsProcessingComponent -MockWith {
                    return @{ }
                }
                Mock -CommandName New-SPEnterpriseSearchQueryProcessingComponent -MockWith {
                    return @{ }
                }
                Mock -CommandName New-SPEnterpriseSearchIndexComponent -MockWith {
                    return @{ }
                }
                Mock -CommandName Set-SPEnterpriseSearchTopology -MockWith {
                    return @{ }
                }
                Mock -CommandName Remove-SPEnterpriseSearchComponent -MockWith {
                    return $null
                }
                Mock -CommandName Get-SPServer -MockWith {
                    return @(
                        @{
                            Name = $env:COMPUTERNAME
                            Id   = $serverId
                        }
                    )
                }

                function Add-SPDscEvent
                {
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType,

                        [Parameter()]
                        [System.UInt32]
                        $EventID
                    )
                }
            }

            # Test contexts
            Context -Name "No search topology has been applied" -Fixture {
                BeforeAll {
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
                        return @{ }
                    }
                }

                It "Should return empty values from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Admin | Should -BeNullOrEmpty
                    $result.Crawler | Should -BeNullOrEmpty
                    $result.ContentProcessing | Should -BeNullOrEmpty
                    $result.AnalyticsProcessing | Should -BeNullOrEmpty
                    $result.QueryProcessing | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the desired topology for the current server" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "No search topology has been applied, with servers specified as FQDN" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ServiceAppName          = "Search Service Application"
                        Admin                   = @("$($env:COMPUTERNAME).domain.com")
                        Crawler                 = @("$($env:COMPUTERNAME).domain.com")
                        ContentProcessing       = @("$($env:COMPUTERNAME).domain.com")
                        AnalyticsProcessing     = @("$($env:COMPUTERNAME).domain.com")
                        QueryProcessing         = @("$($env:COMPUTERNAME).domain.com")
                        IndexPartition          = @("$($env:COMPUTERNAME).domain.com")
                        FirstPartitionDirectory = "I:\SearchIndexes\0"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                        return @{ }
                    }

                    Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith {
                        return @{
                            Server = @{
                                Address = "$($env:COMPUTERNAME).domain.com"
                            }
                            Status = "Online"
                        }
                    } -ParameterFilter { $Identity -eq "$($env:COMPUTERNAME).domain.com" }

                    Mock -CommandName Get-CimInstance -MockWith {
                        return @{
                            Domain = "domain.com"
                        }
                    }

                    Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith {
                        return $null
                    } -ParameterFilter { $Identity -ne "$($env:COMPUTERNAME).domain.com" }
                }

                It "Should return empty values from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Admin | Should -BeNullOrEmpty
                    $result.Crawler | Should -BeNullOrEmpty
                    $result.ContentProcessing | Should -BeNullOrEmpty
                    $result.AnalyticsProcessing | Should -BeNullOrEmpty
                    $result.QueryProcessing | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the desired topology for the current server" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "No search topology exist and the search service instance isnt running" -Fixture {
                BeforeAll {
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
                        return @{ }
                    }
                    $Global:SPDscSearchRoleInstanceCalLCount = 0
                    Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith {
                        if ($Global:SPDscSearchRoleInstanceCalLCount -eq 2)
                        {
                            $Global:SPDscSearchRoleInstanceCalLCount = 0
                            return @{
                                Status = "Online"
                            }
                        }
                        else
                        {
                            $Global:SPDscSearchRoleInstanceCalLCount++
                            return @{
                                Status = "Offline"
                            }
                        }
                    }
                }

                It "Should set the desired topology for the current server and starts the search service instance" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-SPEnterpriseSearchServiceInstance
                }
            }

            Context -Name "A search topology has been applied but it is not correct" -Fixture {
                BeforeAll {
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

                It "Should remove components that shouldn't be on this server" {
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

                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPEnterpriseSearchComponent -Times 5
                }
            }

            Context -Name "The correct topology on this server exists" -Fixture {
                BeforeAll {
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

                    Mock -CommandName Get-SPEnterpriseSearchServiceInstance {
                        return @{
                            Server     = @{
                                Address = $env:COMPUTERNAME
                            }
                            Components = @{
                                IndexLocation = "D:\Index"
                            }
                            Status     = "Online"

                        }
                    }
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should return the FirstIndexPartition location" {
                    (Get-TargetResource @testParams).FirstPartitionDirectory | Should -Be "D:\Index"
                }
            }

            Context -Name "No search service application exists" -Fixture {
                BeforeAll {
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
                        return @{ }
                    }
                }

                It "Should return empty values from the get method" {
                    (Get-TargetResource @testParams).Admin | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the desired topology for the current server" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "A search topology exists that has a server with a new ID in it" -Fixture {
                BeforeAll {
                    $newServerId = New-Guid
                    $adminComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.AdminComponent
                    $adminComponent.ServerName = $null
                    $adminComponent.ServerId = $newServerId
                    $adminComponent.ComponentId = [Guid]::NewGuid()

                    $crawlComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.CrawlComponent
                    $crawlComponent.ServerName = $null
                    $crawlComponent.ServerId = $newServerId
                    $crawlComponent.ComponentId = [Guid]::NewGuid()

                    $contentProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.ContentProcessingComponent
                    $contentProcessingComponent.ServerName = $null
                    $contentProcessingComponent.ServerId = $newServerId
                    $contentProcessingComponent.ComponentId = [Guid]::NewGuid()

                    $analyticsProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.AnalyticsProcessingComponent
                    $analyticsProcessingComponent.ServerName = $null
                    $analyticsProcessingComponent.ServerId = $newServerId
                    $analyticsProcessingComponent.ComponentId = [Guid]::NewGuid()

                    $queryProcessingComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.QueryProcessingComponent
                    $queryProcessingComponent.ServerName = $null
                    $queryProcessingComponent.ServerId = $newServerId
                    $queryProcessingComponent.ComponentId = [Guid]::NewGuid()

                    $indexComponent = New-Object Microsoft.Office.Server.Search.Administration.Topology.IndexComponent
                    $indexComponent.ServerName = $null
                    $indexComponent.ServerId = $newServerId
                    $indexComponent.IndexPartitionOrdinal = 0

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

                    Mock -CommandName Get-SPEnterpriseSearchServiceInstance {
                        return @{
                            Server = @{
                                Address = $env:COMPUTERNAME
                            }
                            Status = "Online"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the topology in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPEnterpriseSearchComponent -Times 5
                    Assert-MockCalled Set-SPEnterpriseSearchTopology
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServiceAppName          = "Search Service Application"
                            Admin                   = @("Server1", "Server2")
                            Crawler                 = @("Server1", "Server2")
                            ContentProcessing       = @("Server1", "Server2")
                            AnalyticsProcessing     = @("Server1", "Server2")
                            QueryProcessing         = @("Server3", "Server4")
                            FirstPartitionDirectory = "I:\SearchIndexes\0"
                            IndexPartition          = @("Server3", "Server4")
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = "Search Service Application"
                            Name        = "Search Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPSearchTopology [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Admin                   = "\$ConfigurationData.NonNodeData.SearchAdminServers";
            AnalyticsProcessing     = "\$ConfigurationData.NonNodeData.SearchAnalyticsProcessingServers";
            ContentProcessing       = "\$ConfigurationData.NonNodeData.SearchContentProcessingServers";
            Crawler                 = "\$ConfigurationData.NonNodeData.SearchCrawlerServers";
            FirstPartitionDirectory = "I:\\SearchIndexes\\0";
            IndexPartition          = "\$ConfigurationData.NonNodeData.SearchIndexPartitionServers";
            PsDscRunAsCredential    = \$Credsspfarm;
            QueryProcessing         = "\$ConfigurationData.NonNodeData.QueryProcessingServers";
            ServiceAppName          = "Search Service Application";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
