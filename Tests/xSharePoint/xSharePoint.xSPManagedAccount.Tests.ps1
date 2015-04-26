[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPManagedAccount"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPManagedAccount" {
    InModuleScope $ModuleName {
        $testParams = @{
            Account = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            EmailNotification = 7
            PreExpireDays = 7
            Schedule = ""
            AccountName = "username"
        }

        Context "Validate test method" {
            It "Fails when managed account does not exist in the farm" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the account exists and has correct settings" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        AccountName = $testParams.AccountName
                        AutomaticChange = $false
                        DaysBeforeChangeToEmail = $testParams.EmailNotification
                        DaysBeforeExpiryToChange = $testParams.PreExpireDays
                        ChangeSchedule = $testParams.Schedule
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the account exists and the schedule doesnt match" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        AccountName = $testParams.AccountName
                        AutomaticChange = $true
                        DaysBeforeChangeToEmail = $testParams.EmailNotification
                        DaysBeforeExpiryToChange = $testParams.PreExpireDays
                        ChangeSchedule = "Weekly Friday between 01:00 and 02:00"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
            It "Fails when the account exists and the email settings dont match" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        AccountName = $testParams.AccountName
                        AutomaticChange = $true
                        DaysBeforeChangeToEmail = 0
                        DaysBeforeExpiryToChange = 0
                        ChangeSchedule = $testParams.Schedule
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }    
}