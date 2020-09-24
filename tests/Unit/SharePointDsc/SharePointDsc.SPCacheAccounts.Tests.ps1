[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPCacheAccounts'
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
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

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
                Mock -CommandName New-SPClaimsPrincipal -MockWith {
                    $Global:SPDscClaimsPrincipalUser = $Identity
                    return (
                        New-Object -TypeName Object | Add-Member -MemberType ScriptMethod `
                            -Name "ToEncodedString" `
                            -Value {
                            return "i:0#.w|$($Global:SPDscClaimsPrincipalUser)"
                        } -PassThru
                    )
                } -ParameterFilter { $IdentityType -eq "WindowsSamAccountName" }

                Mock -CommandName New-SPClaimsPrincipal -MockWith {
                    return @{
                        Value = $Identity -replace "i:0#.w|"
                    }
                } -ParameterFilter { $IdentityType -eq "EncodedClaim" }
            }

            # Test contexts
            Context -Name "The web application specified does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://test.sharepoint.com"
                        SuperUserAlias   = "DEMO\SuperUser"
                        SuperReaderAlias = "DEMO\SuperReader"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith { return $null }
                }

                It "Should return empty values from the get method" {
                    $results = Get-TargetResource @testParams
                    $results.SuperUserAlias | Should -BeNullOrEmpty
                    $results.SuperReaderAlias | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw and exception where set is called" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "The specified cache accounts have not been configured, Claims WebApp" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://test.sharepoint.com"
                        SuperUserAlias   = "DEMO\SuperUser"
                        SuperReaderAlias = "DEMO\SuperReader"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $policiesObject = New-Object -TypeName "Object" |
                        Add-Member -MemberType ScriptMethod `
                            -Name Add `
                            -Value {
                            return New-Object -TypeName "Object" |
                            Add-Member -MemberType NoteProperty `
                                -Name PolicyRoleBindings `
                                -Value (
                                New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod `
                                    -Name Add `
                                    -Value { } `
                                    -PassThru
                            ) -PassThru
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod `
                            -Name Remove `
                            -Value { } `
                            -PassThru

                        return New-Object -TypeName "Object" |
                        Add-Member -MemberType NoteProperty `
                            -Name Properties `
                            -Value @{ } `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name Policies `
                            -Value $policiesObject `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name PolicyRoles `
                            -Value (
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetSpecialRole `
                                -Value { return @{ } } `
                                -PassThru
                        ) -PassThru |
                        Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value { } `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name UseClaimsAuthentication `
                            -Value $true `
                            -PassThru
                    }
                }

                It "Should return empty strings from the Get method" {
                    $results = Get-TargetResource @testParams
                    $results.SuperUserAlias | Should -BeNullOrEmpty
                    $results.SuperReaderAlias | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the accounts when set is called" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "The specified cache accounts have not been configured, non-claims WebApp" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://test.sharepoint.com"
                        SuperUserAlias   = "DEMO\SuperUser"
                        SuperReaderAlias = "DEMO\SuperReader"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $policiesObject = New-Object -TypeName "Object" |
                        Add-Member -MemberType ScriptMethod `
                            -Name Add `
                            -Value {
                            return New-Object -TypeName "Object" |
                            Add-Member -MemberType NoteProperty `
                                -Name PolicyRoleBindings `
                                -Value (
                                New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod `
                                    -Name Add `
                                    -Value { } `
                                    -PassThru
                            ) -PassThru
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod `
                            -Name Remove `
                            -Value { } `
                            -PassThru

                        return New-Object -TypeName "Object" |
                        Add-Member -MemberType NoteProperty `
                            -Name Properties `
                            -Value @{ } `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name Policies `
                            -Value $policiesObject `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name PolicyRoles `
                            -Value (
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetSpecialRole `
                                -Value { return @{ } } `
                                -PassThru
                        ) -PassThru |
                        Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value { } `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name UseClaimsAuthentication `
                            -Value $false `
                            -PassThru
                    }
                }

                It "Should return empty strings from the Get method" {
                    $results = Get-TargetResource @testParams
                    $results.SuperUserAlias | Should -BeNullOrEmpty
                    $results.SuperReaderAlias | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the accounts when set is called" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "The cache accounts have been configured correctly, SetWebAppPolicy set to False" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://test.sharepoint.com"
                        SuperUserAlias   = "DEMO\SuperUser"
                        SuperReaderAlias = "DEMO\SuperReader"
                        SetWebAppPolicy  = $false
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return New-Object -TypeName "Object" |
                        Add-Member -MemberType NoteProperty `
                            -Name Properties `
                            -Value @{
                            portalsuperuseraccount   = $testParams.SuperUserAlias
                            portalsuperreaderaccount = $testParams.SuperReaderAlias
                        } -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name Policies `
                            -Value @(
                            @{
                                UserName = $testParams.SuperUserAlias
                            },
                            @{
                                UserName = $testParams.SuperReaderAlias
                            },
                            @{
                                UserName = "i:0#.w|$($testParams.SuperUserAlias)"
                            },
                            @{
                                UserName = "i:0#.w|$($testParams.SuperReaderAlias)"
                            }
                        ) -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name PolicyRoles `
                            -Value (
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetSpecialRole `
                                -Value {
                                return @{ }
                            } -PassThru
                        ) -PassThru |
                        Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value { } `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name UseClaimsAuthentication `
                            -Value $false `
                            -PassThru
                    }
                }

                It "Should return the values from the get method" {
                    $results = Get-TargetResource @testParams
                    $results.SuperUserAlias | Should -Not -BeNullOrEmpty
                    $results.SuperReaderAlias | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The cache accounts have been configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://test.sharepoint.com"
                        SuperUserAlias   = "DEMO\SuperUser"
                        SuperReaderAlias = "DEMO\SuperReader"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return New-Object -TypeName "Object" |
                        Add-Member -MemberType NoteProperty `
                            -Name Properties `
                            -Value @{
                            portalsuperuseraccount   = $testParams.SuperUserAlias
                            portalsuperreaderaccount = $testParams.SuperReaderAlias
                        } -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name Policies `
                            -Value @(
                            @{
                                UserName = $testParams.SuperUserAlias
                            },
                            @{
                                UserName = $testParams.SuperReaderAlias
                            },
                            @{
                                UserName = "i:0#.w|$($testParams.SuperUserAlias)"
                            },
                            @{
                                UserName = "i:0#.w|$($testParams.SuperReaderAlias)"
                            }
                        ) -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name PolicyRoles `
                            -Value (
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetSpecialRole `
                                -Value {
                                return @{ }
                            } -PassThru
                        ) -PassThru |
                        Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value { } `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name UseClaimsAuthentication `
                            -Value $false `
                            -PassThru
                    }
                }

                It "Should return the values from the get method" {
                    $results = Get-TargetResource @testParams
                    $results.SuperUserAlias | Should -Not -BeNullOrEmpty
                    $results.SuperReaderAlias | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Cache accounts have been configured, but the reader account is wrong" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://test.sharepoint.com"
                        SuperUserAlias   = "DEMO\SuperUser"
                        SuperReaderAlias = "DEMO\SuperReader"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return New-Object -TypeName "Object" |
                        Add-Member -MemberType NoteProperty -Name Properties @{
                            portalsuperuseraccount   = $testParams.SuperUserAlias
                            portalsuperreaderaccount = "WRONG\AccountName"
                        } -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name Policies `
                            -Value (
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name Add `
                                -Value {
                                return New-Object -TypeName "Object" |
                                Add-Member -MemberType NoteProperty `
                                    -Name PolicyRoleBindings `
                                    -Value (
                                    New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod `
                                        -Name Add `
                                        -Value { } `
                                        -PassThru
                                ) -PassThru
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name Remove `
                                -Value { } `
                                -PassThru
                        ) -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name PolicyRoles `
                            -Value (
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetSpecialRole `
                                -Value {
                                return @{ }
                            } -PassThru
                        ) -PassThru |
                        Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value { } `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name UseClaimsAuthentication `
                            -Value $true `
                            -PassThru
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the correct accounts to the web app again" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "Cache accounts have been configured, but the super account is wrong" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl        = "http://test.sharepoint.com"
                        SuperUserAlias   = "DEMO\SuperUser"
                        SuperReaderAlias = "DEMO\SuperReader"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return New-Object -TypeName "Object" |
                        Add-Member -MemberType NoteProperty -Name Properties @{
                            portalsuperuseraccount   = "WRONG\AccountName"
                            portalsuperreaderaccount = $testParams.SuperReaderAlias
                        } -PassThru |
                        Add-Member -MemberType NoteProperty -Name Policies -Value (
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name Add `
                                -Value {
                                return New-Object -TypeName "Object" |
                                Add-Member -MemberType NoteProperty `
                                    -Name PolicyRoleBindings `
                                    -Value (
                                    New-Object -TypeName "Object" |
                                    Add-Member -MemberType ScriptMethod `
                                        -Name Add `
                                        -Value { } `
                                        -PassThru
                                ) -PassThru
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name Remove `
                                -Value { } `
                                -PassThru
                        ) -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name PolicyRoles `
                            -Value (
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetSpecialRole `
                                -Value {
                                return @{ }
                            } -PassThru
                        ) -PassThru |
                        Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value { } `
                            -PassThru |
                        Add-Member -MemberType NoteProperty `
                            -Name UseClaimsAuthentication `
                            -Value $true `
                            -PassThru
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should set the correct accounts to the web app again" {
                    Set-TargetResource @testParams
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
