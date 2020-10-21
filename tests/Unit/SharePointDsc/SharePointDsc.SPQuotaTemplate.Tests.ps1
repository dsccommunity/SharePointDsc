[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPQuotaTemplate'
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
                Add-Type -TypeDefinition @"
            namespace Microsoft.SharePoint.Administration
            {
                public class SPQuotaTemplate
                {
                    public string Name { get; set; }
                    public long StorageMaximumLevel { get; set; }
                    public long StorageWarningLevel { get; set; }
                    public double UserCodeMaximumLevel { get; set; }
                    public double UserCodeWarningLevel { get; set; }
                }
            }
"@

                # Mocks for all contexts
                Mock -CommandName Get-SPFarm -MockWith {
                    return @{ }
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
            Context -Name "WarningUsagePointsSolutions is lower than MaximumUsagePointsSolutions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                        = "Test"
                        StorageMaxInMB              = 1024
                        StorageWarningInMB          = 512
                        MaximumUsagePointsSolutions = 1000
                        WarningUsagePointsSolutions = 1800
                        Ensure                      = "Present"
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw "Unable to detect local farm"
                    }
                }

                It "Should throw an exception in the get method to say MaxPoints need to be larger than WarningPoints" {
                    { Get-TargetResource @testParams } | Should -Throw "MaximumUsagePointsSolutions must be equal to or larger than"
                }

                It "Should throw an exception in the test method to say MaxPoints need to be larger than WarningPoints" {
                    { Test-TargetResource @testParams } | Should -Throw "MaximumUsagePointsSolutions must be equal to or larger than"
                }

                It "Should throw an exception in the set method to say MaxPoints need to be larger than WarningPoints" {
                    { Set-TargetResource @testParams } | Should -Throw "MaximumUsagePointsSolutions must be equal to or larger than"
                }
            }

            Context -Name "StorageWarningInMB is lower than StorageMaxInMB" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                        = "Test"
                        StorageMaxInMB              = 1024
                        StorageWarningInMB          = 1512
                        MaximumUsagePointsSolutions = 1000
                        WarningUsagePointsSolutions = 800
                        Ensure                      = "Present"
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw "Unable to detect local farm"
                    }
                }

                It "Should throw an exception in the get method to say StorageMax need to be larger than StorageWarning" {
                    { Get-TargetResource @testParams } | Should -Throw "StorageMaxInMB must be equal to or larger than StorageWarningInMB."
                }

                It "Should throw an exception in the test method to say StorageMax need to be larger than StorageWarning" {
                    { Test-TargetResource @testParams } | Should -Throw "StorageMaxInMB must be equal to or larger than StorageWarningInMB."
                }

                It "Should throw an exception in the set method to say StorageMax need to be larger than StorageWarning" {
                    { Set-TargetResource @testParams } | Should -Throw "StorageMaxInMB must be equal to or larger than StorageWarningInMB."
                }
            }

            Context -Name "Using Max or Warning parameters with Ensure=Absent" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                        = "Test"
                        StorageMaxInMB              = 1024
                        StorageWarningInMB          = 512
                        MaximumUsagePointsSolutions = 1000
                        WarningUsagePointsSolutions = 800
                        Ensure                      = "Absent"
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw "Unable to detect local farm"
                    }
                }

                It "Should return Ensure=Absent" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should throw an exception in the test method to say Max and Warning parameters should not be used" {
                    { Test-TargetResource @testParams } | Should -Throw "Do not use StorageMaxInMB, StorageWarningInMB"
                }

                It "Should throw an exception in the set method to say Max and Warning parameters should not be used" {
                    { Set-TargetResource @testParams } | Should -Throw "Do not use StorageMaxInMB, StorageWarningInMB"
                }
            }

            Context -Name "The server is not part of SharePoint farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                        = "Test"
                        StorageMaxInMB              = 1024
                        StorageWarningInMB          = 512
                        MaximumUsagePointsSolutions = 1000
                        WarningUsagePointsSolutions = 800
                        Ensure                      = "Present"
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw "Unable to detect local farm"
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }
            }

            Context -Name "The server is in a farm and the incorrect settings have been applied to the template" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                        = "Test"
                        StorageMaxInMB              = 1024
                        StorageWarningInMB          = 512
                        MaximumUsagePointsSolutions = 1000
                        WarningUsagePointsSolutions = 800
                        Ensure                      = "Present"
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        $quotaTemplates = @(@{
                                Test = @{
                                    StorageMaximumLevel  = 512
                                    StorageWarningLevel  = 256
                                    UserCodeMaximumLevel = 400
                                    UserCodeWarningLevel = 200
                                }
                            })
                        $quotaTemplatesCol = { $quotaTemplates }.Invoke()

                        $contentService = @{
                            QuotaTemplates = $quotaTemplatesCol
                        }

                        $contentService = $contentService | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $Global:SPDscQuotaTemplatesUpdated = $true
                        } -PassThru
                        return $contentService
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the quota template settings" {
                    $Global:SPDscQuotaTemplatesUpdated = $false
                    Set-TargetResource @testParams
                    $Global:SPDscQuotaTemplatesUpdated | Should -Be $true
                }
            }

            Context -Name "The server is in a farm and the template doesn't exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                        = "Test"
                        StorageMaxInMB              = 1024
                        StorageWarningInMB          = 512
                        MaximumUsagePointsSolutions = 1000
                        WarningUsagePointsSolutions = 800
                        Ensure                      = "Present"
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        $quotaTemplates = @(@{
                                Test = $null
                            })
                        $quotaTemplatesCol = { $quotaTemplates }.Invoke()

                        $contentService = @{
                            QuotaTemplates = $quotaTemplatesCol
                        }

                        $contentService = $contentService | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $Global:SPDscQuotaTemplatesUpdated = $true
                        } -PassThru
                        return $contentService
                    }
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new quota template" {
                    $Global:SPDscQuotaTemplatesUpdated = $false
                    Set-TargetResource @testParams
                    $Global:SPDscQuotaTemplatesUpdated | Should -Be $true
                }
            }

            Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                        = "Test"
                        StorageMaxInMB              = 1024
                        StorageWarningInMB          = 512
                        MaximumUsagePointsSolutions = 1000
                        WarningUsagePointsSolutions = 800
                        Ensure                      = "Present"
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        $returnVal = @{
                            QuotaTemplates = @{
                                Test = @{
                                    StorageMaximumLevel  = 1073741824
                                    StorageWarningLevel  = 536870912
                                    UserCodeMaximumLevel = 1000
                                    UserCodeWarningLevel = 800
                                }
                            }
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $Global:SPDscQuotaTemplatesUpdated = $true
                        } -PassThru
                        return $returnVal
                    }
                }

                It "Should return values from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be 'Present'
                    $result.StorageMaxInMB | Should -Be 1024
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }

            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
