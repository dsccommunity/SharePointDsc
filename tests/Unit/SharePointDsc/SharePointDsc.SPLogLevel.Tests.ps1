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
$script:DSCResourceName = 'SPLogLevel'
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

                # Mocks for all contexts
                Mock -CommandName Set-SPLogLevel -MockWith { }

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
            Context -Name "Multiple Log Category Areas were specified for one item" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server", "Excel Services Application"
                                Name       = "*"
                                TraceLevel = "Medium"
                                EventLevel = "Information"
                            } -ClientOnly)
                        )
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).SPLogLevelSetting | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an error from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Exactly one log area, or the wildcard character '*' must be provided for each log item"
                }
            }

            Context -Name "Multiple Log Category Names were specified for one item" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePointServer"
                                Name       = "Database", "UserProfile"
                                TraceLevel = "Medium"
                                EventLevel = "Information"
                            } -ClientOnly)
                        )
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).SPLogLevelSetting | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an error from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Exactly one log name, or the wildcard character '*' must be provided for each log item"
                }
            }

            Context -Name "No desired Trace and Event levels were specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area = "SharePointServer"
                                Name = "Database"
                            } -ClientOnly)
                        )
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).SPLogLevelSetting | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an error from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "TraceLevel and / or EventLevel must be provided for each Area"
                }
            }

            Context -Name "An invalid Trace level was specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePointServer"
                                Name       = "Database"
                                TraceLevel = "detailed"
                                EventLevel = "Information"
                            } -ClientOnly)
                        )
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).SPLogLevelSetting | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an error from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "TraceLevel detailed is not valid, must specify exactly one of None,Unexpected,Monitorable,High,Medium,Verbose,VerboseEx, or Default"
                }
            }

            Context -Name "An invalid Event level was specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "Database"
                                TraceLevel = "Medium"
                                EventLevel = "detailed"
                            } -ClientOnly)
                        )
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).SPLogLevelSetting | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an error from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "EventLevel detailed is not valid, must specify exactly one of None,ErrorCritical,Error,Warning,Information,Verbose, or Default"
                }
            }

            Context -Name "Desired setting for log level items is the Default, and the current setting is the Default" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "Database"
                                TraceLevel = "Default"
                                EventLevel = "Default"
                            } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @{
                            Area                 = "SharePoint Server"
                            Name                 = "Database"
                            TraceSeverity        = "Medium"
                            EventSeverity        = "Information"
                            DefaultTraceSeverity = "Medium"
                            DefaultEventSeverity = "Information"
                        }
                    }
                }

                It "Should return 'Default' from the get method [TraceLevel]" {
                    (Get-TargetResource @testParams).SPLogLevelSetting.TraceLevel | Should -Be "Default"
                }

                It "Should return 'Default' from the get method [EventLevel]" {
                    (Get-TargetResource @testParams).SPLogLevelSetting.EventLevel | Should -Be "Default"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }

            }

            Context -Name "Desired setting for a log level item is the Default, and the current setting is not the Default" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "Database"
                                TraceLevel = "Default"
                                EventLevel = "Default"
                            } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @{
                            Area                 = "SharePoint Server"
                            Name                 = "Database"
                            TraceSeverity        = "Unexpected"
                            EventSeverity        = "Error"
                            DefaultTraceSeverity = "Medium"
                            DefaultEventSeverity = "Information"
                        }
                    }
                }

                It "Should return values from the get method [TraceLevel] and [EventLevel]" {
                    $result = Get-TargetResource @testParams
                    $result.SPLogLevelSetting.TraceLevel | Should -Be "Unexpected"
                    $result.SPLogLevelSetting.EventLevel | Should -Be "Error"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call Set-SPLogLevel for the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPLogLevel
                }
            }

            Context -Name "Desired setting for a log level item is a custom value, and the current setting matches" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "Database"
                                TraceLevel = "Unexpected"
                                EventLevel = "Error"
                            } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @{
                            Area                 = "SharePoint Server"
                            Name                 = "Database"
                            TraceSeverity        = "Unexpected"
                            EventSeverity        = "Error"
                            DefaultTraceSeverity = "Medium"
                            DefaultEventSeverity = "Information"
                        }
                    }
                }

                It "Should return values from the get method [TraceLevel] and [EventLevel]" {
                    $result = Get-TargetResource @testParams
                    $result.SPLogLevelSetting.TraceLevel | Should -Be "Unexpected"
                    $result.SPLogLevelSetting.EventLevel | Should -Be "Error"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }

            }

            Context -Name "Desired setting for a log level item is a custom value, and the current settings do not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "Database"
                                TraceLevel = "Unexpected"
                                EventLevel = "Error"
                            } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @{
                            Area                 = "SharePoint Server"
                            Name                 = "Database"
                            TraceSeverity        = "Medium"
                            EventSeverity        = "Information"
                            DefaultTraceSeverity = "Medium"
                            DefaultEventSeverity = "Information"
                        }
                    }
                }

                It "Should return values from the get method [TraceLevel] and [EventLevel]" {
                    $result = Get-TargetResource @testParams
                    $result.SPLogLevelSetting.TraceLevel | Should -Be "Medium"
                    $result.SPLogLevelSetting.EventLevel | Should -Be "Information"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call Set-SPLogLevel for the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPLogLevel
                }
            }

            Context -Name "Desired settings for an entire Area is a custom value, and all current settings match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "*"
                                TraceLevel = "Medium"
                                EventLevel = "Information"
                            } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Database"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Audit"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "User Profile"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    }
                }

                It "Should return values from the get method [TraceLevel] and [EventLevel]" {
                    $result = Get-TargetResource @testParams
                    $result.SPLogLevelSetting.TraceLevel | Should -Be @("Medium", "Medium", "Medium")
                    $result.SPLogLevelSetting.EventLevel | Should -Be @("Information", "Information", "Information")
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Desired settings for an entire Area is a custom value, but one category within the area does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "*"
                                TraceLevel = "Medium"
                                EventLevel = "Information"
                            } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Database"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Audit"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "User Profile"
                                TraceSeverity        = "Verbose"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    }
                }

                It "Should return values from the get method [TraceLevel] and [EventLevel]" {
                    $result = Get-TargetResource @testParams
                    $result.SPLogLevelSetting.TraceLevel | Should -Be @("Medium", "Medium", "Verbose")
                    $result.SPLogLevelSetting.EventLevel | Should -Be @("Information", "Information", "Information")
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call Set-SPLogLevel for the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPLogLevel
                }

            }

            Context -Name "Desired settings for all areas is the Default, and the current settings match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "*"
                                Name       = "*"
                                TraceLevel = "Default"
                                EventLevel = "Default"
                            } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "Access Services"
                                Name                 = "Administration"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "Access Services"
                                Name                 = "Application Design"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "Business Connectivity Services"
                                Name                 = "Business Data"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Database"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Audit"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "User Profile"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    }
                }

                It "Should return values from the get method [TraceLevel] and [EventLevel]" {
                    $result = Get-TargetResource @testParams
                    $result.SPLogLevelSetting.TraceLevel | Should -Be @("Default", "Default", "Default", "Default", "Default", "Default")
                    $result.SPLogLevelSetting.EventLevel | Should -Be @("Default", "Default", "Default", "Default", "Default", "Default")
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Desired settings for all areas is a custom value, and the current settings do not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "*"
                                Name       = "*"
                                TraceLevel = "Medium"
                                EventLevel = "Verbose"
                            } -ClientOnly)
                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "Access Services"
                                Name                 = "Administration"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "Access Services"
                                Name                 = "Application Design"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "Business Connectivity Services"
                                Name                 = "Business Data"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Database"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Audit"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            },
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "User Profile"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    }
                }

                It "Should return values from the get method [TraceLevel] and [EventLevel]" {
                    $result = Get-TargetResource @testParams
                    $result.SPLogLevelSetting.TraceLevel | Should -Be @("Medium", "Medium", "Medium", "Medium", "Medium", "Medium")
                    $result.SPLogLevelSetting.EventLevel | Should -Be @("Information", "Information", "Information", "Information", "Information", "Information")
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call Set-SPLogLevel for the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPLogLevel
                }
            }

            Context -Name "Collection input, Desired settings for all is a custom value, and the current settings do not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "Database"
                                TraceLevel = "Unexpected"
                                EventLevel = "Error"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "User Profile"
                                TraceLevel = "None"
                                EventLevel = "Warning"
                            } -ClientOnly)

                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Database"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    } -ParameterFilter { $Identity -eq "SharePoint Server:Database" }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "User Profile"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    } -ParameterFilter { $Identity -eq "SharePoint Server:User Profile" }
                }

                It "Should return values from the get method [TraceLevel and EventLevel, first and second item]" {
                    $result = Get-TargetResource @testParams
                    ($result.SPLogLevelSetting)[0].TraceLevel | Should -Be "Medium"
                    ($result.SPLogLevelSetting)[0].EventLevel | Should -Be "Information"
                    ($result.SPLogLevelSetting)[1].TraceLevel | Should -Be "Medium"
                    ($result.SPLogLevelSetting)[1].EventLevel | Should -Be "Information"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call Set-SPLogLevel for the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPLogLevel
                }
            }

            Context -Name "Collection input, Desired settings for all is a custom value, and the current settings match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "Database"
                                TraceLevel = "Medium"
                                EventLevel = "Information"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "User Profile"
                                TraceLevel = "Medium"
                                EventLevel = "Information"
                            } -ClientOnly)

                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Database"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    } -ParameterFilter { $Identity -eq "SharePoint Server:Database" }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "User Profile"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    } -ParameterFilter { $Identity -eq "SharePoint Server:User Profile" }
                }

                It "Should return values from the get method [TraceLevel and EventLevel, first and second item]" {
                    $result = Get-TargetResource @testParams
                    ($result.SPLogLevelSetting)[0].TraceLevel | Should -Be "Medium"
                    ($result.SPLogLevelSetting)[0].EventLevel | Should -Be "Information"
                    ($result.SPLogLevelSetting)[1].TraceLevel | Should -Be "Medium"
                    ($result.SPLogLevelSetting)[1].EventLevel | Should -Be "Information"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Collection input, Desired settings for all is Default value, and the current settings match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "Database"
                                TraceLevel = "Default"
                                EventLevel = "Default"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "User Profile"
                                TraceLevel = "Default"
                                EventLevel = "Default"
                            } -ClientOnly)

                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Database"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    } -ParameterFilter { $Identity -eq "SharePoint Server:Database" }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "User Profile"
                                TraceSeverity        = "Medium"
                                EventSeverity        = "Information"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    } -ParameterFilter { $Identity -eq "SharePoint Server:User Profile" }
                }

                It "Should return Default from the get method [TraceLevel and EventLevel, first and second item]" {
                    $result = Get-TargetResource @testParams
                    ($result.SPLogLevelSetting)[0].TraceLevel | Should -Be "Default"
                    ($result.SPLogLevelSetting)[0].EventLevel | Should -Be "Default"
                    ($result.SPLogLevelSetting)[1].TraceLevel | Should -Be "Default"
                    ($result.SPLogLevelSetting)[1].EventLevel | Should -Be "Default"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Collection input, Desired settings for all is the Default, and the current settings do not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "My LogLevel Settings"
                        SPLogLevelSetting = @(
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "Database"
                                TraceLevel = "Default"
                                EventLevel = "Default"
                            } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                                Area       = "SharePoint Server"
                                Name       = "User Profile"
                                TraceLevel = "Default"
                                EventLevel = "Default"
                            } -ClientOnly)

                        )
                    }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "Database"
                                TraceSeverity        = "Verbose"
                                EventSeverity        = "Warning"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    } -ParameterFilter { $Identity -eq "SharePoint Server:Database" }

                    Mock -CommandName Get-SPLogLevel -MockWith {
                        return @(
                            @{
                                Area                 = "SharePoint Server"
                                Name                 = "User Profile"
                                TraceSeverity        = "Verbose"
                                EventSeverity        = "Warning"
                                DefaultTraceSeverity = "Medium"
                                DefaultEventSeverity = "Information"
                            }
                        )
                    } -ParameterFilter { $Identity -eq "SharePoint Server:User Profile" }
                }

                It "Should return Default from the get method [TraceLevel and EventLevel, first and second item]" {
                    $result = Get-TargetResource @testParams
                    ($result.SPLogLevelSetting)[0].TraceLevel | Should -Be "Verbose"
                    ($result.SPLogLevelSetting)[0].EventLevel | Should -Be "Warning"
                    ($result.SPLogLevelSetting)[1].TraceLevel | Should -Be "Verbose"
                    ($result.SPLogLevelSetting)[1].EventLevel | Should -Be "Warning"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call Set-SPLogLevel for the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPLogLevel
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        $CurrentLogLevelSettings = @()
                        $CurrentLogLevelSettings += New-Object -TypeName PSObject -Property @{
                            Area       = "Access Services"
                            Name       = "Administration"
                            TraceLevel = "Default"
                            EventLevel = "Default"
                        }
                        $CurrentLogLevelSettings += New-Object -TypeName PSObject -Property @{
                            Area       = "SharePoint Server"
                            Name       = "General"
                            TraceLevel = "Default"
                            EventLevel = "Default"
                        }

                        return @{
                            Name              = "Export"
                            SPLogLevelSetting = $CurrentLogLevelSettings
                        }
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    if ($null -eq (Get-Variable -Name 'DynamicCompilation' -ErrorAction SilentlyContinue))
                    {
                        $DynamicCompilation = $false
                    }

                    if ($null -eq (Get-Variable -Name 'StandAlone' -ErrorAction SilentlyContinue))
                    {
                        $StandAlone = $true
                    }

                    if ($null -eq (Get-Variable -Name 'ExtractionModeValue' -ErrorAction SilentlyContinue))
                    {
                        $Global:ExtractionModeValue = 2
                        $Global:ComponentsToExtract = @('SPFarm')
                    }

                    $result = @'
        SPLogLevel AllLogLevels
        {
            Name                 = "Export";
            PsDscRunAsCredential = $Credsspfarm;
            SPLogLevelSetting    = @(
                MSFT_SPLogLevelItem {TraceLevel="Default"; Name="Administration"; EventLevel="Default"; Area="Access Services"},
                MSFT_SPLogLevelItem {TraceLevel="Default"; Name="General"; EventLevel="Default"; Area="SharePoint Server"}
            );
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Be $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
