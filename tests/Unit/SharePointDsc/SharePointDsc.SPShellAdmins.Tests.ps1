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
$script:DSCResourceName = 'SPShellAdmins'
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

                # Mocks for all contexts
                Mock -CommandName Add-SPShellAdmin -MockWith { }
                Mock -CommandName Remove-SPShellAdmin -MockWith { }

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
            Context -Name "The server is not part of SharePoint farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = "contoso\user1", "contoso\user2"
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw "Unable to detect local farm"
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Members | Should -BeNullOrEmpty
                    $result.MembersToInclude | Should -BeNullOrEmpty
                    $result.MembersToExclude | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }
            }

            Context -Name "ContentDatabases and AllContentDatabases parameters used simultaneously" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = "contoso\user1", "contoso\user2"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                                    Name    = "SharePoint_Content_Contoso1"
                                    Members = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                        )
                        AllDatabases     = $true
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Members | Should -BeNullOrEmpty
                    $result.MembersToInclude | Should -BeNullOrEmpty
                    $result.MembersToExclude | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Cannot use the Databases parameter together with the AllDatabases parameter"
                }
            }

            Context -Name "Members and MembersToInclude parameters used simultaneously - General permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = "contoso\user1", "contoso\user2"
                        MembersToInclude = "contoso\user1", "contoso\user2"
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Members | Should -BeNullOrEmpty
                    $result.MembersToInclude | Should -BeNullOrEmpty
                    $result.MembersToExclude | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
                }
            }

            Context -Name "None of the Members, MembersToInclude and MembersToExclude parameters are used - General permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Members | Should -BeNullOrEmpty
                    $result.MembersToInclude | Should -BeNullOrEmpty
                    $result.MembersToExclude | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
                }
            }

            Context -Name "Members and MembersToInclude parameters used simultaneously - Database permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name             = "SharePoint_Content_Contoso1"
                                    Members          = "contoso\user1", "contoso\user2"
                                    MembersToInclude = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Members | Should -BeNullOrEmpty
                    $result.MembersToInclude | Should -BeNullOrEmpty
                    $result.MembersToExclude | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Databases: Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
                }
            }

            Context -Name "Databases and ExcludeDatabases parameters used simultaneously" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name    = "SharePoint_Content_Contoso1"
                                    Members = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                        )
                        ExcludeDatabases = "SharePoint_Content_Contoso2"
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Name | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Cannot use the Databases parameter together with the ExcludeDatabases parameter"
                }
            }

            Context -Name "None of the Members, MembersToInclude and MembersToExclude parameters are used - Database permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name = "SharePoint_Content_Contoso1"
                                } -ClientOnly)
                        )
                    }
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Members | Should -BeNullOrEmpty
                    $result.MembersToInclude | Should -BeNullOrEmpty
                    $result.MembersToExclude | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Databases: At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
                }
            }

            Context -Name "Specified content database does not exist - Database permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name    = "SharePoint_Content_Contoso3"
                                    Members = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SharePoint_Content_Contoso1"
                                Id   = "F9168C5E-CEB2-4faa-B6BF-329BF39FA1E4"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso2"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A8"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified database does not exist"
                }
            }

            Context -Name "AllDatabases parameter is used and permissions do not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = "contoso\user1", "contoso\user2"
                        AllDatabases     = $true
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{
                                UserName = "contoso\user3", "contoso\user4"
                            }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user3", "contoso\user4"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SharePoint_Content_Contoso1"
                                Id   = "F9168C5E-CEB2-4faa-B6BF-329BF39FA1E4"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso2"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A8"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPShellAdmin
                    Assert-MockCalled Remove-SPShellAdmin
                }
            }

            Context -Name "AllDatabases parameter is used with ExcludeDatabases and permissions do not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = "contoso\user1", "contoso\user2"
                        AllDatabases     = $true
                        ExcludeDatabases = "SharePoint_Content_Contoso3"
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{
                                UserName = "contoso\user3", "contoso\user4"
                            }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SharePoint_Content_Contoso1"
                                Id   = "F9168C5E-CEB2-4faa-B6BF-329BF39FA1E4"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso2"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A8"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso3"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A9"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPShellAdmin
                    Assert-MockCalled Remove-SPShellAdmin
                }
            }

            Context -Name "Configured Members do not match the actual members - General permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = "contoso\user1", "contoso\user2"
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{ }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{ UserName = "contoso\user3", "contoso\user4" }
                        }
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPShellAdmin
                    Assert-MockCalled Remove-SPShellAdmin
                }
            }

            Context -Name "Configured Members match the actual members - General permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = "contoso\user1", "contoso\user2"
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{ }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Configured Members do not match the actual members - Database permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name    = "SharePoint_Content_Contoso1"
                                    Members = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name    = "SharePoint_Content_Contoso2"
                                    Members = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{
                                UserName = "contoso\user3", "contoso\user4"
                            }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SharePoint_Content_Contoso1"
                                Id   = "F9168C5E-CEB2-4faa-B6BF-329BF39FA1E4"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso2"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A8"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPShellAdmin
                    Assert-MockCalled Remove-SPShellAdmin
                }
            }

            Context -Name "Configured Members match the actual members - Database permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name    = "SharePoint_Content_Contoso1"
                                    Members = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name    = "SharePoint_Content_Contoso2"
                                    Members = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SharePoint_Content_Contoso1"
                                Id   = "F9168C5E-CEB2-4faa-B6BF-329BF39FA1E4"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso2"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A8"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Configured MembersToInclude do not match the actual members - General permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        MembersToInclude = "contoso\user1", "contoso\user2"
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{ }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user3", "contoso\user4"
                            }
                        }
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPShellAdmin
                }
            }

            Context -Name "Configured MembersToInclude match the actual members - General permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        MembersToInclude = "contoso\user1", "contoso\user2"
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{ }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2", "contoso\user3"
                            }
                        }
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Configured MembersToInclude do not match the actual members - Database permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name             = "SharePoint_Content_Contoso1"
                                    MembersToInclude = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name             = "SharePoint_Content_Contoso2"
                                    MembersToInclude = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{
                                UserName = "contoso\user3", "contoso\user4"
                            }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SharePoint_Content_Contoso1"
                                Id   = "F9168C5E-CEB2-4faa-B6BF-329BF39FA1E4"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso2"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A8"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPShellAdmin
                }
            }

            Context -Name "Configured MembersToInclude match the actual members - Database permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name             = "SharePoint_Content_Contoso1"
                                    MembersToInclude = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name             = "SharePoint_Content_Contoso2"
                                    MembersToInclude = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2", "contoso\user3"
                            }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SharePoint_Content_Contoso1"
                                Id   = "F9168C5E-CEB2-4faa-B6BF-329BF39FA1E4"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso2"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A8"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Configured MembersToExclude do not match the actual members - General permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        MembersToExclude = "contoso\user1", "contoso\user2"
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{ }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPShellAdmin
                }
            }

            Context -Name "Configured MembersToExclude match the actual members - General permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        MembersToExclude = "contoso\user1", "contoso\user2"
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{ }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user3", "contoso\user4"
                            }
                        }
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Configured MembersToExclude do not match the actual members - Database permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name             = "SharePoint_Content_Contoso1"
                                    MembersToExclude = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name             = "SharePoint_Content_Contoso2"
                                    MembersToExclude = "contoso\user1", "contoso\user2"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SharePoint_Content_Contoso1"
                                Id   = "F9168C5E-CEB2-4faa-B6BF-329BF39FA1E4"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso2"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A8"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPShellAdmin
                }
            }

            Context -Name "Configured MembersToExclude match the actual members - Database permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Databases        = @(
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name             = "SharePoint_Content_Contoso1"
                                    MembersToExclude = "contoso\user3", "contoso\user4"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPDatabasePermissions -Property @{
                                    Name             = "SharePoint_Content_Contoso2"
                                    MembersToExclude = "contoso\user5", "contoso\user6"
                                } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPShellAdmin -MockWith {
                        if ($database)
                        {
                            # Database parameter used, return database permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                        else
                        {
                            # Database parameter not used, return general permissions
                            return @{
                                UserName = "contoso\user1", "contoso\user2"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SharePoint_Content_Contoso1"
                                Id   = "F9168C5E-CEB2-4faa-B6BF-329BF39FA1E4"
                            },
                            @{
                                Name = "SharePoint_Content_Contoso2"
                                Id   = "936DA01F-9ABD-4d9d-80C7-02AF85C822A8"
                            }
                        )
                    }
                }

                It "Should return null from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
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
