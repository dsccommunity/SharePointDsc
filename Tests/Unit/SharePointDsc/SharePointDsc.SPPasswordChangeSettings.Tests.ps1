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
                                              -DscResource "SPPasswordChangeSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Test contexts
        Context -Name "No local SharePoint farm is available" {
            $testParams = @{
                MailAddress = "e@mail.com"
                DaysBeforeExpiry = 7
                PasswordChangeWaitTimeSeconds = 60
            }

            Mock -CommandName Get-SPFarm -MockWith { 
                return $null 
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty 
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }
        }


        Context -Name "There is a local SharePoint farm and the properties are set correctly" {
            $testParams = @{
                MailAddress = "e@mail.com"
                DaysBeforeExpiry = 7
                PasswordChangeWaitTimeSeconds = 60
            }
            
            Mock -CommandName Get-SPFarm -MockWith { 
                return @{
                    PasswordChangeEmailAddress = "e@mail.com"
                    DaysBeforePasswordExpirationToSendEmail = 7
                    PasswordChangeGuardTime = 60
                    PasswordChangeMaximumTries = 3
                }
            }
            
            It "Should return farm properties from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "There is a local SharePoint farm and the properties are not set correctly" {
            $testParams = @{
                MailAddress = "e@mail.com"
                DaysBeforeExpiry = 7
                PasswordChangeWaitTimeSeconds = 60
            }
            
            Mock -CommandName Get-SPFarm -MockWith { 
                $result = @{
                    PasswordChangeEmailAddress = ""
                    PasswordChangeGuardTime = 0
                    PasswordChangeMaximumTries = 0
                    DaysBeforePasswordExpirationToSendEmail = 0
                }
                $result = $result | Add-Member  ScriptMethod Update { 
                    $Global:SPDscFarmUpdateCalled = $true
                    return $true;
                
                    } -PassThru
                return $result
            }

            It "Should return farm properties from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the new and set methods from the set function" {
                $Global:SPDscFarmUpdateCalled = $false
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPFarm
                $Global:SPDscFarmUpdateCalled  | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
