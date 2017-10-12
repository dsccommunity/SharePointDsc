[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPProjectServerGroup"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major) 
        {
            15 {
                Context -Name "All methods throw exceptions as Project Server support in SharePointDsc is only for 2016" -Fixture {
                    It "Should throw on the get method" {
                        { Get-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the test method" {
                        { Test-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the set method" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }
            }
            16 {
                $modulePath = "Modules\SharePointDsc\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
                Import-Module -Name (Join-Path -Path $Global:SPDscHelper.RepoRoot -ChildPath $modulePath -Resolve)

                $psDllPath = "Modules\SharePointDsc\Modules\SharePointDsc.ProjectServer\ProjectServerServices.dll"
                $bytes = [System.IO.File]::ReadAllBytes($psDllPath)
                [System.Reflection.Assembly]::Load($bytes)

                Mock -CommandName "Import-Module" -MockWith {}

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
                
                function New-SPDscResourceTable
                {
                    param(
                        [Parameter(Mandatory = $true)]
                        [System.Collections.Hashtable]
                        $Values
                    )
                    $ds = New-Object -TypeName "System.Data.DataSet"
                    $ds.Tables.Add("Resources")
                    $Values.Keys | ForEach-Object -Process {
                        $ds.Tables[0].Columns.Add($_, [System.Object]) | Out-Null
                    }
                    $row = $ds.Tables[0].NewRow()
                    $Values.Keys | ForEach-Object -Process {
                        $row[$_] = $Values.$_
                    }
                    $ds.Tables[0].Rows.Add($row) | Out-Null
                    return $ds
                }

                Mock -CommandName "Get-SPProjectPermissionMode" -MockWith {
                    return "ProjectServer"
                }

                Mock -CommandName "Convert-SPDscADGroupNameToID" -MockWith {
                    return New-Guid
                }

                Mock -CommandName "New-SPClaimsPrincipal" -MockWith {
                    return @{
                        Value = $Identity.Replace("i:0#.w|", "")
                    }
                }

                Mock -CommandName "New-SPDscProjectServerWebService" -ParameterFilter {
                    $EndpointName -eq "Security"
                } -MockWith {
                    $service = [SPDscTests.DummyWebService]::new()
                    $service = $service | Add-Member -MemberType ScriptMethod `
                                                     -Name ReadGroupList `
                                                     -Value {
                                                         if ($global:SPDscCreateGroupsCalled -eq $true)
                                                         {
                                                            return $global:SPDscCurrentGroupList
                                                         }
                                                         return $global:SPDscEmptyList
                                                     } -PassThru -Force `
                                        | Add-Member -MemberType ScriptMethod `
                                                     -Name CreateGroups `
                                                     -Value {
                                                         $global:SPDscCreateGroupsCalled = $true
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
                                                     } -PassThru -Force `
                                        | Add-Member -MemberType ScriptMethod `
                                                     -Name DeleteGroups `
                                                     -Value {
                                                         $global:SPDscDeleteGroupsCalled = $true
                                                     } -PassThru -Force
                    return $service
                }

                Mock -CommandName "Get-SPDscProjectServerResourceId" -MockWIth {
                    return New-Guid
                }

                $global:SPDscEmptyList = @{
                    SecurityGroups = @(
                        @{
                            WSEC_GRP_NAME = "Not the group you want"
                            WSEC_GRP_UID = (New-Guid)
                        }
                    )
                }

                Context -Name "A group doesn't exist, but should" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        Description = "An example description"
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = New-Object -TypeName "System.Object" `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @()
                        }
                    }

                    It "should return absent from the get method" {
                        $global:SPDscCreateGroupsCalled = $false
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "should return false from the test method" {
                        $global:SPDscCreateGroupsCalled = $false
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should create the group in the set method" {
                        $global:SPDscCreateGroupsCalled = $false
                        $global:SPDscSetGroupsCalled = $false
                        Set-TargetResource @testParams
                        $global:SPDscCreateGroupsCalled | Should Be $true
                        $global:SPDscSetGroupsCalled | Should Be $true
                    }
                }

                Context -Name "A group exists, and should and also has a correct description" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        Description = "An example description"
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = $testParams.Description
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @()
                        }
                    }

                    It "should return present from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "should return true from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "A group exists, but shouldn't" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        Ensure = "Absent"
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = $testParams.Description
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @()
                        }
                    }

                    It "should return present from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "should return false from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should remove the group in the set method" {
                        $global:SPDscDeleteGroupsCalled = $false
                        Set-TargetResource @testParams
                        $global:SPDscDeleteGroupsCalled | Should Be $true
                    }
                }

                Context -Name "A group doesn't exist, and shouldn't" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        Ensure = "Absent"
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = $null

                    It "should return absent from the get method" {
                        $global:SPDscCreateGroupsCalled = $false
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "should return true from the test method" {
                        $global:SPDscCreateGroupsCalled = $false
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "A group has an incorrect description set" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        Description = "An example description"
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = "Incorrect description"
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @()
                        }
                    }

                    It "should return present from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "should return false from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should create the group in the set method" {
                        $global:SPDscCreateGroupsCalled = $false
                        $global:SPDscSetGroupsCalled = $false
                        Set-TargetResource @testParams
                        $global:SPDscSetGroupsCalled | Should Be $true
                    }
                }

                Context -Name "A group has an incorrect AD group set" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        ADGroup = "DEMO\Group Name"
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = "Incorrect description"
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return New-Guid } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @()
                        }
                    }

                    Mock -CommandName "Convert-SPDscADGroupIDToName" -MockWith {
                        return "DEMO\Wrong Group"
                    }

                    It "should return present from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "should return false from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should create the group in the set method" {
                        $global:SPDscCreateGroupsCalled = $false
                        $global:SPDscSetGroupsCalled = $false
                        Set-TargetResource @testParams
                        $global:SPDscSetGroupsCalled | Should Be $true
                    }
                }

                Context -Name "A group has a correct AD group set" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        ADGroup = "DEMO\Group Name"
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = "Incorrect description"
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return New-Guid } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @()
                        }
                    }

                    Mock -CommandName "Convert-SPDscADGroupIDToName" -MockWith {
                        return $testParams.ADGroup
                    }

                    It "should return present from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "should return true from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "A group has a fixed members list that doesn't match" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        Members = @(
                            "DEMO\Member1",
                            "DEMO\Member2"
                        )
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = $testParams.Description
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @(
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                            )
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByRES_UIDWSEC_GRP_UID `
                                         -Value {
                                             return New-Object -TypeName "System.Object" `
                                                        | Add-Member -MemberType ScriptMethod `
                                                                     -Name Delete `
                                                                     -Value {
                                                                         $global:SPDscMemberDeleteCalled = $true
                                                                     } -PassThru -Force
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name NewGroupMembersRow `
                                         -Value {
                                             return @{
                                                WSEC_GRP_UID = ""
                                                RES_UID = ""
                                             }
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name AddGroupMembersRow `
                                         -Value {
                                            $global:SPDscMemberRowAddedCalled = $true
                                         } -PassThru -Force
                    }

                    $global:SPDscCurrentMembers = @(
                        "i:0#.w|DEMO\Member1"
                        "i:0#.w|DEMO\Member3"
                        "i:0#.w|DEMO\Member4"
                    )
                    Mock -CommandName "Get-SPDscProjectServerResourceName" -MockWith {
                        $value = $global:SPDscCurrentMembers[$global:SPDscCurrentMembersReadCount]
                        $global:SPDscCurrentMembersReadCount ++
                        return $value
                    }

                    It "should return current members from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        (Get-TargetResource @testParams).Members.Count | Should BeGreaterThan 0
                    }

                    It "should return false from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should update the members group in the set method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        $global:SPDscMemberDeleteCalled = $false
                        $global:SPDscMemberRowAddedCalled = $false
                        $global:SPDscSetGroupsCalled = $false
                        Set-TargetResource @testParams
                        $global:SPDscMemberDeleteCalled | Should Be $true
                        $global:SPDscMemberRowAddedCalled | Should Be $true
                        $global:SPDscSetGroupsCalled | Should Be $true
                    }
                }

                Context -Name "A group has a fixed members list that matches" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        Members = @(
                            "DEMO\Member1"
                            "DEMO\Member3"
                            "DEMO\Member4"
                        )
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = $testParams.Description
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @(
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                            )
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByRES_UIDWSEC_GRP_UID `
                                         -Value {
                                             return New-Object -TypeName "System.Object" `
                                                        | Add-Member -MemberType ScriptMethod `
                                                                     -Name Delete `
                                                                     -Value {
                                                                         $global:SPDscMemberDeleteCalled = $true
                                                                     } -PassThru -Force
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name NewGroupMembersRow `
                                         -Value {
                                             return @{
                                                WSEC_GRP_UID = ""
                                                RES_UID = ""
                                             }
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name AddGroupMembersRow `
                                         -Value {
                                            $global:SPDscMemberRowAddedCalled = $true
                                         } -PassThru -Force
                    }

                    $global:SPDscCurrentMembers = @(
                        "i:0#.w|DEMO\Member1"
                        "i:0#.w|DEMO\Member3"
                        "i:0#.w|DEMO\Member4"
                    )
                    Mock -CommandName "Get-SPDscProjectServerResourceName" -MockWith {
                        $value = $global:SPDscCurrentMembers[$global:SPDscCurrentMembersReadCount]
                        $global:SPDscCurrentMembersReadCount ++
                        return $value
                    }

                    It "should return current members from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        (Get-TargetResource @testParams).Members.Count | Should BeGreaterThan 0
                    }

                    It "should return true from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "A group has a list of members to include that doesn't match" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        MembersToInclude = @(
                            "DEMO\Member2"
                        )
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = $testParams.Description
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @(
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                            )
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByRES_UIDWSEC_GRP_UID `
                                         -Value {
                                             return New-Object -TypeName "System.Object" `
                                                        | Add-Member -MemberType ScriptMethod `
                                                                     -Name Delete `
                                                                     -Value {
                                                                         $global:SPDscMemberDeleteCalled = $true
                                                                     } -PassThru -Force
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name NewGroupMembersRow `
                                         -Value {
                                             return @{
                                                WSEC_GRP_UID = ""
                                                RES_UID = ""
                                             }
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name AddGroupMembersRow `
                                         -Value {
                                            $global:SPDscMemberRowAddedCalled = $true
                                         } -PassThru -Force
                    }

                    $global:SPDscCurrentMembers = @(
                        "i:0#.w|DEMO\Member1"
                        "i:0#.w|DEMO\Member3"
                        "i:0#.w|DEMO\Member4"
                    )
                    Mock -CommandName "Get-SPDscProjectServerResourceName" -MockWith {
                        $value = $global:SPDscCurrentMembers[$global:SPDscCurrentMembersReadCount]
                        $global:SPDscCurrentMembersReadCount ++
                        return $value
                    }

                    It "should return current members from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        (Get-TargetResource @testParams).Members.Count | Should BeGreaterThan 0
                    }

                    It "should return false from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should update the members group in the set method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        $global:SPDscMemberDeleteCalled = $false
                        $global:SPDscMemberRowAddedCalled = $false
                        $global:SPDscSetGroupsCalled = $false
                        Set-TargetResource @testParams
                        $global:SPDscMemberRowAddedCalled | Should Be $true
                        $global:SPDscSetGroupsCalled | Should Be $true
                    }
                }

                Context -Name "A group has a list of members to include that does match" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        MembersToInclude = @(
                            "DEMO\Member1"
                        )
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = $testParams.Description
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @(
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                            )
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByRES_UIDWSEC_GRP_UID `
                                         -Value {
                                             return New-Object -TypeName "System.Object" `
                                                        | Add-Member -MemberType ScriptMethod `
                                                                     -Name Delete `
                                                                     -Value {
                                                                         $global:SPDscMemberDeleteCalled = $true
                                                                     } -PassThru -Force
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name NewGroupMembersRow `
                                         -Value {
                                             return @{
                                                WSEC_GRP_UID = ""
                                                RES_UID = ""
                                             }
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name AddGroupMembersRow `
                                         -Value {
                                            $global:SPDscMemberRowAddedCalled = $true
                                         } -PassThru -Force
                    }

                    $global:SPDscCurrentMembers = @(
                        "i:0#.w|DEMO\Member1"
                        "i:0#.w|DEMO\Member3"
                        "i:0#.w|DEMO\Member4"
                    )
                    Mock -CommandName "Get-SPDscProjectServerResourceName" -MockWith {
                        $value = $global:SPDscCurrentMembers[$global:SPDscCurrentMembersReadCount]
                        $global:SPDscCurrentMembersReadCount ++
                        return $value
                    }

                    It "should return current members from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        (Get-TargetResource @testParams).Members.Count | Should BeGreaterThan 0
                    }

                    It "should return true from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "A group has a list of members to exclude that doesn't match" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        MembersToExclude = @(
                            "DEMO\Member1"
                        )
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = $testParams.Description
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @(
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                            )
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByRES_UIDWSEC_GRP_UID `
                                         -Value {
                                             return New-Object -TypeName "System.Object" `
                                                        | Add-Member -MemberType ScriptMethod `
                                                                     -Name Delete `
                                                                     -Value {
                                                                         $global:SPDscMemberDeleteCalled = $true
                                                                     } -PassThru -Force
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name NewGroupMembersRow `
                                         -Value {
                                             return @{
                                                WSEC_GRP_UID = ""
                                                RES_UID = ""
                                             }
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name AddGroupMembersRow `
                                         -Value {
                                            $global:SPDscMemberRowAddedCalled = $true
                                         } -PassThru -Force
                    }

                    $global:SPDscCurrentMembers = @(
                        "i:0#.w|DEMO\Member1"
                        "i:0#.w|DEMO\Member3"
                        "i:0#.w|DEMO\Member4"
                    )
                    Mock -CommandName "Get-SPDscProjectServerResourceName" -MockWith {
                        $value = $global:SPDscCurrentMembers[$global:SPDscCurrentMembersReadCount]
                        $global:SPDscCurrentMembersReadCount ++
                        return $value
                    }

                    It "should return current members from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        (Get-TargetResource @testParams).Members.Count | Should BeGreaterThan 0
                    }

                    It "should return false from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should update the members group in the set method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        $global:SPDscMemberDeleteCalled = $false
                        $global:SPDscMemberRowAddedCalled = $false
                        $global:SPDscSetGroupsCalled = $false
                        Set-TargetResource @testParams
                        $global:SPDscMemberDeleteCalled | Should Be $true
                        $global:SPDscSetGroupsCalled | Should Be $true
                    }
                }

                Context -Name "A group has a list of members to exclude that does match" -Fixture {
                    $testParams = @{
                        Url = "http://server/pwa"
                        Name = "New Group 1"
                        MembersToExclude = @(
                            "DEMO\Member2"
                        )
                    }

                    $global:SPDscCurrentGroupList = @{
                        SecurityGroups = @(
                            @{
                                WSEC_GRP_NAME = $testParams.Name
                                WSEC_GRP_UID = (New-Guid)
                            }
                            @{
                                WSEC_GRP_NAME = "Not the group you want"
                                WSEC_GRP_UID = (New-Guid)
                            }
                        )
                    }

                    $global:SPDscCurrentGroupDetails = @{
                        SecurityGroups = @{
                            WSEC_GRP_NAME = $testParams.Name
                            WSEC_GRP_DESC = $testParams.Description
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByWSEC_GRP_UID `
                                         -Value {
                                             return @{
                                                WSEC_GRP_NAME = $testParams.Name
                                                WSEC_GRP_DESC = ""
                                                WSEC_GRP_AD_GUID = $null
                                                WSEC_GRP_AD_GROUP = $null
                                            }
                                         } `
                                       -Force -PassThru `
                            | Add-Member -MemberType ScriptProperty `
                                         -Name WSEC_GRP_AD_GUID `
                                         -Value { return [System.DBNull]::Value } `
                                         -PassThru -Force
                        GroupMembers = @{
                            Rows = @(
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                                @{ RES_UID = New-Guid }
                            )
                        }   | Add-Member -MemberType ScriptMethod `
                                         -Name FindByRES_UIDWSEC_GRP_UID `
                                         -Value {
                                             return New-Object -TypeName "System.Object" `
                                                        | Add-Member -MemberType ScriptMethod `
                                                                     -Name Delete `
                                                                     -Value {
                                                                         $global:SPDscMemberDeleteCalled = $true
                                                                     } -PassThru -Force
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name NewGroupMembersRow `
                                         -Value {
                                             return @{
                                                WSEC_GRP_UID = ""
                                                RES_UID = ""
                                             }
                                         } -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                         -Name AddGroupMembersRow `
                                         -Value {
                                            $global:SPDscMemberRowAddedCalled = $true
                                         } -PassThru -Force
                    }

                    $global:SPDscCurrentMembers = @(
                        "i:0#.w|DEMO\Member1"
                        "i:0#.w|DEMO\Member3"
                        "i:0#.w|DEMO\Member4"
                    )
                    Mock -CommandName "Get-SPDscProjectServerResourceName" -MockWith {
                        $value = $global:SPDscCurrentMembers[$global:SPDscCurrentMembersReadCount]
                        $global:SPDscCurrentMembersReadCount ++
                        return $value
                    }

                    It "should return current members from the get method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        (Get-TargetResource @testParams).Members.Count | Should BeGreaterThan 0
                    }

                    It "should return true from the test method" {
                        $global:SPDscCreateGroupsCalled = $true
                        $global:SPDscCurrentMembersReadCount = 0
                        Test-TargetResource @testParams | Should Be $true
                    }
                }
            }
            Default {
                throw [Exception] "A supported version of SharePoint was not used in testing"
            }
        }
    }
}
