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
$script:DSCResourceName = 'SPMinRoleCompliance'
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

            # Mocks for all contexts
            Mock -CommandName Start-SPServiceInstance -MockWith { }
            Mock -CommandName Stop-SPServiceInstance -MockWith { }
            Mock -CommandName Get-SPDscRoleTestMethod -MockWith {
                $obj = New-Object -TypeName System.Object
                $obj = $obj | Add-Member -MemberType ScriptMethod `
                    -Name Invoke `
                    -Value {
                    return $global:SPDscIsRoleCompliant
                } -PassThru -Force
                return $obj
            }

            # Test contexts
            switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15
                {
                    Context -Name "All methods throw exceptions as MinRole doesn't exist in 2013" -Fixture {
                        It "Should throw on the get method" {
                            { Get-TargetResource @testParams } | Should -Throw
                        }

                        It "Should throw on the test method" {
                            { Test-TargetResource @testParams } | Should -Throw
                        }

                        It "Should throw on the set method" {
                            { Set-TargetResource @testParams } | Should -Throw
                        }
                    }
                }
                16
                {
                    Context -Name "The farm is not compliant as services aren't running but should be" -Fixture {
                        $testParams = @{
                            IsSingleInstance = "Yes"
                            State            = "Compliant"
                        }

                        Mock -CommandName Get-SPService -MockWith {
                            return @(
                                @{
                                    CompliantWithMinRole = $true
                                    Instances            = @(
                                        @{
                                            Id       = (New-Guid)
                                            Status   = "Disabled"
                                            TypeName = "Dummy service 1"
                                            Server   = @{
                                                Name = "ServerName"
                                            }
                                        }
                                    )
                                }
                                @{
                                    CompliantWithMinRole = $false
                                    Instances            = @(
                                        @{
                                            Id       = (New-Guid)
                                            Status   = "Disabled"
                                            TypeName = "Dummy service 2"
                                            Server   = @{
                                                Name = "ServerName"
                                            }
                                        }
                                    )
                                }
                            )
                        }

                        $global:SPDscIsRoleCompliant = $false

                        It "should return NonCompliant in the get method" {
                            (Get-TargetResource @testParams).State | Should -Be "NonCompliant"
                        }

                        It "should return false in the test method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "should start the service in the set method" {
                            Set-TargetResource @testParams
                            Assert-MockCalled -CommandName "Start-SPServiceInstance" -Times 1
                            Assert-MockCalled -CommandName "Stop-SPServiceInstance" -Times 0
                        }
                    }

                    Context -Name "The farm is not compliant as services are running that shouldn't be" -Fixture {
                        $testParams = @{
                            IsSingleInstance = "Yes"
                            State            = "Compliant"
                        }

                        Mock -CommandName Get-SPService -MockWith {
                            return @(
                                @{
                                    CompliantWithMinRole = $false
                                    Instances            = @(
                                        @{
                                            Id       = (New-Guid)
                                            Status   = "Online"
                                            TypeName = "Dummy service 1"
                                            Server   = @{
                                                Name = "ServerName"
                                            }
                                        }
                                    )
                                }
                                @{
                                    CompliantWithMinRole = $true
                                    Instances            = @(
                                        @{
                                            Id       = (New-Guid)
                                            Status   = "Online"
                                            TypeName = "Dummy service 2"
                                            Server   = @{
                                                Name = "ServerName"
                                            }
                                        }
                                    )
                                }
                            )
                        }

                        $global:SPDscIsRoleCompliant = $false

                        It "should return NonCompliant in the get method" {
                            (Get-TargetResource @testParams).State | Should -Be "NonCompliant"
                        }

                        It "should return false in the test method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "should start the service in the set method" {
                            Set-TargetResource @testParams
                            Assert-MockCalled -CommandName "Start-SPServiceInstance" -Times 0
                            Assert-MockCalled -CommandName "Stop-SPServiceInstance" -Times 1
                        }
                    }

                    Context -Name "The farm is compliant and should be" -Fixture {
                        $testParams = @{
                            IsSingleInstance = "Yes"
                            State            = "Compliant"
                        }

                        $testParams = @{
                            IsSingleInstance = "Yes"
                            State            = "Compliant"
                        }

                        Mock -CommandName Get-SPService -MockWith {
                            return @(
                                @{
                                    CompliantWithMinRole = $true
                                    Instances            = @(
                                        @{
                                            Id       = (New-Guid)
                                            Status   = "Disabled"
                                            TypeName = "Dummy service 1"
                                            Server   = @{
                                                Name = "ServerName"
                                            }
                                        }
                                    )
                                }
                                @{
                                    CompliantWithMinRole = $true
                                    Instances            = @(
                                        @{
                                            Id       = (New-Guid)
                                            Status   = "Disabled"
                                            TypeName = "Dummy service 2"
                                            Server   = @{
                                                Name = "ServerName"
                                            }
                                        }
                                    )
                                }
                            )
                        }

                        $global:SPDscIsRoleCompliant = $true

                        It "should return NonCompliant in the get method" {
                            (Get-TargetResource @testParams).State | Should -Be "Compliant"
                        }

                        It "should return false in the test method" {
                            Test-TargetResource @testParams | Should -Be $true
                        }
                    }

                    Context -Name "NonCompliant is requested in any function" -Fixture {
                        $testParams = @{
                            IsSingleInstance = "Yes"
                            State            = "NonCompliant"
                        }

                        It "Should throw on the test method" {
                            { Test-TargetResource @testParams } | Should -Throw
                        }

                        It "Should throw on the set method" {
                            { Set-TargetResource @testParams } | Should -Throw
                        }
                    }
                }
                Default
                {
                    throw [Exception] "A supported version of SharePoint was not used in testing"
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
