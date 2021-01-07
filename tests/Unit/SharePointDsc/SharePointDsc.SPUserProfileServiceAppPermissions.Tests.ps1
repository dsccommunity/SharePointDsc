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
$script:DSCResourceName = 'SPUserProfileServiceAppPermissions'
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

                # Mocks for all contexts
                Mock -CommandName New-SPClaimsPrincipal -MockWith {
                    return @{
                        Value = $Identity -replace "i:0#.w\|"
                    }
                } -ParameterFilter { $IdentityType -eq "EncodedClaim" }

                Mock -CommandName New-SPClaimsPrincipal -MockWith {
                    $Global:SPDscClaimsPrincipalUser = $Identity
                    return (
                        New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod ToEncodedString {
                            return "i:0#.w|$($Global:SPDscClaimsPrincipalUser)"
                        } -PassThru
                    )
                } -ParameterFilter { $IdentityType -eq "WindowsSamAccountName" }

                Mock Grant-SPObjectSecurity -MockWith { }
                Mock Revoke-SPObjectSecurity -MockWith { }
                Mock -CommandName Set-SPProfileServiceApplicationSecurity -MockWith { }

                Mock -CommandName Start-Sleep -MockWith { }
                Mock -CommandName Test-SPDscIsADUser -MockWith { return $true }
                Mock -CommandName Write-Warning -MockWith { }

                Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                    return @(
                        @{
                            DisplayName = $testParams.ProxyName
                        }
                    )
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
            Context -Name "The proxy does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ProxyName            = "User Profile Service App Proxy"
                        CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                        FollowAndEditProfile = @("Everyone")
                        UseTagsAndNotes      = @("None")
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @()
                    }
                }

                It "Should return null values from the get method" {
                    $results = Get-TargetResource @testParams
                    $results.CreatePersonalSite | Should -BeNullOrEmpty
                    $results.FollowAndEditProfile | Should -BeNullOrEmpty
                    $results.UseTagsAndNotes | Should -BeNullOrEmpty
                }

                It "Should return false in the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the permissions correctly" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "Users who should have access do not have access" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ProxyName            = "User Profile Service App Proxy"
                        CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                        FollowAndEditProfile = @("Everyone")
                        UseTagsAndNotes      = @("None")
                    }

                    Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                        return @{
                            AccessRules = @()
                        }
                    }
                }

                It "Should return the current permissions correctly" {
                    Get-TargetResource @testParams
                }

                It "Should return false in the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the permissions correctly" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPProfileServiceApplicationSecurity
                }
            }

            Context -Name "Users who should have access have incorrect permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ProxyName            = "User Profile Service App Proxy"
                        CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                        FollowAndEditProfile = @("Everyone")
                        UseTagsAndNotes      = @("None")
                    }

                    Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                        return @{
                            AccessRules = @(
                                @{
                                    Name          = "i:0#.w|DEMO\User2"
                                    AllowedRights = "UsePersonalFeatures"
                                },
                                @{
                                    Name          = "i:0#.w|DEMO\User1"
                                    AllowedRights = "UsePersonalFeatures"
                                },
                                @{
                                    Name          = "c:0(.s|true"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                }
                            )
                        }
                    }
                }

                It "Should return the current permissions correctly" {
                    Get-TargetResource @testParams
                }

                It "Should return false in the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the permissions correctly" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPProfileServiceApplicationSecurity
                }
            }

            Context -Name "Users who should have permissions have the correct permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ProxyName            = "User Profile Service App Proxy"
                        CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                        FollowAndEditProfile = @("Everyone")
                        UseTagsAndNotes      = @("None")
                    }

                    Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                        return @{
                            AccessRules = @(
                                @{
                                    Name          = "i:0#.w|DEMO\User2"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "i:0#.w|DEMO\User1"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "c:0(.s|true"
                                    AllowedRights = "UsePersonalFeatures"
                                }
                            )
                        }
                    }
                }

                It "Should return the current permissions correctly" {
                    Get-TargetResource @testParams
                }

                It "Should return true in the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Users who should not have access have permissions assigned" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ProxyName            = "User Profile Service App Proxy"
                        CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                        FollowAndEditProfile = @("Everyone")
                        UseTagsAndNotes      = @("None")
                    }

                    Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                        return @{
                            AccessRules = @(
                                @{
                                    Name          = "i:0#.w|DEMO\User2"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "i:0#.w|DEMO\User1"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "i:0#.w|DEMO\User3"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "c:0(.s|true"
                                    AllowedRights = "UsePersonalFeatures"
                                }
                            )
                        }
                    }
                }

                It "Should return the current permissions correctly" {
                    Get-TargetResource @testParams
                }

                It "Should return false in the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the permissions correctly" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPProfileServiceApplicationSecurity
                }
            }

            Context -Name "The old non-claims 'Authenticated Users' entry exists in the permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ProxyName            = "User Profile Service App Proxy"
                        CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                        FollowAndEditProfile = @("Everyone")
                        UseTagsAndNotes      = @("None")
                    }

                    Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                        return @{
                            AccessRules = @(
                                @{
                                    Name          = "i:0#.w|DEMO\User2"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "i:0#.w|DEMO\User1"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "NT Authority\Authenticated Users"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "c:0(.s|true"
                                    AllowedRights = "UsePersonalFeatures"
                                }
                            )
                        }
                    }
                }

                It "Should return the current permissions correctly" {
                    Get-TargetResource @testParams
                }

                It "Should return false in the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the permissions correctly" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPProfileServiceApplicationSecurity
                }
            }

            Context -Name "Passing empty values for non-mandatory parameters" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ProxyName = "User Profile Service App Proxy"
                    }

                    Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                        return @{
                            AccessRules = @(
                                @{
                                    Name          = "i:0#.w|DEMO\User2"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "i:0#.w|DEMO\User1"
                                    AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                                },
                                @{
                                    Name          = "c:0(.s|true"
                                    AllowedRights = "UsePersonalFeatures"
                                }
                            )
                        }
                    }
                }

                It "Should return the current permissions correctly" {
                    Get-TargetResource @testParams
                }

                It "Should return true in the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ProxyName            = "User Profile Service Application Proxy"
                            CreatePersonalSite   = @("DEMO\Group", "DEMO\User1")
                            FollowAndEditProfile = @("Everyone")
                            UseTagsAndNotes      = @("None")
                        }
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $spServiceAppProxy = [PSCustomObject]@{
                            DisplayName = "User Profile Service Application Proxy"
                            Name        = "User Profile Service Application Proxy"
                        }
                        $spServiceAppProxy = $spServiceAppProxy | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "UserProfileApplicationProxy"
                            }
                        } -PassThru -Force
                        return $spServiceAppProxy
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPUserProfileServiceAppPermissions [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            CreatePersonalSite   = \@\("DEMO\\Group","DEMO\\User1"\);
            FollowAndEditProfile = \@\("Everyone"\);
            ProxyName            = "User Profile Service Application Proxy";
            PsDscRunAsCredential = \$Credsspfarm;
            UseTagsAndNotes      = \@\("None"\);
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
