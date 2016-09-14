[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPWorkManagementServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPWorkManagement - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test Work Management App"
            ApplicationPool = "Test App Pool"
        }
        $testParamsComplete = @{
            Name = "Test Work Management App"
            ApplicationPool = "Test App Pool"
            MinimumTimeBetweenEwsSyncSubscriptionSearches =10
            MinimumTimeBetweenProviderRefreshes=10
            MinimumTimeBetweenSearchQueries=10
            NumberOfSubscriptionSyncsPerEwsSyncRun=10
            NumberOfUsersEwsSyncWillProcessAtOnce=10
            NumberOfUsersPerEwsSyncBatch=10
        }

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")

        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Context -Name "When a service application exists and Ensure equals 'absent'" {
            $testParamsAbsent = @{
                Name = "Test Work Management App"
                Ensure = "Absent"
            }
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Work Management Service Application"
                    DisplayName = $testParamsAbsent.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                })
            }
            Mock -CommandName Remove-SPServiceApplication{ }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParamsAbsent | Should Be $false
            }

            It "Should call the remove service app cmdlet from the set method" {
                Set-TargetResource @testParamsAbsent
                Assert-MockCalled Remove-SPServiceApplication
            }
        }

        Context -Name "When no service applications exist in the current farm" {

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            Mock -CommandName New-SPWorkManagementServiceApplication { }
            Mock -CommandName Set-SPWorkManagementServiceApplication { }

            Mock -CommandName New-SPWorkManagementServiceApplicationProxy { }
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

        Context -Name "When service applications exist in the current farm but the specific Work Management app does not" {
            Mock -CommandName Set-SPWorkManagementServiceApplication { }
            Mock -CommandName New-SPWorkManagementServiceApplication { }
            Mock -CommandName New-SPWorkManagementServiceApplicationProxy { }
            $Global:GetSpServiceApplicationCalled=$false
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                if($Global:GetSpServiceApplicationCalled -eq $false){
                    $Global:GetSpServiceApplicationCalled=$true;
                    return @(@{
                    TypeName = "Some other service app type"
                    })
                }
                return @(@{
                    TypeName = "Work Management Service Application" 
                        })
            }
            
        
            It "Should return null from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should create  new app from the Get method" {
                Set-TargetResource @testParams 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
                Assert-MockCalled Set-SPWorkManagementServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

        }

        Context -Name "When a service application exists and is configured correctly" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Work Management Service Application"
                    DisplayName = $testParamsComplete.Name
                    ApplicationPool = @{ Name = $testParamsComplete.ApplicationPool }
                    AdminSettings = @{
                            MinimumTimeBetweenEwsSyncSubscriptionSearches =  (new-timespan -minutes 10)
                            MinimumTimeBetweenProviderRefreshes= (new-timespan -minutes 10)
                            MinimumTimeBetweenSearchQueries= (new-timespan -minutes 10)
                            NumberOfSubscriptionSyncsPerEwsSyncRun=10
                            NumberOfUsersEwsSyncWillProcessAtOnce=  10
                            NumberOfUsersPerEwsSyncBatch=  10
            
                    }

                })
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParamsComplete | Should Be $true
            }
        }

        Context -Name "When a service application exists and is not configured correctly" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Work Management Service Application"
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

                })
            }
            Mock -CommandName Set-SPWorkManagementServiceApplication { }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParamsComplete | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParamsComplete
                Assert-MockCalled Set-SPWorkManagementServiceApplication
                Assert-MockCalled Get-SPServiceApplication
            }
        }

    }
}
