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
                                              -DscResource "SPSearchIndexPartition"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        Add-Type -TypeDefinition @"
        public class IndexComponent 
        { 
            public string ServerName { get; set; } 
            public System.Guid ComponentId {get; set;} 
            public System.Int32 IndexPartitionOrdinal {get; set;}
        }
"@
        $indexComponent = New-Object -TypeName IndexComponent
        $indexComponent.ServerName = $env:COMPUTERNAME
        $indexComponent.IndexPartitionOrdinal = 0

        # Mocks for all contexts   
        Mock -CommandName New-PSSession -MockWith {
            return $null
        }
        Mock -CommandName New-Item -MockWith { 
            return @{} 
        }
        Mock -CommandName Start-Sleep -MockWith {}
        Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
            return @{
                ActiveTopology = @{}
            }
        } 
        Mock -CommandName New-SPEnterpriseSearchTopology -MockWith { 
            return @{} 
        }

        $Global:SPDscSearchRoleInstanceCallCount = 0
        Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith {
            if ($Global:SPDscSearchRoleInstanceCallCount -eq 2) 
            {
                $Global:SPDscSearchRoleInstanceCallCount = 0
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Online"
                }
            } 
            else 
            {
                $Global:SPDscSearchRoleInstanceCallCount++
                return @{
                    Server = @{
                        Address = $env:COMPUTERNAME
                    }
                    Status = "Offline"
                }
            }
        }
        Mock -CommandName Start-SPEnterpriseSearchServiceInstance -MockWith { 
            return $null 
        }
        Mock -CommandName New-SPEnterpriseSearchIndexComponent -MockWith { 
            return $null 
        }
        Mock -CommandName Remove-SPEnterpriseSearchComponent -MockWith { 
            return $null 
        }
        Mock -CommandName Set-SPEnterpriseSearchTopology -MockWith { 
            return $null 
        }

        # Test contexts        
        Context -Name "Search index doesn't exist and it should" {
            $testParams = @{
                Index = "0"
                Servers = @($env:COMPUTERNAME)
                RootDirectory = "C:\SearchIndex\0"
                ServiceAppName = "Search Service Application"
            }

            Mock -CommandName Get-SPEnterpriseSearchComponent { 
                return @() 
            }
            
            $Global:SPDscSearchRoleInstanceCallCount = 0

            It "Should return an empty server list from the get method" {
                $result = Get-TargetResource @testParams
                $result.Servers | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create the search index in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchIndexComponent
            }
        }
        
        Context -Name "Search index does exist and it should" {
            $testParams = @{
                Index = "0"
                Servers = @($env:COMPUTERNAME)
                RootDirectory = "C:\SearchIndex\0"
                ServiceAppName = "Search Service Application"
            }
            
            Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith { 
                return @($indexComponent) 
            }

            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Servers | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Search index exists and it shouldn't" {
            $testParams = @{
                Index = "0"
                Servers = @("SharePoint2")
                RootDirectory = "C:\SearchIndex\0"
                ServiceAppName = "Search Service Application"
            }
            
            Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith { 
                return @($indexComponent) 
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should remove the search index in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchComponent
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
