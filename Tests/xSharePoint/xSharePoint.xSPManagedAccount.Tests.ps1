[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPManagedAccount"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPManagedAccount" {
    InModuleScope $ModuleName {
        $testParams = @{
            Account = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            EmailNotification = 7
            PreExpireDays = 7
            Schedule = ""
            AccountName = "username"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue         
        Mock New-SPManagedAccount { }
        Mock Set-SPManagedAccount { }

        Context "The specified managed account does not exist in the farm" {
            Mock Get-SPManagedAccount { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty 
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new and set methods from the set function" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedAccount
                Assert-MockCalled Set-SPManagedAccount
            }
        }

        Context "The specified managed account exists but has an incorrect schedule" {
            Mock Get-SPManagedAccount { return @{
                Username = $testParams.AccountName
                DaysBeforeChangeToEmail = $testParams.EmailNotification
                DaysBeforeExpiryToChange = $testParams.PreExpireDays
                ChangeSchedule = "wrong schedule"
            }}

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the set methods from the set function" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPManagedAccount
            }
        }

        Context "The specified managed account exists but has incorrect notifcation settings" {
            Mock Get-SPManagedAccount { return @{
                Username = $testParams.AccountName
                DaysBeforeChangeToEmail = 0
                DaysBeforeExpiryToChange = 0
                ChangeSchedule = $testParams.Schedule
            }}

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "The specified managed account exists and is configured correctly" {
            Mock Get-SPManagedAccount { return @{
                Username = $testParams.AccountName
                DaysBeforeChangeToEmail = $testParams.EmailNotification
                DaysBeforeExpiryToChange = $testParams.PreExpireDays
                ChangeSchedule = $testParams.Schedule
            }}

            It "returns the current values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}