[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPPasswordChangeSettings'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
        InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
            Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

            # Test contexts
            Context -Name "No local SharePoint farm is available" {
                $testParams = @{
                    IsSingleInstance              = "Yes"
                    MailAddress                   = "e@mail.com"
                    DaysBeforeExpiry              = 7
                    PasswordChangeWaitTimeSeconds = 60
                }

                Mock -CommandName Get-SPFarm -MockWith {
                    return $null
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).MailAddress | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }


            Context -Name "There is a local SharePoint farm and the properties are set correctly" {
                $testParams = @{
                    IsSingleInstance              = "Yes"
                    MailAddress                   = "e@mail.com"
                    DaysBeforeExpiry              = 7
                    PasswordChangeWaitTimeSeconds = 60
                }

                Mock -CommandName Get-SPFarm -MockWith {
                    return @{
                        PasswordChangeEmailAddress              = "e@mail.com"
                        DaysBeforePasswordExpirationToSendEmail = 7
                        PasswordChangeGuardTime                 = 60
                        PasswordChangeMaximumTries              = 3
                    }
                }

                It "Should return farm properties from the get method" {
                    (Get-TargetResource @testParams).MailAddress | Should -Be "e@mail.com"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "There is a local SharePoint farm and the properties are not set correctly" {
                $testParams = @{
                    IsSingleInstance              = "Yes"
                    MailAddress                   = "e@mail.com"
                    DaysBeforeExpiry              = 7
                    PasswordChangeWaitTimeSeconds = 60
                }

                Mock -CommandName Get-SPFarm -MockWith {
                    $result = @{
                        PasswordChangeEmailAddress              = ""
                        PasswordChangeGuardTime                 = 0
                        PasswordChangeMaximumTries              = 0
                        DaysBeforePasswordExpirationToSendEmail = 0
                    }
                    $result = $result | Add-Member  ScriptMethod Update {
                        $Global:SPDscFarmUpdateCalled = $true
                        return $true;

                    } -PassThru
                    return $result
                }

                It "Should return farm properties from the get method" {
                    (Get-TargetResource @testParams).MailAddress | Should -Be ""
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the new and set methods from the set function" {
                    $Global:SPDscFarmUpdateCalled = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPFarm
                    $Global:SPDscFarmUpdateCalled | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
