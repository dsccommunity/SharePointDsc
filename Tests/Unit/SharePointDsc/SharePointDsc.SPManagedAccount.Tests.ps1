[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
                                              -DscResource "SPManagedAccount"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @("username", $mockPassword)

        # Mocks for all contexts   
        Mock -CommandName New-SPManagedAccount -MockWith { }
        Mock -CommandName Set-SPManagedAccount -MockWith { }
        Mock -CommandName Remove-SPManagedAccount -MockWith { }

        # Test contexts
        Context -Name "The specified managed account does not exist in the farm and it should" -Fixture {
            $testParams = @{
                Account = $mockCredential
                EmailNotification = 7
                PreExpireDays = 7
                Schedule = ""
                Ensure = "Present"
                AccountName = $mockCredential.Username
            }

            Mock -CommandName Get-SPManagedAccount -MockWith { return $null }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the new and set methods from the set function" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedAccount
                Assert-MockCalled Set-SPManagedAccount
            }
        }

        Context -Name "The specified managed account exists and it should but has an incorrect schedule" -Fixture {
            $testParams = @{
                Account = $mockCredential
                EmailNotification = 7
                PreExpireDays = 7
                Schedule = ""
                Ensure = "Present"
                AccountName = $mockCredential.Username
            }
            
            Mock -CommandName Get-SPManagedAccount -MockWith { 
                return @{
                    Username = $testParams.AccountName
                    DaysBeforeChangeToEmail = $testParams.EmailNotification
                    DaysBeforeExpiryToChange = $testParams.PreExpireDays
                    ChangeSchedule = "wrong schedule"
                }
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the set methods from the set function" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPManagedAccount
            }
        }

        Context -Name "The specified managed account exists and it should but has incorrect notifcation settings" -Fixture {
            $testParams = @{
                Account = $mockCredential
                EmailNotification = 7
                PreExpireDays = 7
                Schedule = ""
                Ensure = "Present"
                AccountName = $mockCredential.Username
            }
            
            Mock -CommandName Get-SPManagedAccount -MockWith { 
                return @{
                    Username = $testParams.AccountName
                    DaysBeforeChangeToEmail = 0
                    DaysBeforeExpiryToChange = 0
                    ChangeSchedule = $testParams.Schedule
                }
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "The specified managed account exists and it should and is also configured correctly" -Fixture {
            $testParams = @{
                Account = $mockCredential
                EmailNotification = 7
                PreExpireDays = 7
                Schedule = ""
                Ensure = "Present"
                AccountName = $mockCredential.Username
            }
            
            Mock -CommandName Get-SPManagedAccount -MockWith { 
                return @{
                    Username = $testParams.AccountName
                    DaysBeforeChangeToEmail = $testParams.EmailNotification
                    DaysBeforeExpiryToChange = $testParams.PreExpireDays
                    ChangeSchedule = $testParams.Schedule
                }
            }

            It "Should return the current values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "The specified account should exist but the account property has not been specified" -Fixture {
            $testParams = @{
                EmailNotification = 7
                PreExpireDays = 7
                Schedule = ""
                Ensure = "Present"
                AccountName = "username"
            }
            
            Mock -CommandName Get-SPManagedAccount -MockWith { 
                return @{
                    Username = $testParams.AccountName
                    DaysBeforeChangeToEmail = $testParams.EmailNotification
                    DaysBeforeExpiryToChange = $testParams.PreExpireDays
                    ChangeSchedule = $testParams.Schedule
                }
            }
            
            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
            
        Context -Name "The specified account exists but it should not" -Fixture {
            $testParams = @{
                Ensure = "Absent"
                AccountName = "username"
            }

            Mock -CommandName Get-SPManagedAccount -MockWith { 
                return @{
                    Username = $testParams.AccountName
                    DaysBeforeChangeToEmail = $testParams.EmailNotification
                    DaysBeforeExpiryToChange = $testParams.PreExpireDays
                    ChangeSchedule = $testParams.Schedule
                }
            }
            
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should call the remove cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPManagedAccount
            }
        }
        
        Context -Name "The specified account does not exist and it should not" -Fixture {
            $testParams = @{
                Ensure = "Absent"
                AccountName = "username"
            }

            Mock -CommandName Get-SPManagedAccount -MockWith { 
                return $null 
            }
            
            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
