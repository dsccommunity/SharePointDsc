[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPWorkManagementServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWorkManagement" {
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

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")

        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
                Context "When a service application exists and Ensure equals 'absent'" {
            $testParamsAbsent = @{
                Name = "Test Work Management App"
                Ensure = "Absent"
            }
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Work Management Service Application"
                    DisplayName = $testParamsAbsent.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                })
            }
            Mock Remove-SPServiceApplication{ }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParamsAbsent | Should Be $false
            }

            It "calls the remove service app cmdlet from the set method" {
                Set-TargetResource @testParamsAbsent
                Assert-MockCalled Remove-SPServiceApplication
            }
        }

        Context "When no service applications exist in the current farm" {

            Mock Get-SPServiceApplication { return $null }
            Mock New-SPWorkManagementServiceApplication { }
            Mock Set-SPWorkManagementServiceApplication { }

            Mock New-SPWorkManagementServiceApplicationProxy { }
            It "returns null from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPWorkManagementServiceApplication 
            }
        }

        Context "When service applications exist in the current farm but the specific Work Management app does not" {
            Mock Set-SPWorkManagementServiceApplication { }
            Mock New-SPWorkManagementServiceApplication { }
            Mock New-SPWorkManagementServiceApplicationProxy { }
            $Global:GetSpServiceApplicationCalled=$false
            Mock Get-SPServiceApplication { 
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
            
        
            It "returns null from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "creates  new app from the Get method" {
                Set-TargetResource @testParams 
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
                Assert-MockCalled Set-SPWorkManagementServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

        }

        Context "When a service application exists and is configured correctly" {
            Mock Get-SPServiceApplication { 
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

            It "returns values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParamsComplete | Should Be $true
            }
        }

        Context "When a service application exists and is not configured correctly" {
            Mock Get-SPServiceApplication { 
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
            Mock Set-SPWorkManagementServiceApplication { }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParamsComplete | Should Be $false
            }

            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource @testParamsComplete
                Assert-MockCalled Set-SPWorkManagementServiceApplication
                Assert-MockCalled Get-SPServiceApplication
            }
        }

    }
}
