[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPFarmAdministrators"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPFarmAdministrators" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Farm Administrators"
            Members = @("Demo\User1", "Demo\User2")
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")

        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue


        Context "No central admin site exists" {
            Mock Get-SPwebapplication { return $null }

            It "should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Unable to locate central administration website"
            }
        }

        Context "Central admin exists and a fixed members list is used which matches" {
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                }}
            Mock Get-SPWeb {
                $web = @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = @{
                        "Farm Administrators" = @{
                            Users = @(
                                @{ UserLogin = "Demo\User1" },
                                @{ UserLogin = "Demo\User2" }
                            )
                        }
                    }
                }
                return $web
            }

            It "should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Central admin exists and a fixed members list is used which does not match" {
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                }}
            Mock Get-SPWeb {
                $web = @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = @{
                        "Farm Administrators" = @{
                            Users = @(
                                @{ UserLogin = "Demo\User1" }
                            )
                        }
                    }
                }
                return $web
            }

            It "should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }
        
        Context "Central admin exists and a members to include is set where the members are in the group" {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToInclude = @("Demo\User2")
            }
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                }}
            Mock Get-SPWeb {
                $web = @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = @{
                        "Farm Administrators" = @{
                            Users = @(
                                @{ UserLogin = "Demo\User1" },
                                @{ UserLogin = "Demo\User2" }
                            )
                        }
                    }
                }
                return $web
            }

            It "should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Central admin exists and a members to include is set where the members are not in the group" {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToInclude = @("Demo\User2")
            }
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                }}
            Mock Get-SPWeb {
                $web = @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = @{
                        "Farm Administrators" = @{
                            Users = @(
                                @{ UserLogin = "Demo\User1" }
                            )
                        }
                    }
                }
                return $web
            }

            It "should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Central admin exists and a members to exclude is set where the members are in the group" {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToExclude = @("Demo\User1")
            }
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                }}
            Mock Get-SPWeb {
                $web = @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = @{
                        "Farm Administrators" = @{
                            Users = @(
                                @{ UserLogin = "Demo\User1" },
                                @{ UserLogin = "Demo\User2" }
                            )
                        }
                    }
                }
                return $web
            }

            It "should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Central admin exists and a members to exclude is set where the members are not in the group" {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToExclude = @("Demo\User1")
            }
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                }}
            Mock Get-SPWeb {
                $web = @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = @{
                        "Farm Administrators" = @{
                            Users = @(
                                @{ UserLogin = "Demo\User2" }
                            )
                        }
                    }
                }
                return $web
            }

            It "should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The resource is called with both an explicit members list as well as members to include/exclude" {
            $testParams = @{
                Name = "Farm Administrators"
                Members = @("Demo\User1")
                MembersToExclude = @("Demo\User1")
            }
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                }}
            Mock Get-SPWeb {
                $web = @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = @{
                        "Farm Administrators" = @{
                            Users = @(
                                @{ UserLogin = "Demo\User2" }
                            )
                        }
                    }
                }
                return $web
            }

            It "should throw in the get method" {
                { Get-TargetResource @testParams } | Should throw 
            }

            It "should throw in the test method" {
                { Test-TargetResource @testParams } | Should throw
            }

            It "should throw in the set method" {
                { Set-TargetResource @testParams } | Should throw
            }
        }

        Context "The resource is called without either the specific members list or the include/exclude lists" {
            $testParams = @{
                Name = "Farm Administrators"
            }
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                }}
            Mock Get-SPWeb {
                $web = @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = @{
                        "Farm Administrators" = @{
                            Users = @(
                                @{ UserLogin = "Demo\User2" }
                            )
                        }
                    }
                }
                return $web
            }

            It "should throw in the get method" {
                { Get-TargetResource @testParams } | Should throw 
            }

            It "should throw in the test method" {
                { Test-TargetResource @testParams } | Should throw
            }

            It "should throw in the set method" {
                { Set-TargetResource @testParams } | Should throw
            }
        }
    }
}
