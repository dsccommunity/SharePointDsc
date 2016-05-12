[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPShellAdmins"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPShellAdmins - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name         = "ShellAdmins"
            Members      = "contoso\user1", "contoso\user2"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")

        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Context "The server is not part of SharePoint farm" {
            Mock Get-SPFarm { throw "Unable to detect local farm" }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Context "Members and MembersToInclude parameters used simultaniously - General permissions" {
            $testParams = @{
                Name             = "ShellAdmins"
                Members          = "contoso\user1", "contoso\user2"
                MembersToInclude = "contoso\user1", "contoso\user2"
            }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
            }
        }

        Context "None of the Members, MembersToInclude and MembersToExclude parameters are used - General permissions" {
            $testParams = @{
                Name             = "ShellAdmins"
            }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
            }
        }

        Context "Members and MembersToInclude parameters used simultaniously - ContentDatabase permissions" {
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

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "ContentDatabases: Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
            }
        }

        Context "None of the Members, MembersToInclude and MembersToExclude parameters are used - ContentDatabase permissions" {
            $testParams = @{
                Name             = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name = "SharePoint_Content_Contoso1"
                    } -ClientOnly)
                )
            }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "ContentDatabases: At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
            }
        }

        Context "Specified content database does not exist - ContentDatabase permissions" {
            $testParams = @{
                Name             = "ShellAdmins"
                ContentDatabases = @(
                    (New-CimInstance -ClassName MSFT_SPContentDatabasePermissions -Property @{
                        Name    = "SharePoint_Content_Contoso3"
                        Members = "contoso\user1", "contoso\user2"
                    } -ClientOnly)
                )
            }
            Mock Get-SPContentDatabase {
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
            It "return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                { Test-TargetResource @testParams } | Should throw "Specified database does not exist"
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Specified database does not exist"
            }
        }

        Context "AllContentDatabases parameter is used and permissions do not match" {
            $testParams = @{
                Name             = "ShellAdmins"
                Members          = "contoso\user1", "contoso\user2"
                AllContentDatabases = $true
            }
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{ UserName = "contoso\user3","contoso\user4" }
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                }
            }
            Mock Get-SPContentDatabase {
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
            Mock Add-SPShellAdmin {}
            Mock Remove-SPShellAdmin {}

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context "AllContentDatabases parameter is used and permissions do not match" {
            $testParams = @{
                Name             = "ShellAdmins"
                Members          = "contoso\user1", "contoso\user2"
                AllContentDatabases = $true
            }
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                }
            }
            Mock Get-SPContentDatabase {
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

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Configured Members do not match the actual members - General permissions" {
            $testParams = @{
                Name         = "ShellAdmins"
                Members      = "contoso\user1", "contoso\user2"
            }
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{}
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user3","contoso\user4" }
                }
            }
            Mock Add-SPShellAdmin {}
            Mock Remove-SPShellAdmin {}

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context "Configured Members match the actual members - General permissions" {
            $testParams = @{
                Name         = "ShellAdmins"
                Members      = "contoso\user1", "contoso\user2"
            }
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{}
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1", "contoso\user2" }
                }
            }

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Configured Members do not match the actual members - ContentDatabase permissions" {
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
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{ UserName = "contoso\user3","contoso\user4" }
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                }
            }
            Mock Get-SPContentDatabase {
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
            Mock Add-SPShellAdmin {}
            Mock Remove-SPShellAdmin {}

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context "Configured Members match the actual members - ContentDatabase permissions" {
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
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                }
            }
            Mock Get-SPContentDatabase {
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

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Configured MembersToInclude do not match the actual members - General permissions" {
            $testParams = @{
                Name             = "ShellAdmins"
                MembersToInclude = "contoso\user1", "contoso\user2"
            }
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{}
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user3","contoso\user4" }
                }
            }

            Mock Add-SPShellAdmin {}

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
            }
        }

        Context "Configured MembersToInclude match the actual members - General permissions" {
            $testParams = @{
                Name             = "ShellAdmins"
                MembersToInclude = "contoso\user1", "contoso\user2"
            }
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{}
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1", "contoso\user2", "contoso\user3" }
                }
            }

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Configured MembersToInclude do not match the actual members - ContentDatabase permissions" {
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
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{ UserName = "contoso\user3","contoso\user4" }
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                }
            }
            Mock Get-SPContentDatabase {
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
            Mock Add-SPShellAdmin {}

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-SPShellAdmin
            }
        }

        Context "Configured MembersToInclude match the actual members - ContentDatabase permissions" {
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
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{ UserName = "contoso\user1","contoso\user2", "contoso\user3" }
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                }
            }
            Mock Get-SPContentDatabase {
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

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Configured MembersToExclude do not match the actual members - General permissions" {
            $testParams = @{
                Name             = "ShellAdmins"
                MembersToExclude = "contoso\user1", "contoso\user2"
            }
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{}
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                }
            }
            Mock Remove-SPShellAdmin {}

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context "Configured MembersToExclude match the actual members - General permissions" {
            $testParams = @{
                Name             = "ShellAdmins"
                MembersToExclude = "contoso\user1", "contoso\user2"
            }
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{}
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user3", "contoso\user4" }
                }
            }

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Configured MembersToExclude do not match the actual members - ContentDatabase permissions" {
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
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                }
            }
            Mock Get-SPContentDatabase {
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
            Mock Remove-SPShellAdmin {}

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPShellAdmin
            }
        }

        Context "Configured MembersToExclude match the actual members - ContentDatabase permissions" {
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
            Mock Get-SPShellAdmin {
                if ($database) {
                    # Database parameter used, return database permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                } else {
                    # Database parameter not used, return general permissions
                    return @{ UserName = "contoso\user1","contoso\user2" }
                }
            }
            Mock Get-SPContentDatabase {
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

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}
