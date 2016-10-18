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
                                              -DscResource "SPWebAppPolicy"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        try { [Microsoft.SharePoint.Administration.SPPolicyRoleType] }
        catch {
            Add-Type -TypeDefinition @"
namespace Microsoft.SharePoint.Administration {
    public enum SPPolicyRoleType { FullRead, FullControl, DenyWrite, DenyAll };
}        
"@
        }

        # Mocks for all contexts   
        Mock -CommandName Test-SPDSCIsADUser {
            return $true
        }

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

        Mock -CommandName Remove-SPDSCGenericObject { }

        # Test contexts
        Context -Name "The web application doesn't exist" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $true
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user2"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should return null from the set method" {
                { Set-TargetResource @testParams } | Should throw "Web application does not exist"
            }
        }
        
        Context -Name "Members and MembersToInclude parameters used simultaniously" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
            }
        }
        
        Context -Name "No Member parameters at all" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
            }
        }
        
        Context -Name "ActAsSystemAccount parameter specified without Full Control in Members" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $true
                    } -ClientOnly)
                )
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Members Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"
            }
        }

        Context -Name "ActAsSystemAccount parameter specified without Full Control in MembersToInclude" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $true
                    } -ClientOnly)
                )
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "MembersToInclude Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"
            }
        }

        Context -Name "The Members parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "contoso\sp_psu"
                        portalsuperreaderaccount = "contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "add user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The MembersToInclude parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "contoso\sp_psu"
                        portalsuperreaderaccount = "contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "add user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The Members parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the webapp" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                    }
                }
                
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
            }
        }

        Context -Name "The MembersToInclude parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the webapp" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                    }
                }
                
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
            }
        }

        Context -Name "The Members parameter used with SetCacheAccounts to True and the Cache Users users are configured correctly" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindingsFR = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindingsFR = $roleBindingsFR | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $roleBindingsFC = @(
                    @{
                        Name = "Full Control"
                    }
                )
                $roleBindingsFC = $roleBindingsFC | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "i:0#.w|contoso\user1"
                        PolicyRoleBindings = $roleBindingsFR
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "i:0#.w|contoso\sp_psu"
                        PolicyRoleBindings = $roleBindingsFC
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "i:0#.w|contoso\sp_psr"
                        PolicyRoleBindings = $roleBindingsFR
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "i:0#.w|contoso\sp_psu"
                        portalsuperreaderaccount = "i:0#.w|contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The MembersToInclude parameter used with SetCacheAccounts to True and the Cache Users users are configured correctly" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindingsFR = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindingsFR = $roleBindingsFR | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $roleBindingsFC = @(
                    @{
                        Name = "Full Control"
                    }
                )
                $roleBindingsFC = $roleBindingsFC | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "i:0#.w|contoso\user1"
                        PolicyRoleBindings = $roleBindingsFR
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "i:0#.w|contoso\sp_psu"
                        PolicyRoleBindings = $roleBindingsFC
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "i:0#.w|contoso\sp_psr"
                        PolicyRoleBindings = $roleBindingsFR
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "contoso\sp_psu"
                        portalsuperreaderaccount = "contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The MembersToExclude parameter used, but it specifies a Cache User" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToExclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\sp_psr"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindingsFR = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindingsFR = $roleBindingsFR | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $roleBindingsFC = @(
                    @{
                        Name = "Full Control"
                    }
                )
                $roleBindingsFC = $roleBindingsFC | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindingsFR
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\sp_psu"
                        PolicyRoleBindings = $roleBindingsFC
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\sp_psr"
                        PolicyRoleBindings = $roleBindingsFR
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "contoso\sp_psu"
                        portalsuperreaderaccount = "contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should throw "You cannot exclude the Cache accounts from the Web Application Policy"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You cannot exclude the Cache accounts from the Web Application Policy"
            }
        }

        Context -Name "The Members parameter contains users that aren't configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user2"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "add user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The Members parameter does not contains users that are configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "i:0#.w|contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "i:0#.w|contoso\user2"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                ) | Add-Member -MemberType ScriptMethod -Name Add -Value { param($input) return $null } -Force -PassThru
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "remove user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The MembersToInclude parameter contains users that are not configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user2"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "add user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The MembersToInclude parameter contains users that are configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )

                $policies = @(
                    @{
                        UserName = "i:0#.w|contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    },
                    @{
                        UserName = "i:0#.w|contoso\user2"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )

                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }



            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The MembersToExclude parameter contains users that are configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToExclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\user2"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru | 
                Add-Member -MemberType NoteProperty Properties @{} -PassThru
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "remove user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The users in the Members parameter have different settings than configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $Global:SPDscWebAppPolicyAddCalled = $true
                } -PassThru -Force

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "correct user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The users in the MembersToInclude parameter have different settings than configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $Global:SPDscWebAppPolicyAddCalled = $true
                } -PassThru -Force

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "correct user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The users in the Members parameter have different settings than configured in the policy - ActAsSystemAccount" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $true
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $Global:SPDscWebAppPolicyAddCalled = $true
                } -PassThru -Force

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "correct user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The users in the MembersToInclude parameter have different settings than configured in the policy - ActAsSystemAccount" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $true
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                    $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                } -PassThru
                $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $Global:SPDscWebAppPolicyAddCalled = $true
                } -PassThru -Force

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                        return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "correct user policy from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "The users in the Members parameter have the same settings as configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                        IdentityType       = "Native"
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The users in the Members parameter have the same settings as configured in the policy, in Claims format" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                        IdentityType       = "Claims"
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )

                $policies = @(
                    @{
                        UserName = "i:0#.w|contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The users in the MembersToInclude parameter have the same  settings as configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )

                $policies = @(
                    @{
                        UserName = "i:0#.w|contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The users in the MembersToExclude parameter aren't configured in the policy" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                MembersToExclude = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\user2"
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The users in the Members parameter have the same settings as configured in the policy, in Claims format with a windows group in the results" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                        Username           = "contoso\group1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                        IdentityType       = "Claims"
                    } -ClientOnly)
                )
            }
            Mock -CommandName Get-SPWebapplication -MockWith { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )

                $policies = @(
                    @{
                        UserName = "i:0#.w|s-1-5-21-2753725054-2932589700-2007370523-2138"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    UseClaimsAuthentication = $true
                    PolicyRoles = New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }
            Mock Resolve-SPDscSecurityIdentifier {
                return "contoso\group1"
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
