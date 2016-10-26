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
                                              -DscResource "SPWorkManagementServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Server.WorkManagement.WorkManagementServiceApplication"

        # Mocks for all contexts   
        Mock -CommandName Remove-SPServiceApplication -MockWith { }
        Mock -CommandName New-SPWorkManagementServiceApplication -MockWith { }
        Mock -CommandName New-SPWorkManagementServiceApplicationProxy -MockWith { }

        # Test contexts
        Context -Name "When a service application exists and Ensure equals 'Absent'" -Fixture {
            $testParams = @{
                Name = "Test Work Management App"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the remove service app cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }

        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name = "Test Work Management App"
                ApplicationPool = "Test App Pool"
            }

            Mock -CommandName Get-SPServiceApplication { return $null }
            
            It "Should return null from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPWorkManagementServiceApplication 
            }
        }
        
        Context -Name "When service applications exist in the current farm but the specific Work Management app does not" -Fixture { 
            $testParams = @{
                Name = "Test Work Management App"
                ApplicationPool = "Test App Pool"
            }
            
            Mock -CommandName Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = "Microsoft.Office.UnKnownWebServiceApplication" } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture {
            $testParams = @{
                Name = "Test Work Management App"
                ApplicationPool = "Test App Pool"
                MinimumTimeBetweenEwsSyncSubscriptionSearches =10
                MinimumTimeBetweenProviderRefreshes=10
                MinimumTimeBetweenSearchQueries=10
                NumberOfSubscriptionSyncsPerEwsSyncRun=10
                NumberOfUsersEwsSyncWillProcessAtOnce=10
                NumberOfUsersPerEwsSyncBatch=10
            }

            Mock -CommandName Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    AdminSettings = @{
                            MinimumTimeBetweenEwsSyncSubscriptionSearches =  (new-timespan -minutes 10)
                            MinimumTimeBetweenProviderRefreshes= (new-timespan -minutes 10)
                            MinimumTimeBetweenSearchQueries= (new-timespan -minutes 10)
                            NumberOfSubscriptionSyncsPerEwsSyncRun=10
                            NumberOfUsersEwsSyncWillProcessAtOnce=  10
                            NumberOfUsersPerEwsSyncBatch=  10
                    }
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a service application exists and is not configured correctly" -Fixture {
            $testParams = @{
                Name = "Test Work Management App"
                ApplicationPool = "Test App Pool"
                MinimumTimeBetweenEwsSyncSubscriptionSearches =10
                MinimumTimeBetweenProviderRefreshes=10
                MinimumTimeBetweenSearchQueries=10
                NumberOfSubscriptionSyncsPerEwsSyncRun=10
                NumberOfUsersEwsSyncWillProcessAtOnce=10
                NumberOfUsersPerEwsSyncBatch=10
            }
            
            Mock -CommandName Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                    AdminSettings = @{
                            MinimumTimeBetweenEwsSyncSubscriptionSearches =  (new-timespan -minutes 10)
                            MinimumTimeBetweenProviderRefreshes= (new-timespan -minutes 10)
                            MinimumTimeBetweenSearchQueries= (new-timespan -minutes 10)
                            NumberOfSubscriptionSyncsPerEwsSyncRun=10
                            NumberOfUsersEwsSyncWillProcessAtOnce=  10
                            NumberOfUsersPerEwsSyncBatch=  10
                    }
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }
            Mock -CommandName Set-SPWorkManagementServiceApplication { }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPWorkManagementServiceApplication
                Assert-MockCalled Get-SPServiceApplication
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
