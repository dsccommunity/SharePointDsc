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
                                              -DscResource "SPFarmAdministrators"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Test contexts
        Context -Name "No central admin site exists" {
            $testParams = @{
                Name = "Farm Administrators"
                Members = @("Demo\User1", "Demo\User2")
            }

            Mock -CommandName Get-SPwebapplication -MockWith { return $null }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Unable to locate central administration website"
            }
        }

        Context -Name "Central admin exists and a fixed members list is used which matches" -Fixture {
            $testParams = @{
                Name = "Farm Administrators"
                Members = @("Demo\User1", "Demo\User2")
            }
            
            Mock -CommandName Get-SPwebapplication -MockWith { 
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }
            }
            Mock -CommandName Get-SPWeb -MockWith {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object -TypeName "Object" | 
                                    Add-Member -MemberType ScriptMethod `
                                               -Name GetByName `
                                               -Value {
                                                    return @{
                                                        Users = @(
                                                            @{ UserLogin = "Demo\User1" },
                                                            @{ UserLogin = "Demo\User2" }
                                                        )
                                                    }
                                                } -PassThru
                }
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Central admin exists and a fixed members list is used which does not match" -Fixture {
            $testParams = @{
                Name = "Farm Administrators"
                Members = @("Demo\User1", "Demo\User2")
            }
            
            Mock -CommandName Get-SPwebapplication -MockWith { 
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }
            }
            
            Mock -CommandName Get-SPWeb -MockWith {
                $web =  @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object -TypeName "Object" | 
                                    Add-Member -MemberType ScriptMethod `
                                               -Name GetByName `
                                               -Value {
                                                    return New-Object -TypeName "Object" | 
                                                        Add-Member -MemberType ScriptProperty `
                                                                   -Name Users `
                                                                   -Value {
                                                                        return @(
                                                                            @{
                                                                                UserLogin = "Demo\User1" 
                                                                            }
                                                                        )                                                 
                                                                    } -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name AddUser `
                                                                   -Value { } `
                                                                   -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name RemoveUser `
                                                                   -Value { } `
                                                                   -PassThru
                                                    } -PassThru
                }
                return $web
            }

            Mock -CommandName Get-SPUser -MockWith { 
                return @{} 
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the members list" {
                Set-TargetResource @testParams 
            }
        }
        
        Context -Name "Central admin exists and a members to include is set where the members are in the group" -Fixture {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToInclude = @("Demo\User2")
            }

            Mock -CommandName Get-SPwebapplication -MockWith { 
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }
            }
            
            Mock -CommandName Get-SPWeb -MockWith {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object -TypeName "Object" | 
                                    Add-Member -MemberType ScriptMethod `
                                               -Name GetByName `
                                               -Value {
                                                    return New-Object "Object" | 
                                                        Add-Member -MemberType ScriptProperty `
                                                                   -Name Users `
                                                                   -Value {
                                                                        return @(
                                                                            @{
                                                                                UserLogin = "Demo\User1" 
                                                                            },
                                                                            @{
                                                                                UserLogin = "Demo\User2" 
                                                                            }
                                                                        )                                                 
                                                                    } -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name AddUser `
                                                                   -Value { } `
                                                                   -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name RemoveUser `
                                                                   -Value { } `
                                                                   -PassThru
                                                    } -PassThru
                }
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Central admin exists and a members to include is set where the members are not in the group" -Fixture {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToInclude = @("Demo\User2")
            }

            Mock -CommandName Get-SPwebapplication -MockWith { 
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }
            }

            Mock -CommandName Get-SPWeb -MockWith {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object -TypeName "Object" | 
                                    Add-Member -MemberType ScriptMethod `
                                               -Name GetByName `
                                               -Value {
                                                    return New-Object "Object" | 
                                                        Add-Member -MemberType ScriptProperty `
                                                                   -Name Users `
                                                                   -Value {
                                                                        return @(
                                                                            @{
                                                                                UserLogin = "Demo\User1" 
                                                                            }
                                                                        )                                                 
                                                                    } -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name AddUser `
                                                                   -Value { } `
                                                                   -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name RemoveUser `
                                                                   -Value { } `
                                                                   -PassThru
                                                    } -PassThru
                }
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should update the members list" {
                Set-TargetResource @testParams 
            }
        }

        Context -Name "Central admin exists and a members to exclude is set where the members are in the group" -Fixture {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToExclude = @("Demo\User1")
            }

            Mock -CommandName Get-SPwebapplication -MockWith { 
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }
            }
            
            Mock -CommandName Get-SPWeb -MockWith {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object -TypeName "Object" | 
                                    Add-Member -MemberType ScriptMethod `
                                               -Name GetByName `
                                               -Value {
                                                    return New-Object "Object" | 
                                                        Add-Member -MemberType ScriptProperty `
                                                                   -Name Users `
                                                                   -Value {
                                                                        return @(
                                                                            @{
                                                                                UserLogin = "Demo\User1" 
                                                                            },
                                                                            @{
                                                                                UserLogin = "Demo\User2"
                                                                            }
                                                                        )                                                 
                                                                    } -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name AddUser `
                                                                   -Value { } `
                                                                   -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name RemoveUser `
                                                                   -Value { } `
                                                                   -PassThru
                                                    } -PassThru
                }
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the members list" {
                Set-TargetResource @testParams 
            }
        }

        Context -Name "Central admin exists and a members to exclude is set where the members are not in the group" -Fixture {
            $testParams = @{
                Name = "Farm Administrators"
                MembersToExclude = @("Demo\User1")
            }

            Mock -CommandName Get-SPwebapplication -MockWith { return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }}
            Mock -CommandName Get-SPWeb -MockWith {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object -TypeName "Object" | 
                                    Add-Member -MemberType ScriptMethod `
                                               -Name GetByName `
                                               -Value {
                                                    return New-Object "Object" | 
                                                        Add-Member -MemberType ScriptProperty `
                                                                   -Name Users `
                                                                   -Value {
                                                                        return @(
                                                                            @{
                                                                                UserLogin = "Demo\User2" 
                                                                            }
                                                                        )                                                 
                                                                    } -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name AddUser `
                                                                   -Value { } `
                                                                   -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name RemoveUser `
                                                                   -Value { } `
                                                                   -PassThru
                                                    } -PassThru
                }
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The resource is called with both an explicit members list as well as members to include/exclude" -Fixture {
            $testParams = @{
                Name = "Farm Administrators"
                Members = @("Demo\User1")
                MembersToExclude = @("Demo\User1")
            }

            Mock -CommandName Get-SPwebapplication -MockWith { 
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }
            }
            
            Mock -CommandName Get-SPWeb -MockWith {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object -TypeName "Object" | 
                                    Add-Member -MemberType ScriptMethod `
                                               -Name GetByName `
                                               -Value {
                                                    return New-Object "Object" | 
                                                        Add-Member -MemberType ScriptProperty `
                                                                   -Name Users `
                                                                   -Value {
                                                                        return @(
                                                                            @{
                                                                                UserLogin = "Demo\User2" 
                                                                            }
                                                                        )                                                 
                                                                    } -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name AddUser `
                                                                   -Value { } `
                                                                   -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name RemoveUser `
                                                                   -Value { } `
                                                                   -PassThru
                                                    } -PassThru
                }
            }

            It "Should throw in the get method" {
                { Get-TargetResource @testParams } | Should throw 
            }

            It "Should throw in the test method" {
                { Test-TargetResource @testParams } | Should throw
            }

            It "Should throw in the set method" {
                { Set-TargetResource @testParams } | Should throw
            }
        }

        Context -Name "The resource is called without either the specific members list or the include/exclude lists" -Fixture {
            $testParams = @{
                Name = "Farm Administrators"
            }

            Mock -CommandName Get-SPwebapplication -MockWith { 
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://admin.shareopoint.contoso.local"
                }
            }
            
            Mock -CommandName Get-SPWeb -MockWith {
                return @{
                    AssociatedOwnerGroup = "Farm Administrators"
                    SiteGroups = New-Object -TypeName "Object" | 
                                    Add-Member -MemberType ScriptMethod `
                                               -Name GetByName `
                                               -Value {
                                                    return New-Object "Object" | 
                                                        Add-Member -MemberType ScriptProperty `
                                                                   -Name Users `
                                                                   -Value {
                                                                        return @(
                                                                            @{
                                                                                UserLogin = "Demo\User2" 
                                                                            }
                                                                        )                                                 
                                                                    } -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name AddUser `
                                                                   -Value { } `
                                                                   -PassThru | 
                                                        Add-Member -MemberType ScriptMethod `
                                                                   -Name RemoveUser `
                                                                   -Value { } `
                                                                   -PassThru
                                                    } -PassThru
                }
            }

            It "Should throw in the get method" {
                { Get-TargetResource @testParams } | Should throw 
            }

            It "Should throw in the test method" {
                { Test-TargetResource @testParams } | Should throw
            }

            It "Should throw in the set method" {
                { Set-TargetResource @testParams } | Should throw
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
