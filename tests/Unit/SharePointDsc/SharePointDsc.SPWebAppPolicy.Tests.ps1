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
$script:DSCResourceName = 'SPWebAppPolicy'
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
                try
                {
                    [Microsoft.SharePoint.Administration.SPPolicyRoleType]
                }
                catch
                {
                    Add-Type -TypeDefinition @"
        namespace Microsoft.SharePoint.Administration {
            public enum SPPolicyRoleType { FullRead, FullControl, DenyWrite, DenyAll };
        }
"@
                }

                # Mocks for all contexts
                Mock -CommandName Test-SPDscIsADUser {
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

                Mock -CommandName Remove-SPDscGenericObject { }

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
            Context -Name "The web application doesn't exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Members   = @(
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
                }

                It "Should return WebAppUrl=null from the get method" {
                    (Get-TargetResource @testParams).WebAppUrl | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return null from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Web application does not exist"
                }
            }

            Context -Name "Members and MembersToInclude parameters used simultaniously" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Members          = @(
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
                }

                It "Should return WebAppUrl=null from the get method" {
                    (Get-TargetResource @testParams).WebAppUrl | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
                }
            }

            Context -Name "No Member parameters at all" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                    }
                }

                It "Should return WebAppUrl=null from the get method" {
                    (Get-TargetResource @testParams).WebAppUrl | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
                }
            }

            Context -Name "ActAsSystemAccount parameter specified without Full Control in Members" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Members   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    ActAsSystemAccount = $true
                                } -ClientOnly)
                        )
                    }
                }

                It "Should return WebAppUrl=null from the get method" {
                    (Get-TargetResource @testParams).WebAppUrl | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Members Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"
                }
            }

            Context -Name "ActAsSystemAccount parameter specified without Full Control in MembersToInclude" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToInclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    ActAsSystemAccount = $true
                                } -ClientOnly)
                        )
                    }
                }

                It "Should return WebAppUrl=null from the get method" {
                    (Get-TargetResource @testParams).WebAppUrl | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "MembersToInclude Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"
                }
            }

            Context -Name "The Members parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Members          = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                        SetCacheAccounts = $true
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
                            }
                        )
                        $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{
                                portalsuperuseraccount   = "contoso\sp_psu"
                                portalsuperreaderaccount = "contoso\sp_psr"
                            }
                        }

                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru

                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "add user policy from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The MembersToInclude parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToInclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                        SetCacheAccounts = $true
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = 'FullRead'
                            }
                        )
                        $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{
                                portalsuperuseraccount   = "contoso\sp_psu"
                                portalsuperreaderaccount = "contoso\sp_psr"
                            }
                        }

                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru

                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "add user policy from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The Members parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the webapp" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Members          = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                        SetCacheAccounts = $true
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = 'FullRead'
                            }
                        )
                        $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{
                            }
                        }

                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru

                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
                }
            }

            Context -Name "The MembersToInclude parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the webapp" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToInclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                        SetCacheAccounts = $true
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = 'FullRead'
                            }
                        )
                        $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{
                            }
                        }

                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru

                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
                }
            }

            Context -Name "The Members parameter used with SetCacheAccounts to True and the Cache Users users are configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Members          = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                        SetCacheAccounts = $true
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindingsFR = @(
                            @{
                                Name = "Full Read"
                                Type = 'FullRead'
                            }
                        )
                        $roleBindingsFR = $roleBindingsFR | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $roleBindingsFC = @(
                            @{
                                Name = "Full Control"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
                            }
                        )
                        $roleBindingsFC = $roleBindingsFC | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "i:0#.w|contoso\user1"
                                PolicyRoleBindings = $roleBindingsFR
                                IsSystemUser       = $false
                            }
                            @{
                                UserName           = "i:0#.w|contoso\sp_psu"
                                PolicyRoleBindings = $roleBindingsFC
                                IsSystemUser       = $false
                            }
                            @{
                                UserName           = "i:0#.w|contoso\sp_psr"
                                PolicyRoleBindings = $roleBindingsFR
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{
                                portalsuperuseraccount   = "i:0#.w|contoso\sp_psu"
                                portalsuperreaderaccount = "i:0#.w|contoso\sp_psr"
                            }
                        }

                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru

                        return @($webApp)
                    }
                }

                It "Should return a set of 3 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 3
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The MembersToInclude parameter used with SetCacheAccounts to True and the Cache Users users are configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToInclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Claims"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                        SetCacheAccounts = $true
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindingsFR = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
                            }
                        )
                        $roleBindingsFR = $roleBindingsFR | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $roleBindingsFC = @(
                            @{
                                Name = "Full Control"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
                            }
                        )
                        $roleBindingsFC = $roleBindingsFC | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "i:0#.w|contoso\user1"
                                PolicyRoleBindings = $roleBindingsFR
                                IsSystemUser       = $false
                            }
                            @{
                                UserName           = "i:0#.w|contoso\sp_psu"
                                PolicyRoleBindings = $roleBindingsFC
                                IsSystemUser       = $false
                            }
                            @{
                                UserName           = "i:0#.w|contoso\sp_psr"
                                PolicyRoleBindings = $roleBindingsFR
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{
                                portalsuperuseraccount   = "contoso\sp_psu"
                                portalsuperreaderaccount = "contoso\sp_psr"
                            }
                        }

                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru

                        return @($webApp)
                    }
                }

                It "Should return a set of 3 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 3
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The MembersToExclude parameter used, but it specifies a Cache User" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToExclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\sp_psr"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindingsFR = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
                            }
                        )
                        $roleBindingsFR = $roleBindingsFR | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $roleBindingsFC = @(
                            @{
                                Name = "Full Control"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
                            }
                        )
                        $roleBindingsFC = $roleBindingsFC | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindingsFR
                                IsSystemUser       = $false
                            }
                            @{
                                UserName           = "contoso\sp_psu"
                                PolicyRoleBindings = $roleBindingsFC
                                IsSystemUser       = $false
                            }
                            @{
                                UserName           = "contoso\sp_psr"
                                PolicyRoleBindings = $roleBindingsFR
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{
                                portalsuperuseraccount   = "contoso\sp_psu"
                                portalsuperreaderaccount = "contoso\sp_psr"
                            }
                        }

                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru

                        return @($webApp)
                    }
                }

                It "Should return a set of 3 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 3
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "You cannot exclude the Cache accounts from the Web Application Policy"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You cannot exclude the Cache accounts from the Web Application Policy"
                }
            }

            Context -Name "The Members parameter contains users that aren't configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Members   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user2"
                                    PermissionLevel    = "Full Control"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user3"
                                    PermissionLevel    = "Full Control"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
                            }
                        )
                        $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the set method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "add user policy from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The Members parameter does not contains users that are configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Members   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Claims"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
                            }
                        )
                        $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "i:0#.w|contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                            @{
                                UserName           = "i:0#.w|contoso\user2"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        ) | Add-Member -MemberType ScriptMethod -Name Add -Value { param($input) return $null } -Force -PassThru

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return a set of 2 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 2
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "remove user policy from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The MembersToInclude parameter contains users that are not configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToInclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user2"
                                    PermissionLevel    = "Full Control"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
                            }
                        )
                        $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "add user policy from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The MembersToInclude parameter contains users that are configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToInclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Read"
                                    IdentityType       = "Claims"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
                            }
                        )

                        $policies = @(
                            @{
                                UserName           = "i:0#.w|contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            },
                            @{
                                UserName           = "i:0#.w|contoso\user2"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        return @($webApp)
                    }
                }

                It "Should return a set of 2 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 2
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The MembersToExclude parameter contains users that are configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToExclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username = "contoso\user1"
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
                            }
                        )
                        $roleBindings = $roleBindings | Add-Member -MemberType ScriptMethod -Name RemoveAll -Value {
                            $Global:SPDscWebAppPolicyRemoveAllCalled = $true
                        } -PassThru

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                            @{
                                UserName           = "contoso\user2"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru |
                            Add-Member -MemberType NoteProperty Properties @{ } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return a set of 2 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 2
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "remove user policy from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The users in the Members parameter have different settings than configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Members   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Control"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
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
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "correct user policy from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The users in the MembersToInclude parameter have different settings than configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToInclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Control"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $false
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Read"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead
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
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "correct user policy from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The users in the Members parameter have different settings than configured in the policy - ActAsSystemAccount" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Members   = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Control"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $true
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Control"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
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
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "correct user policy from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The users in the MembersToInclude parameter have different settings than configured in the policy - ActAsSystemAccount" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToInclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Control"
                                    IdentityType       = "Native"
                                    ActAsSystemAccount = $true
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Control"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
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
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )
                        $policies = $policies | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $policy = @{
                                IsSystemUser = $false
                            }
                            $policy = $policy | Add-Member ScriptProperty -Name PolicyRoleBindings -Value {
                                return New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod -Name Add -Value { } -PassThru
                            } -PassThru
                            return $policy
                        } -PassThru -Force

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscWebApplicationUpdateCalled = $false
                It "correct user policy from the set method" {
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The users in the Members parameter have the same settings as configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Members   = @(
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
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
                            }
                        )

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The users in the Members parameter have the same settings as configured in the policy, in Claims format" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Members   = @(
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
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
                            }
                        )

                        $policies = @(
                            @{
                                UserName           = "i:0#.w|contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The users in the MembersToInclude parameter have the same  settings as configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
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
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
                            }
                        )

                        $policies = @(
                            @{
                                UserName           = "i:0#.w|contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The users in the MembersToExclude parameter aren't configured in the policy" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        MembersToExclude = @(
                            (New-CimInstance -ClassName MSFT_SPWebAppPolicy -Property @{
                                    Username = "contoso\user2"
                                } -ClientOnly)
                        )
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $roleBindings = @(
                            @{
                                Name = "Full Control"
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
                            }
                        )

                        $policies = @(
                            @{
                                UserName           = "contoso\user1"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        return @($webApp)
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The users in the Members parameter have the same settings as configured in the policy, in Claims format with a windows group in the results" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Members   = @(
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
                                Type = [Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl
                            }
                        )

                        $policies = @(
                            @{
                                UserName           = "i:0#.w|s-1-5-21-2753725054-2932589700-2007370523-2138"
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser       = $false
                            }
                        )

                        $webApp = @{
                            Url                     = $testParams.WebAppUrl
                            UseClaimsAuthentication = $true
                            PolicyRoles             = New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod -Name GetSpecialRole -Value { return @{ } } -PassThru
                            Policies                = $policies
                            Properties              = @{ }
                        }
                        return @($webApp)
                    }
                    Mock Resolve-SPDscSecurityIdentifier {
                        return "contoso\group1"
                    }
                }

                It "Should return a set of 1 Members from the get method" {
                    (Get-TargetResource @testParams).Members.Count | Should -Be 1
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            WebAppUrl              = "http://sharepoint.contoso.com"
                            Members                = @(
                                @{
                                    Username           = "contoso\user1"
                                    PermissionLevel    = "Full Control"
                                    ActAsSystemAccount = $true
                                }
                                @{
                                    Username        = "contoso\Group 1"
                                    PermissionLevel = "Full Read"
                                    IdentityType    = "Claims"
                                }
                            )
                            SetCacheAccountsPolicy = $false
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $spWebApp = [PSCustomObject]@{
                            Name = "SharePoint Sites"
                            Url  = "https://intranet.sharepoint.contoso.com"
                        }
                        return $spWebApp
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPWebAppPolicy [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Members                = \@\(
                MSFT_SPWebPolicyPermissions {
                    Username = 'contoso\\user1'
                    PermissionLevel = 'Full Control'
                    ActAsSystemAccount = \$True
                },
                MSFT_SPWebPolicyPermissions {
                    Username = 'contoso\\Group 1'
                    PermissionLevel = 'Full Read'
                    IdentityType = 'Claims'
                }\);
            PsDscRunAsCredential   = \$Credsspfarm;
            SetCacheAccountsPolicy = \$False;
            WebAppUrl              = "http://sharepoint.contoso.com";
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
