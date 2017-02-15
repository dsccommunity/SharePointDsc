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
                                              -DscResource "SPShellAdmins"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts   
        Mock -CommandName Add-SPShellAdmin -MockWith {}
        Mock -CommandName Remove-SPShellAdmin -MockWith {}

        # Test contexts
        Context -Name "The server is not part of SharePoint farm" -Fixture {
            $testParams = @{
                Name         = "ShellAdmins"
                Members      = "contoso\user1", "contoso\user2"
            }

            Mock -CommandName Get-SPFarm -MockWith { 
                throw "Unable to detect local farm" 
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Context -Name "Members and MembersToInclude parameters used simultaniously - General permissions" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                Members          = "contoso\user1", "contoso\user2"
                MembersToInclude = "contoso\user1", "contoso\user2"
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
            }
        }

        Context -Name "None of the Members, MembersToInclude and MembersToExclude parameters are used - General permissions" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
            }
        }

        Context -Name "Members and MembersToInclude parameters used simultaniously - ContentDatabase permissions" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name = "SharePoint_Content_Contoso1"
                        Members = "contoso\user1", "contoso\user2"
                        MembersToInclude = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                )
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "ContentDatabases: Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
            }
        }

        Context -Name "None of the Members, MembersToInclude and MembersToExclude parameters are used - ContentDatabase permissions" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name = "SharePoint_Content_Contoso1"
                    } -ClientOnly)
                )
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "ContentDatabases: At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
            }
        }

        Context -Name "Specified content database does not exist - ContentDatabase permissions" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name    = "SharePoint_Content_Contoso3"
                        Members = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPContentDatabase -MockWith {
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

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                { Test-TargetResource @testParams } | Should throw "Specified database does not exist"
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Specified database does not exist"
            }
        }

        Context -Name "AllContentDatabases parameter is used and permissions do not match" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                Members          = "contoso\user1", "contoso\user2"
                AllContentDatabases = $true
            }

            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{ 
                        UserName = "contoso\user3","contoso\user4" 
                    }
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                }
            }

            Mock -CommandName Get-SPContentDatabase -MockWith {
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

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context -Name "AllContentDatabases parameter is used and permissions do not match" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                Members          = "contoso\user1", "contoso\user2"
                AllContentDatabases = $true
            }

            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                }
            }

            Mock -CommandName Get-SPContentDatabase -MockWith {
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

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Configured Members do not match the actual members - General permissions" -Fixture {
            $testParams = @{
                Name         = "ShellAdmins"
                Members      = "contoso\user1", "contoso\user2"
            }

            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{}
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user3","contoso\user4" }
                }
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context -Name "Configured Members match the actual members - General permissions" -Fixture {
            $testParams = @{
                Name         = "ShellAdmins"
                Members      = "contoso\user1", "contoso\user2"
            }

            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{}
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1", "contoso\user2" 
                    }
                }
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Configured Members do not match the actual members - ContentDatabase permissions" -Fixture {
            $testParams = @{
                Name         = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name = "SharePoint_Content_Contoso1"
                        Members = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name = "SharePoint_Content_Contoso2"
                        Members = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                )
            }
            
            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{ 
                        UserName = "contoso\user3","contoso\user4" 
                    }
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                }
            }

            Mock -CommandName Get-SPContentDatabase -MockWith {
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

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context -Name "Configured Members match the actual members - ContentDatabase permissions" -Fixture {
            $testParams = @{
                Name         = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name = "SharePoint_Content_Contoso1"
                        Members = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name = "SharePoint_Content_Contoso2"
                        Members = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                }
            }

            Mock -CommandName Get-SPContentDatabase -MockWith {
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

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Configured MembersToInclude do not match the actual members - General permissions" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                MembersToInclude = "contoso\user1", "contoso\user2"
            }

            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{}
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user3","contoso\user4" 
                    }
                }
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
            }
        }

        Context -Name "Configured MembersToInclude match the actual members - General permissions" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                MembersToInclude = "contoso\user1", "contoso\user2"
            }

            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{}
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1", "contoso\user2", "contoso\user3" 
                    }
                }
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Configured MembersToInclude do not match the actual members - ContentDatabase permissions" -Fixture {
            $testParams = @{
                Name         = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name             = "SharePoint_Content_Contoso1"
                        MembersToInclude = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
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
                        UserName = "contoso\user3","contoso\user4" 
                    }
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                }
            }

            Mock -CommandName Get-SPContentDatabase -MockWith {
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
            
            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
            }
        }

        Context -Name "Configured MembersToInclude match the actual members - ContentDatabase permissions" -Fixture {
            $testParams = @{
                Name         = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name             = "SharePoint_Content_Contoso1"
                        MembersToInclude = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
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
                        UserName = "contoso\user1","contoso\user2", "contoso\user3" 
                    }
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                }
            }

            Mock -CommandName Get-SPContentDatabase -MockWith {
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

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Configured MembersToExclude do not match the actual members - General permissions" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                MembersToExclude = "contoso\user1", "contoso\user2"
            }

            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{}
                }
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                }
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context -Name "Configured MembersToExclude match the actual members - General permissions" -Fixture {
            $testParams = @{
                Name             = "ShellAdmins"
                MembersToExclude = "contoso\user1", "contoso\user2"
            }

            Mock -CommandName Get-SPShellAdmin -MockWith {
                if ($database) 
                {
                    # Database parameter used, return database permissions
                    return @{}
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user3", "contoso\user4" 
                    }
                }
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Configured MembersToExclude do not match the actual members - ContentDatabase permissions" -Fixture {
            $testParams = @{
                Name         = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name             = "SharePoint_Content_Contoso1"
                        MembersToExclude = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
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
                        UserName = "contoso\user1","contoso\user2" 
                    }
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                }
            }

            Mock -CommandName Get-SPContentDatabase -MockWith {
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

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context -Name "Configured MembersToExclude match the actual members - ContentDatabase permissions" -Fixture {
            $testParams = @{
                Name         = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name             = "SharePoint_Content_Contoso1"
                        MembersToExclude = "contoso\user3", "contoso\user4"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
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
                        UserName = "contoso\user1","contoso\user2" 
                    }
                } 
                else 
                {
                    # Database parameter not used, return general permissions
                    return @{ 
                        UserName = "contoso\user1","contoso\user2" 
                    }
                }
            }

            Mock -CommandName Get-SPContentDatabase -MockWith {
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

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
