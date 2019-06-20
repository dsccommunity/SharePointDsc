[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPLogLevel"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts
        Mock -CommandName Set-SPLogLevel -MockWith { }

        # Test contexts
        Context -Name "Multiple Log Category Areas were specified for one item" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server","Excel Services Application"
                        Name    = "*"
                        TraceLevel = "Medium"
                        EventLevel = "Information"
                    } -ClientOnly)
                )
            }


            It "Should return null from the get method" {
                (Get-TargetResource @testParams).SPLogLevelSetting | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an error from the set method" {
                { Set-TargetResource @testParams } | Should throw "Exactly one log area, or the wildcard character '*' must be provided for each log item"
            }
        }

        Context -Name "Multiple Log Category Names were specified for one item" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePointServer"
                        Name    = "Database","UserProfile"
                        TraceLevel = "Medium"
                        EventLevel = "Information"
                    } -ClientOnly)
                )
            }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).SPLogLevelSetting | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an error from the set method" {
                { Set-TargetResource @testParams } | Should throw "Exactly one log name, or the wildcard character '*' must be provided for each log item"
            }
        }

        Context -Name "No desired Trace and Event levels were specified" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePointServer"
                        Name    = "Database"
                    } -ClientOnly)
                )
            }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).SPLogLevelSetting | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an error from the set method" {
                { Set-TargetResource @testParams } | Should throw "TraceLevel and / or EventLevel must be provided for each Area"
            }
        }

        Context -Name "An invalid Trace level was specified" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePointServer"
                        Name    = "Database"
                        TraceLevel = "detailed"
                        EventLevel = "Information"
                    } -ClientOnly)
                )
            }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).SPLogLevelSetting | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an error from the set method" {
                { Set-TargetResource @testParams } | Should throw "TraceLevel detailed is not valid, must specify exactly one of None,Unexpected,Monitorable,High,Medium,Verbose,VerboseEx, or Default"
            }
        }

        Context -Name "An invalid Event level was specified" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "Database"
                        TraceLevel = "Medium"
                        EventLevel = "detailed"
                    } -ClientOnly)
                )
            }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).SPLogLevelSetting | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an error from the set method" {
                { Set-TargetResource @testParams } | Should throw "EventLevel detailed is not valid, must specify exactly one of None,ErrorCritical,Error,Warning,Information,Verbose, or Default"
            }
        }

        Context -Name "Desired setting for log level items is the Default, and the current setting is the Default" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "Database"
                        TraceLevel = "Default"
                        EventLevel = "Default"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @{
                        Area = "SharePoint Server"
                        Name = "Database"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
            }

            It "Should return 'Default' from the get method [TraceLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.TraceLevel | Should Be "Default"
            }

            It "Should return 'Default' from the get method [EventLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.EventLevel | Should Be "Default"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        }

        Context -Name "Desired setting for a log level item is the Default, and the current setting is not the Default" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "Database"
                        TraceLevel = "Default"
                        EventLevel = "Default"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @{
                        Area = "SharePoint Server"
                        Name = "Database"
                        TraceSeverity = "Unexpected"
                        EventSeverity = "Error"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
            }

            It "Should return values from the get method [TraceLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.TraceLevel | Should Be "Unexpected"
            }

            It "Should return values from the get method [EventLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.EventLevel | Should Be "Error"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call Set-SPLogLevel for the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPLogLevel
            }
        }

        Context -Name "Desired setting for a log level item is a custom value, and the current setting matches" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "Database"
                        TraceLevel = "Unexpected"
                        EventLevel = "Error"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @{
                        Area = "SharePoint Server"
                        Name = "Database"
                        TraceSeverity = "Unexpected"
                        EventSeverity = "Error"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
            }

            It "Should return values from the get method [TraceLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.TraceLevel | Should Be "Unexpected"
            }

            It "Should return values from the get method [EventLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.EventLevel | Should Be "Error"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        }

        Context -Name "Desired setting for a log level item is a custom value, and the current settings do not match" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "Database"
                        TraceLevel = "Unexpected"
                        EventLevel = "Error"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @{
                        Area = "SharePoint Server"
                        Name = "Database"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
            }

            It "Should return values from the get method [TraceLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.TraceLevel | Should Be "Medium"
            }

            It "Should return values from the get method [EventLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.EventLevel | Should Be "Information"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call Set-SPLogLevel for the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPLogLevel
            }
        }

        Context -Name "Desired settings for an entire Area is a custom value, and all current settings match" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "*"
                        TraceLevel = "Medium"
                        EventLevel = "Information"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @(
                    @{
                        Area = "SharePoint Server"
                        Name = "Database"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "Audit"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "User Profile"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
                )
            }

            It "Should return values from the get method [TraceLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.TraceLevel | Should Be "Medium"
            }

            It "Should return values from the get method [EventLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.EventLevel | Should Be "Information"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Desired settings for an entire Area is a custom value, but one category within the area does not match" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "*"
                        TraceLevel = "Medium"
                        EventLevel = "Information"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @(
                    @{
                        Area = "SharePoint Server"
                        Name = "Database"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "Audit"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "User Profile"
                        TraceSeverity = "Verbose"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
                )
            }

            It "Should return values from the get method [TraceLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.TraceLevel | Should Be "Medium,Verbose"
            }

            It "Should return values from the get method [EventLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.EventLevel | Should Be "Information"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call Set-SPLogLevel for the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPLogLevel
            }

        }

        Context -Name "Desired settings for all areas is the Default, and the current settings match" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "*"
                        Name    = "*"
                        TraceLevel = "Default"
                        EventLevel = "Default"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @(
                    @{
                        Area = "Access Services"
                        Name = "Administration"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "Access Services"
                        Name = "Application Design"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "Business Connectivity Services"
                        Name = "Business Data"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "Database"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "Audit"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "User Profile"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
                )
            }

            It "Should return values from the get method [TraceLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.TraceLevel | Should Be "Default"
            }

            It "Should return values from the get method [EventLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.EventLevel | Should Be "Default"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Desired settings for all areas is a custom value, and the current settings do not match" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "*"
                        Name    = "*"
                        TraceLevel = "Medium"
                        EventLevel = "Verbose"
                    } -ClientOnly)
                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @(
                    @{
                        Area = "Access Services"
                        Name = "Administration"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "Access Services"
                        Name = "Application Design"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "Business Connectivity Services"
                        Name = "Business Data"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "Database"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "Audit"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    },
                    @{
                        Area = "SharePoint Server"
                        Name = "User Profile"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
                )
            }

            It "Should return values from the get method [TraceLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.TraceLevel | Should Be "Medium"
            }

            It "Should return values from the get method [EventLevel]" {
                (Get-TargetResource @testParams).SPLogLevelSetting.EventLevel | Should Be "Information"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call Set-SPLogLevel for the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPLogLevel
            }
        }

        Context -Name "Collection input, Desired settings for all is a custom value, and the current settings do not match" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "Database"
                        TraceLevel = "Unexpected"
                        EventLevel = "Error"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "User Profile"
                        TraceLevel = "None"
                        EventLevel = "Warning"
                    } -ClientOnly)

                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @(
                    @{
                        Area = "placeholder"
                        Name = "placeholder"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
                )
            }

            It "Should return values from the get method [TraceLevel, first item]" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[0].TraceLevel | Should Be "Medium"
            }

            It "Should return values from the get method [EventLevel], first item" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[0].EventLevel | Should Be "Information"
            }

            It "Should return values from the get method [TraceLevel, second item]" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[1].TraceLevel | Should Be "Medium"
            }

            It "Should return values from the get method [EventLevel], second item" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[1].EventLevel | Should Be "Information"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call Set-SPLogLevel for the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPLogLevel
            }
        }

        Context -Name "Collection input, Desired settings for all is a custom value, and the current settings match" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "Database"
                        TraceLevel = "Medium"
                        EventLevel = "Information"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "User Profile"
                        TraceLevel = "Medium"
                        EventLevel = "Information"
                    } -ClientOnly)

                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @(
                    @{
                        Area = "placeholder"
                        Name = "placeholder"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
                )
            }

            It "Should return values from the get method [TraceLevel, first item]" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[0].TraceLevel | Should Be "Medium"
            }

            It "Should return values from the get method [EventLevel], first item" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[0].EventLevel | Should Be "Information"
            }

            It "Should return values from the get method [TraceLevel, second item]" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[1].TraceLevel | Should Be "Medium"
            }

            It "Should return values from the get method [EventLevel], second item" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[1].EventLevel | Should Be "Information"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Collection input, Desired settings for all is Default value, and the current settings match" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "Database"
                        TraceLevel = "Default"
                        EventLevel = "Default"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "User Profile"
                        TraceLevel = "Default"
                        EventLevel = "Default"
                    } -ClientOnly)

                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @(
                    @{
                        Area = "placeholder"
                        Name = "placeholder"
                        TraceSeverity = "Medium"
                        EventSeverity = "Information"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
                )
            }

            It "Should return Default from the get method [TraceLevel, first item]" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[0].TraceLevel | Should Be "Default"
            }

            It "Should return Default from the get method [EventLevel], first item" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[0].EventLevel | Should Be "Default"
            }

            It "Should return Default from the get method [TraceLevel, second item]" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[1].TraceLevel | Should Be "Default"
            }

            It "Should return Default from the get method [EventLevel], second item" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[1].EventLevel | Should Be "Default"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Collection input, Desired settings for all is the Default, and the current settings do not match" -Fixture {
            $testParams = @{
                Name = "My LogLevel Settings"
                SPLogLevelSetting = @(
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "Database"
                        TraceLevel = "Default"
                        EventLevel = "Default"
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
                        Area           = "SharePoint Server"
                        Name    = "User Profile"
                        TraceLevel = "Default"
                        EventLevel = "Default"
                    } -ClientOnly)

                )
            }

            Mock -CommandName Get-SPLogLevel -MockWith {
                return @(
                    @{
                        Area = "placeholder"
                        Name = "placeholder"
                        TraceSeverity = "Verbose"
                        EventSeverity = "Warning"
                        DefaultTraceSeverity = "Medium"
                        DefaultEventSeverity = "Information"
                    }
                )
            }

            It "Should return values from the get method [TraceLevel, first item]" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[0].TraceLevel | Should Be "Verbose"
            }

            It "Should return values from the get method [EventLevel], first item" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[0].EventLevel | Should Be "Warning"
            }

            It "Should return values from the get method [TraceLevel, second item]" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[1].TraceLevel | Should Be "Verbose"
            }

            It "Should return values from the get method [EventLevel], second item" {
                ((Get-TargetResource @testParams).SPLogLevelSetting)[1].EventLevel | Should Be "Warning"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call Set-SPLogLevel for the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPLogLevel
            }
        }


    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
