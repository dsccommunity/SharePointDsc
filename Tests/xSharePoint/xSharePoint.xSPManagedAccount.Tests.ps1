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
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint")
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

        Context "Validate get method" {
            It "Calls the service application picker with the appropriate type name" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPManagedAccount" -and $Arguments.Identity -eq $testParams.Account.UserName }
                
                $results = Get-TargetResource @testParams

                Assert-VerifiableMocks
            }
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
                        EmailNotification = $testParams.EmailNotification
                        PreExpireDays = $testParams.PreExpireDays
                        Schedule = $testParams.Schedule
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the account exists and the schedule doesnt match" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        AccountName = $testParams.AccountName
                        EmailNotification = $testParams.EmailNotification
                        PreExpireDays = $testParams.PreExpireDays
                        Schedule = "Weekly Friday between 01:00 and 02:00"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
            It "Fails when the account exists and the email settings dont match" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        AccountName = $testParams.AccountName
                        EmailNotification = 0
                        PreExpireDays = 0
                        Schedule = $testParams.Schedule
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Creates a new account when none exists" {
                Mock Get-TargetResource { return @{} }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPManagedAccount" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Set-SPManagedAccount" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
            It "Modifies an existing account where it already exists" {
                Mock Get-TargetResource { return @{}
                    AccountName = $testParams.Account.UserName
                    Schedule = $testParams.Schedule
                }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Set-SPManagedAccount" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}