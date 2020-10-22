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
$script:DSCResourceName = 'SPTimerJobState'
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
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Initialize tests

                # Mocks for all contexts
                Mock -CommandName Set-SPTimerJob -MockWith {
                    return $null
                }
                Mock -CommandName Enable-SPTimerJob -MockWith {
                    return $null
                }
                Mock -CommandName Get-SPFarm -MockWith {
                    return @{ }
                }
                Mock -CommandName Get-SPWebApplication -MockWith {
                    return @{ }
                }

                function Add-SPDscEvent
                {
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType,

                        [Parameter()]
                        [System.UInt32]
                        $EventID
                    )
                }
            }

            # Test contexts
            Context -Name "The server is not part of SharePoint farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "N/A"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw "Unable to detect local farm"
                    }
                }

                It "Should return null from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }

                It "Should return false from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }
            }

            Context -Name "The specified web application is not found" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "http://sharepoint.domain.com"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return $null
                    }
                }

                It "Should return null from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Specified web application not found!"
                }

                It "Should return false from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Specified web application not found!"
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified web application not found!"
                }
            }

            Context -Name "No timer jobs found for the specified web application" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "http://sharepoint.domain.com"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPTimerJob -MockWith {
                        return $null
                    }
                }

                It "Should return null from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "No timer jobs found. Please check the input values"
                }

                It "Should return false from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "No timer jobs found. Please check the input values"
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "No timer jobs found. Please check the input values"
                }
            }

            Context -Name "The server is in a farm and the incorrect enabled settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "N/A"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPTimerJob -MockWith {
                        $returnVal = @{
                            TypeName   = "job-spapp-statequery"
                            IsDisabled = $true
                            Schedule   = "hourly between 0 and 59"
                        }
                        return , @($returnVal)
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the timerjob settings" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Enable-SPTimerJob
                }
            }

            Context -Name "The server is in a farm and the incorrect enabled settings have been applied - WebApp" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "http://sharepoint.domain.com"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPTimerJob -MockWith {
                        $returnVal = @{
                            TypeName   = "job-spapp-statequery"
                            IsDisabled = $true
                            Schedule   = "hourly between 0 and 59"
                        }
                        return , @($returnVal)
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the timerjob settings" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Enable-SPTimerJob
                }
            }

            Context -Name "The server is in a farm and the incorrect schedule settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "N/A"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPTimerJob -MockWith {
                        $returnVal = @{
                            TypeName   = "job-spapp-statequery"
                            IsDisabled = $false
                            Schedule   = "weekly at sat 23:00:00"
                        }
                        return , @($returnVal)
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the timer job settings" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPTimerJob
                }
            }

            Context -Name "The server is in a farm and the incorrect schedule settings have been applied - WebApp" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "http://sharepoint.domain.com"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPTimerJob -MockWith {
                        $returnVal = @{
                            TypeName   = "job-spapp-statequery"
                            IsDisabled = $false
                            Schedule   = "weekly at sat 23:00:00"
                        }
                        return , @($returnVal)
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the timer job settings" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPTimerJob
                }
            }

            Context -Name "The server is in a farm and the incorrect schedule format has been used" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "N/A"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPTimerJob -MockWith {
                        $returnVal = @{
                            TypeName   = "job-spapp-statequery"
                            IsDisabled = $false
                            Schedule   = "incorrect format"
                        }
                        return , @($returnVal)
                    }

                    Mock -CommandName Set-SPTimerJob -MockWith {
                        throw "Invalid Time: `"The time given was not given in the proper format. See: Get-Help Set-SPTimerJob -detailed`""
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception because the incorrect schedule format is used" {
                    { Set-TargetResource @testParams } | Should -Throw "Incorrect schedule format used. New schedule will not be applied."
                }
            }

            Context -Name "The server is in a farm and the incorrect schedule format has been used - WebApp" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "http://sharepoint.domain.com"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPTimerJob -MockWith {
                        $returnVal = @{
                            TypeName   = "job-spapp-statequery"
                            IsDisabled = $false
                            Schedule   = "incorrect format"
                        }
                        return , @($returnVal)
                    }

                    Mock -CommandName Set-SPTimerJob -MockWith {
                        throw "Invalid Time: `"The time given was not given in the proper format. See: Get-Help Set-SPTimerJob -detailed`""
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception because the incorrect schedule format is used" {
                    { Set-TargetResource @testParams } | Should -Throw "Incorrect schedule format used. New schedule will not be applied."
                }
            }

            Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "N/A"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPTimerJob -MockWith {
                        $returnVal = @{
                            TypeName   = "job-spapp-statequery"
                            IsDisabled = $false
                            Schedule   = "hourly between 0 and 59"
                        }
                        return , @($returnVal)
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The server is in a farm and the correct settings have been applied - WebApp" -Fixture {
                BeforeAll {
                    $testParams = @{
                        TypeName  = "job-spapp-statequery"
                        WebAppUrl = "http://sharepoint.domain.com"
                        Enabled   = $true
                        Schedule  = "hourly between 0 and 59"
                    }

                    Mock -CommandName Get-SPTimerJob -MockWith {
                        $returnVal = @{
                            TypeName   = "job-spapp-statequery"
                            IsDisabled = $false
                            Schedule   = "hourly between 0 and 59"
                        }
                        return , @($returnVal)
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
