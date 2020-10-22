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
$script:DSCResourceName = 'SPProjectServerGlobalPermissions'
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

                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
                {
                    $script:projectPath = "$PSScriptRoot\..\..\.." | Convert-Path
                    $script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
                            ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                            $(try
                                { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
                                }
                                catch
                                { $false
                                })
                        }).BaseName

                    $script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
                    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

                    $modulePath = Join-Path -Path $script:subModulesFolder -ChildPath "SharePointDsc.ProjectServerConnector\SharePointDsc.ProjectServerConnector.psm1" -Resolve
                    Import-Module -Name $modulePath

                    [System.Reflection.Assembly]::LoadWithPartialName("System.ServiceModel") | Out-Null
                    $fullDllPath = Join-Path -Path $script:subModulesFolder -ChildPath "SharePointDsc.ProjectServerConnector\ProjectServerServices.dll" -Resolve
                    $bytes = [System.IO.File]::ReadAllBytes($fullDllPath)
                    [System.Reflection.Assembly]::Load($bytes) | Out-Null

                    Mock -CommandName "Import-Module" -MockWith { }

                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            WebApplication = @{
                                Url = "http://server"
                            }
                        }
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{
                            DisableKerberos = $true
                        }
                    }

                    try
                    {
                        [SPDscTests.DummyWebService] | Out-Null
                    }
                    catch
                    {
                        Add-Type -TypeDefinition @"
                            namespace SPDscTests
                            {
                                public class DummyWebService : System.IDisposable
                                {
                                    public void Dispose()
                                    {

                                    }
                                }
                            }
"@
                    }

                    function New-SPDscUserGlobalPermissionsTable
                    {
                        param(
                            [Parameter(Mandatory = $true)]
                            [System.Collections.Hashtable[]]
                            $Values
                        )
                        $ds = [SvcResource.ResourceAuthorizationDataSet]::new()

                        $Values | ForEach-Object -Process {
                            $currentValue = $_
                            $row = $ds.GlobalPermissions.NewGlobalPermissionsRow()
                            $Values.Keys | ForEach-Object -Process {
                                $row[$_] = $currentValue.$_
                            }
                            $ds.GlobalPermissions.AddGlobalPermissionsRow($row) | Out-Null
                        }
                        return $ds
                    }

                    function New-SPDscGroupGlobalPermissionsTable
                    {
                        param(
                            [Parameter(Mandatory = $true)]
                            [System.Collections.Hashtable[]]
                            $Values
                        )
                        $ds = [SvcSecurity.SecurityGroupsDataSet]::new()

                        $Values | ForEach-Object -Process {
                            $currentValue = $_
                            $row = $ds.GlobalPermissions.NewGlobalPermissionsRow()
                            $Values.Keys | ForEach-Object -Process {
                                $row[$_] = $currentValue.$_
                            }
                            $ds.GlobalPermissions.AddGlobalPermissionsRow($row) | Out-Null
                        }
                        return $ds
                    }

                    Mock -CommandName "Get-SPProjectPermissionMode" -MockWith {
                        return "ProjectServer"
                    }

                    Mock -CommandName "New-SPDscProjectServerWebService" -ParameterFilter {
                        $EndpointName -eq "Security"
                    } -MockWith {
                        $service = [SPDscTests.DummyWebService]::new()
                        $service = $service | Add-Member -MemberType ScriptMethod `
                            -Name ReadGroupList `
                            -Value {
                            return @{
                                SecurityGroups = @(
                                    @{
                                        WSEC_GRP_NAME = "Group1"
                                        WSEC_GRP_UID  = $global:SPDscGroupId
                                    }
                                )
                            }
                        } -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name ReadGroup `
                            -Value {
                            return $global:SPDscCurrentGroupDetails
                        } -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name SetGroups `
                            -Value {
                            $global:SPDscSetGroupsCalled = $true
                        } -PassThru -Force
                        return $service
                    }

                    Mock -CommandName "New-SPDscProjectServerWebService" -ParameterFilter {
                        $EndpointName -eq "Resource"
                    } -MockWith {
                        $service = [SPDscTests.DummyWebService]::new()
                        $service = $service | Add-Member -MemberType ScriptMethod `
                            -Name ReadResourceAuthorization `
                            -Value {
                            return $global:SPDscCurrentResourceAuth
                        } -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name UpdateResources `
                            -Value {
                            $global:SPDscUpdateResourcesCalled = $true
                        } -PassThru -Force
                        return $service
                    }

                    $global:SPDscResourceId = New-Guid
                    $global:SPDscGroupId = New-Guid
                    Mock -CommandName "Get-SPDscProjectServerResourceId" -MockWith {
                        return $global:SPDscResourceId
                    }

                    Mock -CommandName "Get-SPDscProjectServerGlobalPermissionId" -MockWith {
                        $permissions = @{
                            "FakePermission1" = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7950")
                            "FakePermission2" = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7951")
                            "FakePermission3" = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7952")
                            "FakePermission4" = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7953")
                        }
                        return $permissions[$PermissionName]
                    }

                    Mock -CommandName "Get-SPDscProjectServerPermissionName" -MockWith {
                        $permissions = @{
                            [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7950") = "FakePermission1"
                            [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7951") = "FakePermission2"
                            [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7952") = "FakePermission3"
                            [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7953") = "FakePermission4"
                        }
                        return $permissions[$PermissionId]
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
            }

            switch ($global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15
                {
                    Context -Name "All methods throw exceptions as Project Server support in SharePointDsc is only for 2016" -Fixture {
                        It "Should throw on the get method" {
                            { Get-TargetResource @testParams } | Should -Throw
                        }

                        It "Should throw on the test method" {
                            { Test-TargetResource @testParams } | Should -Throw
                        }

                        It "Should throw on the set method" {
                            { Set-TargetResource @testParams } | Should -Throw
                        }
                    }
                }
                16
                {
                    Context -Name "A resource should have permissions but is missing some" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Url              = "http://server/pwa"
                                EntityType       = "User"
                                EntityName       = "TEST\user1"
                                AllowPermissions = @(
                                    "FakePermission1",
                                    "FakePermission2"
                                )
                                DenyPermissions  = @(
                                    "FakePermission3",
                                    "FakePermission4"
                                )
                            }

                            $global:SPDscCurrentResourceAuth = New-SPDscUserGlobalPermissionsTable -Values @(
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7950")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7952")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                }
                            )
                        }

                        It "Should return the current permissions from the get method" {
                            (Get-TargetResource @testParams).AllowPermissions | Should -Not -BeNullOrEmpty
                        }

                        It "Should return false from the set method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "Should call methods to add the missing permissions in the set method" {
                            $global:SPDscUpdateResourcesCalled = $false
                            Set-TargetResource @testParams
                            $global:SPDscUpdateResourcesCalled | Should -Be $true
                        }
                    }

                    Context -Name "A resource should have permissions but has additional ones" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Url              = "http://server/pwa"
                                EntityType       = "User"
                                EntityName       = "TEST\user1"
                                AllowPermissions = @(
                                    "FakePermission1"
                                )
                                DenyPermissions  = @(
                                    "FakePermission3"
                                )
                            }

                            $global:SPDscCurrentResourceAuth = New-SPDscUserGlobalPermissionsTable -Values @(
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7950")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7951")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7952")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                },
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7953")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                }
                            )
                        }

                        It "Should return the current permissions from the get method" {
                            (Get-TargetResource @testParams).AllowPermissions | Should -Not -BeNullOrEmpty
                        }

                        It "Should return false from the set method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "Should call methods to add the missing permissions in the set method" {
                            $global:SPDscUpdateResourcesCalled = $false
                            Set-TargetResource @testParams
                            $global:SPDscUpdateResourcesCalled | Should -Be $true
                        }
                    }

                    Context -Name "A resource should have permissions and they match" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Url              = "http://server/pwa"
                                EntityType       = "User"
                                EntityName       = "TEST\user1"
                                AllowPermissions = @(
                                    "FakePermission1",
                                    "FakePermission2"
                                )
                                DenyPermissions  = @(
                                    "FakePermission3",
                                    "FakePermission4"
                                )
                            }

                            $global:SPDscCurrentResourceAuth = New-SPDscUserGlobalPermissionsTable -Values @(
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7950")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7951")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7952")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                },
                                @{
                                    RES_UID          = $global:SPDscResourceId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7953")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                }
                            )
                        }

                        It "Should return the current permissions from the get method" {
                            (Get-TargetResource @testParams).AllowPermissions | Should -Not -BeNullOrEmpty
                        }

                        It "Should return true from the set method" {
                            Test-TargetResource @testParams | Should -Be $true
                        }
                    }

                    Context -Name "A group should have permissions but is missing some" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Url              = "http://server/pwa"
                                EntityType       = "Group"
                                EntityName       = "group1"
                                AllowPermissions = @(
                                    "FakePermission1",
                                    "FakePermission2"
                                )
                                DenyPermissions  = @(
                                    "FakePermission3",
                                    "FakePermission4"
                                )
                            }

                            $global:SPDscCurrentGroupDetails = New-SPDscGroupGlobalPermissionsTable -Values @(
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7950")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7952")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                }
                            )
                        }

                        It "Should return the current permissions from the get method" {
                            (Get-TargetResource @testParams).AllowPermissions | Should -Not -BeNullOrEmpty
                        }

                        It "Should return false from the set method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "Should call methods to add the missing permissions in the set method" {
                            $global:SPDscSetGroupsCalled = $false
                            Set-TargetResource @testParams
                            $global:SPDscSetGroupsCalled | Should -Be $true
                        }
                    }

                    Context -Name "A group should have permissions but has additional ones" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Url              = "http://server/pwa"
                                EntityType       = "Group"
                                EntityName       = "Group1"
                                AllowPermissions = @(
                                    "FakePermission1"
                                )
                                DenyPermissions  = @(
                                    "FakePermission3"
                                )
                            }

                            $global:SPDscCurrentGroupDetails = New-SPDscGroupGlobalPermissionsTable -Values @(
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7950")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7951")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7952")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                },
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7953")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                }
                            )
                        }

                        It "Should return the current permissions from the get method" {
                            (Get-TargetResource @testParams).AllowPermissions | Should -Not -BeNullOrEmpty
                        }

                        It "Should return false from the set method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "Should call methods to add the missing permissions in the set method" {
                            $global:SPDscSetGroupsCalled = $false
                            Set-TargetResource @testParams
                            $global:SPDscSetGroupsCalled | Should -Be $true
                        }
                    }

                    Context -Name "A group should have permissions and they match" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Url              = "http://server/pwa"
                                EntityType       = "Group"
                                EntityName       = "Group1"
                                AllowPermissions = @(
                                    "FakePermission1",
                                    "FakePermission2"
                                )
                                DenyPermissions  = @(
                                    "FakePermission3",
                                    "FakePermission4"
                                )
                            }

                            $global:SPDscCurrentGroupDetails = New-SPDscGroupGlobalPermissionsTable -Values @(
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7950")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7951")
                                    WSEC_ALLOW       = $true
                                    WSEC_DENY        = $false
                                },
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7952")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                },
                                @{
                                    WSEC_GRP_UID     = $global:SPDscGroupId
                                    WSEC_FEA_ACT_UID = [Guid]::Parse("ce501426-c4bf-4619-a635-a937b7be7953")
                                    WSEC_ALLOW       = $false
                                    WSEC_DENY        = $true
                                }
                            )
                        }

                        It "Should return the current permissions from the get method" {
                            (Get-TargetResource @testParams).AllowPermissions | Should -Not -BeNullOrEmpty
                        }

                        It "Should return true from the set method" {
                            Test-TargetResource @testParams | Should -Be $true
                        }
                    }
                }
                Default
                {
                    throw [Exception] "A supported version of SharePoint was not used in testing"
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
