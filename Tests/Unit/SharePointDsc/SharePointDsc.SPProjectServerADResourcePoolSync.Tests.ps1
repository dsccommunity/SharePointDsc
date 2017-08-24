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
                                              -DscResource "SPProjectServerADResourcePoolSync"

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
                Mock -CommandName "Enable-SPProjectActiveDirectoryEnterpriseResourcePoolSync" -MockWith {}
                Mock -CommandName "Disable-SPProjectActiveDirectoryEnterpriseResourcePoolSync" -MockWith {}
                Mock -CommandName "Import-Module" -MockWith {}
                Mock -CommandName "New-Object" -ParameterFilter {
                    $TypeName -eq "System.DirectoryServices.DirectoryEntry"
                } -MockWith { return @{
                    objectGUID = @{
                        Value = (New-Guid)
                    }
                } }

                Mock -CommandName "New-Object" -ParameterFilter {
                    $TypeName -eq "System.DirectoryServices.DirectorySearcher"
                } -MockWith { 
                    $searcher = @{
                        SearchRoot = $null
                        PageSize = $null
                        Filter = $null
                        SearchScope = $null
                        PropertiesToLoad = (New-Object -TypeName "System.Collections.Generic.List[System.String]")
                    }
                    $searcher = $searcher | Add-Member -MemberType ScriptMethod `
                                                       -Name FindOne `
                                                       -Value {
                                                           $result = @{}
                                                           $result = $result | Add-Member -MemberType ScriptMethod `
                                                                                          -Name GetDirectoryEntry `
                                                                                          -Value {
                                                                                              return @{
                                                                                                objectsid = @("item")
                                                                                              }
                                                                                          } -PassThru -Force
                                                            return $result
                                                       } -PassThru -Force
                    return $searcher
                }
                Mock -CommandName "New-Object" -ParameterFilter {
                    $TypeName -eq "System.Security.Principal.SecurityIdentifier"
                } -MockWith {
                    $sid = @{}
                    $sid = $sid | Add-Member -MemberType ScriptMethod `
                                             -Name Translate `
                                             -Value {
                                                 $returnVal = $global:SPDscGroupsToReturn[$global:SPDscSidCount]
                                                 $global:SPDscSidCount++
                                                 return $returnVal
                                             } -PassThru -Force
                    return $sid
                }
                Mock -CommandName "New-Object" -ParameterFilter {
                    $TypeName -eq "System.Security.Principal.NTAccount"
                } -MockWith {
                    $sid = @{}
                    $sid = $sid | Add-Member -MemberType ScriptMethod `
                                             -Name Translate `
                                             -Value {
                                                 $returnVal = $global:SPDscSidsToReturn[$global:SPDscSidCount]
                                                 $global:SPDscSidCount++
                                                 return $returnVal
                                             } -PassThru -Force
                    return $sid
                }

                Context -Name "No AD groups are set but there should be" -Fixture { 
                    $testParams = @{
                        Url = "http://server/pwa"
                        GroupNames = @("DOMAIN\Group 1", "DOMAIN\Group 2")
                        Ensure = "Present"
                    }

                    Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                        $service = [SPDscTests.DummyWebService]::new()
                        $service = $service | Add-Member -MemberType ScriptMethod `
                                                         -Name GetActiveDirectorySyncEnterpriseResourcePoolSettings2 `
                                                         -Value {
                                                            return @{
                                                                ADGroupGuids = ([Guid[]]::new(0))
                                                            }
                                                         } -PassThru -Force
                        return $service
                    }

                    $global:SPDscGroupsToReturn = @()
                    $global:SPDscSidsToReturn = @("example SID", "example SID")

                    It "should return absent from the get method" {
                        $global:SPDscSidCount = 0    
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "should return false from the test method" {
                        $global:SPDscSidCount = 0
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should make the updates in the set method" {
                        $global:SPDscSidCount = 0
                        Set-TargetResource @testParams
                        Assert-MockCalled -CommandName "Enable-SPProjectActiveDirectoryEnterpriseResourcePoolSync"
                    }
                }

                Context -Name "AD groups are set but they are incorrect" -Fixture { 
                    $testParams = @{
                        Url = "http://server/pwa"
                        GroupNames = @("DOMAIN\Group 1", "DOMAIN\Group 2")
                        Ensure = "Present"
                    }

                    Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                        $service = [SPDscTests.DummyWebService]::new()
                        $service = $service | Add-Member -MemberType ScriptMethod `
                                                         -Name GetActiveDirectorySyncEnterpriseResourcePoolSettings2 `
                                                         -Value {
                                                            return @{
                                                                ADGroupGuids = ([Guid[]](New-Guid))
                                                            }
                                                         } -PassThru -Force
                        return $service
                    }

                    $global:SPDscGroupsToReturn = @("DOMAIN\Group 1")
                    $global:SPDscSidsToReturn = @("example SID", "example SID")

                    It "should return present from the get method" {
                        $global:SPDscSidCount = 0
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "should return false from the test method" {
                        $global:SPDscSidCount = 0
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should make the updates in the set method" {
                        $global:SPDscSidCount = 0
                        Set-TargetResource @testParams
                        Assert-MockCalled -CommandName "Enable-SPProjectActiveDirectoryEnterpriseResourcePoolSync"
                    }
                } 

                Context -Name "AD groups are set and they are correct" -Fixture { 
                    $testParams = @{
                        Url = "http://server/pwa"
                        GroupNames = @("DOMAIN\Group 1", "DOMAIN\Group 2")
                        Ensure = "Present"
                    }

                    Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                        $service = [SPDscTests.DummyWebService]::new()
                        $service = $service | Add-Member -MemberType ScriptMethod `
                                                         -Name GetActiveDirectorySyncEnterpriseResourcePoolSettings2 `
                                                         -Value {
                                                            return @{
                                                                ADGroupGuids = ([Guid[]](New-Guid),(New-Guid))
                                                            }
                                                         } -PassThru -Force
                        return $service
                    }

                    $global:SPDscGroupsToReturn = @("DOMAIN\Group 1", "DOMAIN\Group 2")
                    $global:SPDscSidsToReturn = @("example SID", "example SID")

                    It "should return present from the get method" {
                        $global:SPDscSidCount = 0
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "should return true from the test method" {
                        $global:SPDscSidCount = 0
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "AD groups are set and there should not be" -Fixture { 
                    $testParams = @{
                        Url = "http://server/pwa"
                        Ensure = "Absent"
                    }

                    Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                        $service = [SPDscTests.DummyWebService]::new()
                        $service = $service | Add-Member -MemberType ScriptMethod `
                                                         -Name GetActiveDirectorySyncEnterpriseResourcePoolSettings2 `
                                                         -Value {
                                                            return @{
                                                                ADGroupGuids = ([Guid[]](New-Guid),(New-Guid))
                                                            }
                                                         } -PassThru -Force
                        return $service
                    }

                    $global:SPDscGroupsToReturn = @("DOMAIN\Group 1", "DOMAIN\Group 2")
                    $global:SPDscSidsToReturn = @()

                    It "should return present from the get method" {
                        $global:SPDscSidCount = 0
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "should return false from the test method" {
                        $global:SPDscSidCount = 0
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should make the updates in the set method" {
                        $global:SPDscSidCount = 0
                        Set-TargetResource @testParams
                        Assert-MockCalled -CommandName "Disable-SPProjectActiveDirectoryEnterpriseResourcePoolSync"
                    }
                }

                Context -Name "No AD groups are set and there should not be" -Fixture { 
                    $testParams = @{
                        Url = "http://server/pwa"
                        Ensure = "Absent"
                    }

                    Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                        $service = [SPDscTests.DummyWebService]::new()
                        $service = $service | Add-Member -MemberType ScriptMethod `
                                                         -Name GetActiveDirectorySyncEnterpriseResourcePoolSettings2 `
                                                         -Value {
                                                            return @{
                                                                ADGroupGuids = $null
                                                            }
                                                         } -PassThru -Force
                        return $service
                    }

                    $global:SPDscGroupsToReturn = @()
                    $global:SPDscSidsToReturn = @()

                    It "should return absent from the get method" {
                        $global:SPDscSidCount = 0
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "should return true from the test method" {
                        $global:SPDscSidCount = 0
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
