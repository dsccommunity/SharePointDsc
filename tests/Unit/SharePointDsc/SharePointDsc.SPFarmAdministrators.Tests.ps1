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
$script:DSCResourceName = 'SPFarmAdministrators'
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
            Context -Name "No central admin site exists" {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = @("Demo\User1", "Demo\User2")
                    }

                    Mock -CommandName Get-SPwebapplication -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Members | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Unable to locate central administration website"
                }
            }

            Context -Name "Central admin exists and a fixed members list is used which matches" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = @("Demo\User1", "Demo\User2")
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            IsAdministrationWebApplication = $true
                            Url                            = "http://admin.shareopoint.contoso.local"
                        }
                    }
                    Mock -CommandName Get-SPWeb -MockWith {
                        return @{
                            AssociatedOwnerGroup = "Farm Administrators"
                            SiteGroups           = New-Object -TypeName "Object" |
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
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 2
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Central admin exists and a fixed members list is used which does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = @("Demo\User1", "Demo\User2")
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            IsAdministrationWebApplication = $true
                            Url                            = "http://admin.shareopoint.contoso.local"
                        }
                    }

                    Mock -CommandName Get-SPWeb -MockWith {
                        $web = @{
                            AssociatedOwnerGroup = "Farm Administrators"
                            SiteGroups           = New-Object -TypeName "Object" |
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
                        return @{ }
                    }
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the members list" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "Central admin exists and a members to include is set where the members are in the group" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        MembersToInclude = @("Demo\User2")
                    }

                    Mock -CommandName Get-SPwebapplication -MockWith {
                        return @{
                            IsAdministrationWebApplication = $true
                            Url                            = "http://admin.shareopoint.contoso.local"
                        }
                    }

                    Mock -CommandName Get-SPWeb -MockWith {
                        return @{
                            AssociatedOwnerGroup = "Farm Administrators"
                            SiteGroups           = New-Object -TypeName "Object" |
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
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 2
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Central admin exists and a members to include is set where the members are not in the group" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        MembersToInclude = @("Demo\User2")
                    }

                    Mock -CommandName Get-SPwebapplication -MockWith {
                        return @{
                            IsAdministrationWebApplication = $true
                            Url                            = "http://admin.shareopoint.contoso.local"
                        }
                    }

                    Mock -CommandName Get-SPWeb -MockWith {
                        return @{
                            AssociatedOwnerGroup = "Farm Administrators"
                            SiteGroups           = New-Object -TypeName "Object" |
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
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the members list" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "Central admin exists and a members to exclude is set where the members are in the group" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        MembersToExclude = @("Demo\User1")
                    }

                    Mock -CommandName Get-SPwebapplication -MockWith {
                        return @{
                            IsAdministrationWebApplication = $true
                            Url                            = "http://admin.shareopoint.contoso.local"
                        }
                    }

                    Mock -CommandName Get-SPWeb -MockWith {
                        return @{
                            AssociatedOwnerGroup = "Farm Administrators"
                            SiteGroups           = New-Object -TypeName "Object" |
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
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 2
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the members list" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "Central admin exists and a members to exclude is set where the members are not in the group" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        MembersToExclude = @("Demo\User1")
                    }

                    Mock -CommandName Get-SPwebapplication -MockWith { return @{
                            IsAdministrationWebApplication = $true
                            Url                            = "http://admin.shareopoint.contoso.local"
                        } }
                    Mock -CommandName Get-SPWeb -MockWith {
                        return @{
                            AssociatedOwnerGroup = "Farm Administrators"
                            SiteGroups           = New-Object -TypeName "Object" |
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
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The resource is called with both an explicit members list as well as members to include/exclude" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Members          = @("Demo\User1")
                        MembersToExclude = @("Demo\User1")
                    }

                    Mock -CommandName Get-SPwebapplication -MockWith {
                        return @{
                            IsAdministrationWebApplication = $true
                            Url                            = "http://admin.shareopoint.contoso.local"
                        }
                    }

                    Mock -CommandName Get-SPWeb -MockWith {
                        return @{
                            AssociatedOwnerGroup = "Farm Administrators"
                            SiteGroups           = New-Object -TypeName "Object" |
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
                }

                It "Should throw in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw
                }

                It "Should throw in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw
                }

                It "Should throw in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "The resource is called without either the specific members list or the include/exclude lists" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                    }

                    Mock -CommandName Get-SPwebapplication -MockWith {
                        return @{
                            IsAdministrationWebApplication = $true
                            Url                            = "http://admin.sharepoint.contoso.local"
                        }
                    }

                    Mock -CommandName Get-SPWeb -MockWith {
                        return @{
                            AssociatedOwnerGroup = "Farm Administrators"
                            SiteGroups           = New-Object -TypeName "Object" |
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
                }

                It "Should throw in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw
                }

                It "Should throw in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw
                }

                It "Should throw in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            IsSingleInstance = "Yes"
                            Members          = @("domain\account", "domain\account2")
                            MembersToInclude = @()
                            MembersToExclude = @()
                        }
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPFarmAdministrators [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            IsSingleInstance     = "Yes";
            Members              = \@\("domain\\account", "domain\\account2"\);
            PsDscRunAsCredential = \$Credsspfarm;
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")
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
