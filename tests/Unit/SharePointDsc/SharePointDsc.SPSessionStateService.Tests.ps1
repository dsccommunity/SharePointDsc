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
$script:DSCResourceName = 'SPSessionStateService'
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
            -DscResource $script:DSCResourceName `
            -ModuleVersion $moduleVersionFolder
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

Invoke-TestSetup -ModuleVersion $moduleVersion

try
{
    Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
        InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
            Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

            # Mocks for all contexts
            Mock -CommandName Set-SPSessionStateService -MockWith { return @{ } }
            Mock -CommandName Enable-SPSessionStateService -MockWith { return @{ } }
            Mock -CommandName Disable-SPSessionStateService -MockWith { return @{ } }

            # Test contexts
            Context -Name "the service isn't enabled but should be" -Fixture {
                $testParams = @{
                    DatabaseName   = "SP_StateService"
                    DatabaseServer = "SQL.test.domain"
                    Ensure         = "Present"
                    SessionTimeout = 60
                }

                Mock -CommandName Get-SPSessionStateService -MockWith {
                    return @{
                        SessionStateEnabled = $false
                        Timeout             = @{
                            TotalMinutes = 60
                        }
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should enable the session service from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Enable-SPSessionStateService
                }
            }

            Context -Name "the service is enabled and should be" -Fixture {
                $testParams = @{
                    DatabaseName   = "SP_StateService"
                    DatabaseServer = "SQL.test.domain"
                    Ensure         = "Present"
                    SessionTimeout = 60
                }

                Mock -CommandName Get-SPSessionStateService -MockWith {
                    return @{
                        SessionStateEnabled = $true
                        Timeout             = @{
                            TotalMinutes = 60
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "the timeout should be set to 90 seconds but is 60" -Fixture {
                $testParams = @{
                    DatabaseName   = "SP_StateService"
                    DatabaseServer = "SQL.test.domain"
                    Ensure         = "Present"
                    SessionTimeout = 90
                }

                Mock -CommandName Get-SPSessionStateService -MockWith {
                    return @{
                        SessionStateEnabled = $true
                        Timeout             = @{
                            TotalMinutes = 60
                        }
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be "Present"
                    $result.SessionTimeout | Should Be 60
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should update session timeout to 90 seconds" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Set-SPSessionStateService
                }
            }

            Context -Name "the service is enabled but shouldn't be" -Fixture {
                $testParams = @{
                    DatabaseName   = "SP_StateService"
                    DatabaseServer = "SQL.test.domain"
                    Ensure         = "Absent"
                }

                Mock -CommandName Get-SPSessionStateService -MockWith {
                    return @{
                        SessionStateEnabled = $true
                        Timeout             = @{
                            TotalMinutes = 60
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "disable the session service from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Disable-SPSessionStateService
                }
            }

            Context -Name "the service is disabled and should be" -Fixture {
                $testParams = @{
                    DatabaseName   = "SP_StateService"
                    DatabaseServer = "SQL.test.domain"
                    Ensure         = "Absent"
                }

                Mock -CommandName Get-SPSessionStateService -MockWith {
                    return @{
                        SessionStateEnabled = $false
                        Timeout             = @{
                            TotalMinutes = 60
                        }
                    }
                }

                It "Should return enabled from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
