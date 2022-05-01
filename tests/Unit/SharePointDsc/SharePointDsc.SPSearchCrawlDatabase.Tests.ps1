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
$script:DSCResourceName = 'SPSearchCrawlDatabase'
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
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Initialize tests
                # Mocks for all contexts
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

            # Crawl DB doesn't exist, but should
            # Crawl DB doesn't exists and shouldn't
            # Crawl DB exists and should
            # Crawl DB exists, but shouldn't

            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName   = 'SP_Search_Crawl'
                        ServiceAppName = 'Search Service Application'
                        DatabaseServer = 'SQL01'
                        Ensure         = 'Present'
                    }

                    Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                        return $null
                    }
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw 'Specified Search service application could not be found!'
                }
            }

            Context -Name "When crawl database doesn't exist, but should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName   = 'SP_Search_Crawl'
                        ServiceAppName = 'Search Service Application'
                        DatabaseServer = 'SQL01'
                        Ensure         = 'Present'
                    }

                    Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                        return ""
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlDatabase -MockWith {
                        return $null
                    }

                    Mock -CommandName New-SPEnterpriseSearchCrawlDatabase -MockWith { }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPEnterpriseSearchCrawlDatabase
                }
            }

            Context -Name "When crawl database doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName   = 'SP_Search_Crawl'
                        ServiceAppName = 'Search Service Application'
                        DatabaseServer = 'SQL01'
                        Ensure         = 'Absent'
                    }

                    Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                        return ""
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlDatabase -MockWith {
                        return $null
                    }

                    Mock -CommandName New-SPEnterpriseSearchCrawlDatabase -MockWith { }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When crawl database does exist, but shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName   = 'SP_Search_Crawl'
                        ServiceAppName = 'Search Service Application'
                        DatabaseServer = 'SQL01'
                        Ensure         = 'Absent'
                    }

                    Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                        return ""
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlDatabase -MockWith {
                        return @{
                            Name     = 'SP_Search_Crawl'
                            Database = @{
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                    }

                    Mock -CommandName Remove-SPEnterpriseSearchCrawlDatabase -MockWith { }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPEnterpriseSearchCrawlDatabase
                }
            }

            Context -Name "When crawl database does exist and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName   = 'SP_Search_Crawl'
                        ServiceAppName = 'Search Service Application'
                        DatabaseServer = 'SQL01'
                        Ensure         = 'Present'
                    }

                    Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                        return ""
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlDatabase -MockWith {
                        return @{
                            Name     = 'SP_Search_Crawl'
                            Database = @{
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                    }

                    Mock -CommandName New-SPEnterpriseSearchCrawlDatabase -MockWith { }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            DatabaseName   = 'SP_Search_CrawlStore'
                            ServiceAppName = 'Search Service Application'
                            DatabaseServer = 'SQL01'
                            Ensure         = "Present"
                        }
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlDatabase -MockWith {
                        return [PSCustomObject]@{
                            Name = "SP_Search_CrawlStore"
                        }
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPSearchCrawlDatabase SP_Search_CrawlStore
        {
            DatabaseName         = "SP_Search_CrawlStore";
            DatabaseServer       = $ConfigurationData.NonNodeData.DatabaseServer;
            Ensure               = "Present";
            PsDscRunAsCredential = $Credsspfarm;
            ServiceAppName       = "Search Service Application";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource -SearchSAName 'Search Service Application' | Should -Be $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
