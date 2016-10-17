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
        $getTypeFullName = "Microsoft.Office.Server.WorkManagement.WorkManagementServiceApplication"

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc") 

        Mock Invoke-SPDSCCommand {  
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope 
        } 
         
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue 
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Mock Remove-SPServiceApplication { }
        
        Context -Name "When a service application exists and Ensure equals 'absent'" {
            $testParamsAbsent = @{
                Name = "Test Work Management App"
                Ensure = "Absent"
            }
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                }
                $spServiceApp = $spServiceApp | Add-Member ScriptMethod GetType { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParamsAbsent | Should Be $false
            }

            It "Should call the remove service app cmdlet from the set method" {
                Set-TargetResource @testParamsAbsent
                Assert-MockCalled Remove-SPServiceApplication
            }
        }

        Context "When no service applications exist in the current farm" {
            Mock Get-SPServiceApplication { return $null }
            Mock New-SPWorkManagementServiceApplication { }
            Mock New-SPWorkManagementServiceApplicationProxy { }

            It "returns null from the Get method" {
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
        
        Context "When service applications exist in the current farm but the specific Work Management app does not" { 
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                }
                $spServiceApp | Add-Member ScriptMethod GetType { 
                    return @{ FullName = "Microsoft.Office.UnKnownWebServiceApplication" } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "When a service application exists and is configured correctly" {
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParamsComplete.ApplicationPool }
                    AdminSettings = @{
                            MinimumTimeBetweenEwsSyncSubscriptionSearches =  (new-timespan -minutes 10)
                            MinimumTimeBetweenProviderRefreshes= (new-timespan -minutes 10)
                            MinimumTimeBetweenSearchQueries= (new-timespan -minutes 10)
                            NumberOfSubscriptionSyncsPerEwsSyncRun=10
                            NumberOfUsersEwsSyncWillProcessAtOnce=  10
                            NumberOfUsersPerEwsSyncBatch=  10
                    }
                }
                $spServiceApp | Add-Member ScriptMethod GetType { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParamsComplete | Should Be $true
            }
        }

        Context "When a service application exists and is not configured correctly" {
            Mock Get-SPServiceApplication {
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
                $spServiceApp | Add-Member ScriptMethod GetType { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
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
