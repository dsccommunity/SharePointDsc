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
$script:DSCResourceName = 'SPSearchIndexPartition'
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
                    return @{ }
                }
                Mock -CommandName Start-Sleep -MockWith { }
                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{
                        ActiveTopology = @{ }
                    }
                }
                Mock -CommandName New-SPEnterpriseSearchTopology -MockWith {
                    return @{ }
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
            }

            # Test contexts
            Context -Name "Search index doesn't exist and it should" {
                BeforeAll {
                    $testParams = @{
                        Index          = "0"
                        Servers        = @($env:COMPUTERNAME)
                        RootDirectory  = "C:\SearchIndex\0"
                        ServiceAppName = "Search Service Application"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchComponent {
                        return @()
                    }

                    $Global:SPDscSearchRoleInstanceCallCount = 0
                }

                It "Should return an empty server list from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Servers | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the search index in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPEnterpriseSearchIndexComponent
                }
            }

            Context -Name "Search index does exist and it should" {
                BeforeAll {
                    $testParams = @{
                        Index          = "0"
                        Servers        = @($env:COMPUTERNAME)
                        RootDirectory  = "C:\SearchIndex\0"
                        ServiceAppName = "Search Service Application"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                        return @($indexComponent)
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Servers | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Search index exists and it shouldn't" {
                BeforeAll {
                    $testParams = @{
                        Index          = "0"
                        Servers        = @("SharePoint2")
                        RootDirectory  = "C:\SearchIndex\0"
                        ServiceAppName = "Search Service Application"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                        return @($indexComponent)
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the search index in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPEnterpriseSearchComponent
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Servers        = @("Server2", "Server3")
                            Index          = 1
                            RootDirectory  = "I:\SearchIndexes\1"
                            ServiceAppName = "Search Service Application"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName    = "Search Service Application"
                            Name           = "Search Service Application"
                            ActiveTopology = @{
                                Id = "Test"
                            }
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

                    Mock -CommandName Get-SPEnterpriseSearchComponent -MockWith {
                        $spSearchIndexComponent = [PSCustomObject]@{
                            IndexPartitionOrdinal = 1
                            ServerName            = "Server02"
                            RootDirectory         = "I:\SearchIndexes\1"
                        }
                        $spSearchIndexComponent = $spSearchIndexComponent | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "IndexComponent"
                            }
                        } -PassThru -Force
                        return $spSearchIndexComponent
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPSearchIndexPartition [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Index                = 1;
            PsDscRunAsCredential = \$Credsspfarm;
            RootDirectory        = "I:\\SearchIndexes\\1";
            Servers              = "\$ConfigurationData.NonNodeData.SearchIndexPartitionServers";
            ServiceAppName       = "Search Service Application";
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
