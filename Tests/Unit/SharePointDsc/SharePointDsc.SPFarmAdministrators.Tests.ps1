[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPFarmAdministrators"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPFarmAdministrators - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Farm Administrators"
            Members = @("Demo\User1", "Demo\User2")
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")

        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
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
                    Url = "http://admin.shareopoint.contoso.local"
                }}
            Mock Get-SPWeb {
                $web = @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object Object | Add-Member ScriptMethod GetByName {
                        return @{
                            Users = @(
                                @{ UserLogin = "Demo\User1" },
                                @{ UserLogin = "Demo\User2" }
                            )
                        }
                    } -PassThru
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
                    Url = "http://admin.shareopoint.contoso.local"
                }}
            Mock Get-SPWeb {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object Object | Add-Member ScriptMethod GetByName {
                        return New-Object  Object | Add-Member ScriptProperty Users {
                            return @(
                                @{ UserLogin = "Demo\User1" }
                            )
                        } -PassThru | Add-Member ScriptMethod AddUser { } -PassThru `
                                    | Add-Member ScriptMethod RemoveUser { } -PassThru
                    } -PassThru
                }
            }
            Mock Get-SPUser { return @{} }

            It "should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should update the members list" {
                Set-TargetResource @testParams 
            }
        }
        
        Context "Central admin exists and a members to include is set where the members are in the group" {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToInclude = @("Demo\User2")
            }
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }}
            Mock Get-SPWeb {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object Object | Add-Member ScriptMethod GetByName {
                        return New-Object  Object | Add-Member ScriptProperty Users {
                            return @(
                                @{ UserLogin = "Demo\User1" },
                                @{ UserLogin = "Demo\User2" }
                            )
                        } -PassThru | Add-Member ScriptMethod AddUser { } -PassThru `
                                    | Add-Member ScriptMethod RemoveUser { } -PassThru
                    } -PassThru
                }
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
                    Url = "http://admin.shareopoint.contoso.local"
                }}
            Mock Get-SPWeb {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object Object | Add-Member ScriptMethod GetByName {
                        return New-Object  Object | Add-Member ScriptProperty Users {
                            return @(
                                @{ UserLogin = "Demo\User1" }
                            )
                        } -PassThru | Add-Member ScriptMethod AddUser { } -PassThru `
                                    | Add-Member ScriptMethod RemoveUser { } -PassThru
                    } -PassThru
                }
            }

            It "should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should update the members list" {
                Set-TargetResource @testParams 
            }
        }

        Context "Central admin exists and a members to exclude is set where the members are in the group" {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToExclude = @("Demo\User1")
            }
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }}
            Mock Get-SPWeb {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object Object | Add-Member ScriptMethod GetByName {
                        return New-Object  Object | Add-Member ScriptProperty Users {
                            return @(
                                @{ UserLogin = "Demo\User1" },
                                @{ UserLogin = "Demo\User2" }
                            )
                        } -PassThru | Add-Member ScriptMethod AddUser { } -PassThru `
                                    | Add-Member ScriptMethod RemoveUser { } -PassThru
                    } -PassThru
                }
            }

            It "should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should update the members list" {
                Set-TargetResource @testParams 
            }
        }

        Context "Central admin exists and a members to exclude is set where the members are not in the group" {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToExclude = @("Demo\User1")
            }
            Mock Get-SPwebapplication { return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }}
            Mock Get-SPWeb {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object Object | Add-Member ScriptMethod GetByName {
                        return New-Object  Object | Add-Member ScriptProperty Users {
                            return @(
                                @{ UserLogin = "Demo\User2" }
                            )
                        } -PassThru | Add-Member ScriptMethod AddUser { } -PassThru `
                                    | Add-Member ScriptMethod RemoveUser { } -PassThru
                    } -PassThru
                }
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
                    Url = "http://admin.shareopoint.contoso.local"
                }}
            Mock Get-SPWeb {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object Object | Add-Member ScriptMethod GetByName {
                        return New-Object  Object | Add-Member ScriptProperty Users {
                            return @(
                                @{ UserLogin = "Demo\User2" }
                            )
                        } -PassThru | Add-Member ScriptMethod AddUser { } -PassThru `
                                    | Add-Member ScriptMethod RemoveUser { } -PassThru
                    } -PassThru
                }
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
                    Url = "http://admin.shareopoint.contoso.local"
                }}
            Mock Get-SPWeb {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object Object | Add-Member ScriptMethod GetByName {
                        return New-Object  Object | Add-Member ScriptProperty Users {
                            return @(
                                @{ UserLogin = "Demo\User2" }
                            )
                        } -PassThru | Add-Member ScriptMethod AddUser { } -PassThru `
                                    | Add-Member ScriptMethod RemoveUser { } -PassThru
                    } -PassThru
                }
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
