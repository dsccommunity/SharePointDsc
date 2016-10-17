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
                                              -DscResource "SPUserProfileServiceAppPermissions"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

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
        Mock -CommandName Test-SPDSCIsADUser -MockWith { return $true }
        Mock -CommandName Write-Warning -MockWith { }

        Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
            return @(
                @{
                    DisplayName = $testParams.ProxyName
                }
            )
        }

        # Test contexts
        Context -Name "The proxy does not exist" -Fixture {
            $testParams = @{
                ProxyName = "User Profile Service App Proxy"
                CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                FollowAndEditProfile = @("Everyone")
                UseTagsAndNotes      = @("None")
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                return @()
            }

            It "Should return null values from the get method" {
                $results = Get-TargetResource @testParams
                $results.CreatePersonalSite | Should BeNullOrEmpty
                $results.FollowAndEditProfile | Should BeNullOrEmpty
                $results.UseTagsAndNotes | Should BeNullOrEmpty
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context -Name "Users who should have access do not have access" -Fixture {
            $testParams = @{
                ProxyName = "User Profile Service App Proxy"
                CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                FollowAndEditProfile = @("Everyone")
                UseTagsAndNotes      = @("None")
            }

            Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                return @{
                    AccessRules = @()
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPProfileServiceApplicationSecurity
            }
        }

        Context -Name "Users who should have access have incorrect permissions" -Fixture {
            $testParams = @{
                ProxyName = "User Profile Service App Proxy"
                CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                FollowAndEditProfile = @("Everyone")
                UseTagsAndNotes      = @("None")
            }

            Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                return @{
                    AccessRules = @(
                        @{
                            Name = "i:0#.w|DEMO\User2"
                            AllowedRights = "UsePersonalFeatures"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User1"
                            AllowedRights = "UsePersonalFeatures"
                        },
                        @{
                            Name = "c:0(.s|true"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        }
                    )
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPProfileServiceApplicationSecurity
            }
        }

        Context -Name "Users who should have permissions have the correct permissions" -Fixture {
            $testParams = @{
                ProxyName = "User Profile Service App Proxy"
                CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                FollowAndEditProfile = @("Everyone")
                UseTagsAndNotes      = @("None")
            }

            Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                return @{
                    AccessRules = @(
                        @{
                            Name = "i:0#.w|DEMO\User2"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User1"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "c:0(.s|true"
                            AllowedRights = "UsePersonalFeatures"
                        }
                    )
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return true in the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Users who should not have access have permissions assigned" -Fixture {
            $testParams = @{
                ProxyName = "User Profile Service App Proxy"
                CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                FollowAndEditProfile = @("Everyone")
                UseTagsAndNotes      = @("None")
            }

            Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                return @{
                    AccessRules = @(
                        @{
                            Name = "i:0#.w|DEMO\User2"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User1"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User3"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "c:0(.s|true"
                            AllowedRights = "UsePersonalFeatures"
                        }
                    )
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPProfileServiceApplicationSecurity
            }
        }

        Context -Name "The old non-claims 'Authenticated Users' entry exists in the permissions" -Fixture {
            $testParams = @{
                ProxyName = "User Profile Service App Proxy"
                CreatePersonalSite   = @("DEMO\User2", "DEMO\User1")
                FollowAndEditProfile = @("Everyone")
                UseTagsAndNotes      = @("None")
            }

            Mock -CommandName Get-SPProfileServiceApplicationSecurity -MockWith {
                return @{
                    AccessRules = @(
                        @{
                            Name = "i:0#.w|DEMO\User2"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "i:0#.w|DEMO\User1"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "NT Authority\Authenticated Users"
                            AllowedRights = "CreatePersonalSite,UseMicrobloggingAndFollowing"
                        },
                        @{
                            Name = "c:0(.s|true"
                            AllowedRights = "UsePersonalFeatures"
                        }
                    )
                }
            }

            It "Should return the current permissions correctly" {
                Get-TargetResource @testParams
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should set the permissions correctly" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPProfileServiceApplicationSecurity
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
