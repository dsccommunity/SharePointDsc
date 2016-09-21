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
                                              -DscResource "SPServiceAppSecurity"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName Test-SPDSCIsADUser -MockWith { return $true }
        
        Mock Grant-SPObjectSecurity -MockWith {}
        Mock Revoke-SPObjectSecurity -MockWith {}
        Mock -CommandName Set-SPServiceApplicationSecurity -MockWith {}

        Mock -CommandName New-SPClaimsPrincipal -MockWith { 
            return @{
                Value = $Identity -replace "i:0#.w\|"
            }
        } -ParameterFilter { $IdentityType -eq "EncodedClaim" }

        Mock -CommandName New-SPClaimsPrincipal -MockWith { 
            $Global:SPDscClaimsPrincipalUser = $Identity
            return (
                New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod `
                                                           -Name ToEncodedString `
                                                           -Value { 
                                                                return "i:0#.w|$($Global:SPDscClaimsPrincipalUser)" 
                                                            } -PassThru
            )
        } -ParameterFilter { $IdentityType -eq "WindowsSamAccountName" }

        # Test contexts
        Context -Name "The service app that security should be applied to does not exist" -Fixture {
            $testParams = @{
                ServiceAppName = "Example Service App"
                SecurityType = "SharingPermissions"
                Members = @(
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                     -ClientOnly `
                                     -Property @{
                                                   Username = "CONTOSO\user1"
                                                   AccessLevel = "Full Control"
                                               }),
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                     -ClientOnly `
                                     -Property @{
                                                   Username = "CONTOSO\user2"
                                                   AccessLevel = "Full Control"
                                               })
                )
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            It "Should return empty members list from the get method" {
                (Get-TargetResource @testParams).Members | Should BeNullOrEmpty
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
        
        Context -Name "None of the required members properties are provided" -Fixture {
            $testParams = @{
                ServiceAppName = "Example Service App"
                SecurityType = "SharingPermissions"
            }
            
            It "Should throw an exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw
            }
            
            It "Should throw an exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
        
        Context -Name "All of the members properties are provided" -Fixture {
            $testParams = @{
                ServiceAppName = "Example Service App"
                SecurityType = "SharingPermissions"
                Members = @(
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                    -ClientOnly `
                                    -Property @{
                                                  Username = "CONTOSO\user1"
                                                  AccessLevel = "Full Control"
                                               })
                )
                MembersToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                    -ClientOnly `
                                    -Property @{
                                                  Username = "CONTOSO\user1"
                                                  AccessLevel = "Full Control"
                                               })
                )
                MembersToExclude = @("CONTOSO\user2")
            }
            
            It "Should throw an exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw
            }
            
            It "Should throw an exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
        
        Context -Name "The service app exists and a fixed members list is provided that does not match the current settings" -Fixture {
            $testParams = @{
                ServiceAppName = "Example Service App"
                SecurityType = "SharingPermissions"
                Members = @(
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                     -ClientOnly `
                                     -Property @{
                                                   Username = "CONTOSO\user1"
                                                   AccessLevel = "Full Control"
                                               }),
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                     -ClientOnly `
                                     -Property @{
                                                   Username = "CONTOSO\user2"
                                                   AccessLevel = "Full Control"
                                               })
                )
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @{} 
            }

            Mock -CommandName Get-SPServiceApplicationSecurity { 
                return @{
                    AccessRules = @(
                        @{
                            Name = "CONTOSO\user1"
                            AllowedRights = "Read"
                        }
                    )
                }
            }
            
            It "Should return a list of current members from the get method" {
                (Get-TargetResource @testParams).Members | Should Not BeNullOrEmpty
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should call the update cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Grant-SPObjectSecurity
                Assert-MockCalled Revoke-SPObjectSecurity
                Assert-MockCalled Set-SPServiceApplicationSecurity
            }
        }
        
        Context -Name "The service app exists and a fixed members list is provided that does match the current settings" -Fixture {
            $testParams = @{
                ServiceAppName = "Example Service App"
                SecurityType = "SharingPermissions"
                Members = @(
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                     -ClientOnly `
                                     -Property @{
                                                   Username = "CONTOSO\user1"
                                                   AccessLevel = "Full Control"
                                               }),
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                     -ClientOnly `
                                     -Property @{
                                                   Username = "CONTOSO\user2"
                                                   AccessLevel = "Full Control"
                                               })
                )
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @{} 
            }
            
            Mock -CommandName Get-SPServiceApplicationSecurity -MockWith { 
                return @{
                    AccessRules = @(
                        @{
                            Name = "CONTOSO\user1"
                            AllowedRights = "FullControl"
                        },
                        @{
                            Name = "CONTOSO\user2"
                            AllowedRights = "FullControl"
                        }
                    )
                }
            }
            
            It "Should return a list of current members from the get method" {
                (Get-TargetResource @testParams).Members | Should Not BeNullOrEmpty
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "The service app exists and a specific list of members to add and remove is provided, which does not match the desired state" -Fixture {
            $testParams = @{
                ServiceAppName = "Example Service App"
                SecurityType = "SharingPermissions"
                MembersToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                     -ClientOnly `
                                     -Property @{
                                                    Username = "CONTOSO\user1"
                                                    AccessLevel = "Full Control"
                                                })
                )
                MembersToExclude = @("CONTOSO\user2")
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @{} 
            }
            
            Mock -CommandName Get-SPServiceApplicationSecurity -MockWith { 
                return @{
                    AccessRules = @(
                        @{
                            Name = "CONTOSO\user2"
                            AllowedRights = "FullControl"
                        }
                    )
                }
            }
            
            It "Should return a list of current members from the get method" {
                (Get-TargetResource @testParams).Members | Should Not BeNullOrEmpty
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should call the update cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Grant-SPObjectSecurity
                Assert-MockCalled Revoke-SPObjectSecurity
                Assert-MockCalled Set-SPServiceApplicationSecurity
            }
        }
        
        Context -Name "The service app exists and a specific list of members to add and remove is provided, which does match the desired state" -Fixture {
            $testParams = @{
                ServiceAppName = "Example Service App"
                SecurityType = "SharingPermissions"
                MembersToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                     -ClientOnly `
                                     -Property @{
                                                    Username = "CONTOSO\user1"
                                                    AccessLevel = "Full Control"
                                                })
                )
                MembersToExclude = @("CONTOSO\user2")
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @{} 
            }
            
            Mock -CommandName Get-SPServiceApplicationSecurity -MockWith { 
                return @{
                    AccessRules = @(
                        @{
                            Name = "CONTOSO\user1"
                            AllowedRights = "FullControl"
                        }
                    )
                }
            }
            
            It "Should return a list of current members from the get method" {
                (Get-TargetResource @testParams).Members | Should Not BeNullOrEmpty
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The service app exists and a specific list of members to add and remove is provided, which does match the desired state and includes a claims based group" -Fixture {
            $testParams = @{
                ServiceAppName = "Example Service App"
                SecurityType = "SharingPermissions"
                MembersToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" `
                                     -ClientOnly `
                                     -Property @{
                                                    Username = "CONTOSO\user1"
                                                    AccessLevel = "Full Control"
                                                })
                )
                MembersToExclude = @("CONTOSO\user2")
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @{} 
            }
            Mock -CommandName Get-SPServiceApplicationSecurity { 
                return @{
                    AccessRules = @(
                        @{
                            Name = "i:0#.w|s-1-5-21-2753725054-2932589700-2007370523-2138"
                            AllowedRights = "FullControl"
                        }
                    )
                }
            }
            
            Mock Resolve-SPDscSecurityIdentifier {
                return "CONTOSO\user1"
            }
            
            It "Should return a list of current members from the get method" {
                (Get-TargetResource @testParams).Members | Should Not BeNullOrEmpty
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
