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
$script:DSCResourceName = 'SPWebAppHttpThrottlingMonitor'
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
            Context -Name "Ensure=Present, but the HealthScoreBuckets parameter is not provided" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl    = 'http://sites.sharepoint.com'
                        Category     = 'Processor'
                        Counter      = '% Processor Time'
                        IsDescending = $false
                        Ensure       = 'Present'
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $webApp = @{
                            DisplayName = 'Sites'
                        }
                        return $webApp
                    }

                    Mock -CommandName Get-SPWebApplicationHttpThrottlingMonitor -MockWith {
                        $associatedHealthScoreCalculator = @{}
                        $associatedHealthScoreCalculator = $associatedHealthScoreCalculator | Add-Member -MemberType ScriptMethod -Name GetScoreBuckets -Value {
                            return @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        } -PassThru

                        return @(
                            @{
                                Category                        = 'Processor'
                                Counter                         = '% Processor Time'
                                AssociatedHealthScoreCalculator = $associatedHealthScoreCalculator
                            }
                        )
                    }
                }

                It "Should return IsDescending=true from the get method" {
                    (Get-TargetResource @testParams).IsDescending | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw 'The HealthScoreBuckets parameter is required when Ensure=Present'
                }
            }

            Context -Name "Specified HealthScoreBuckets order does not match the IsDescending parameter" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl          = 'http://sites.sharepoint.com'
                        Category           = 'Processor'
                        Counter            = '% Processor Time'
                        HealthScoreBuckets = @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        IsDescending       = $false
                        Ensure             = 'Present'
                    }
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw 'The order of HealthScoreBuckets and IsDescending do not match. Make sure they do.'
                }
            }

            Context -Name "Specified Category and Counter returns more than one result" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl          = 'http://sites.sharepoint.com'
                        Category           = 'Processor'
                        Counter            = '% Processor Time'
                        HealthScoreBuckets = @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        IsDescending       = $true
                        Ensure             = 'Present'
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $webApp = @{
                            DisplayName = 'Sites'
                        }
                        return $webApp
                    }

                    Mock -CommandName Get-SPWebApplicationHttpThrottlingMonitor -MockWith {
                        $associatedHealthScoreCalculator = @{}
                        $associatedHealthScoreCalculator = $associatedHealthScoreCalculator | Add-Member -MemberType ScriptMethod -Name GetScoreBuckets -Value {
                            return @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        } -PassThru

                        return @(
                            @{
                                Category                        = 'Processor'
                                Counter                         = '% Processor Time'
                                AssociatedHealthScoreCalculator = $associatedHealthScoreCalculator
                                Instance                        = 0
                            },
                            @{
                                Category                        = 'Processor'
                                Counter                         = '% Processor Time'
                                AssociatedHealthScoreCalculator = $associatedHealthScoreCalculator
                                Instance                        = 1
                            }
                        )
                    }
                }

                It "Should throw an exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw 'The specified Category and Counter returned more than one result. Please also specify a CounterInstance.'
                }

                It "Should throw an exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw 'The specified Category and Counter returned more than one result. Please also specify a CounterInstance.'
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw 'The specified Category and Counter returned more than one result. Please also specify a CounterInstance.'
                }
            }

            Context -Name "Specified web application does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl          = 'http://sites.sharepoint.com'
                        Category           = 'Processor'
                        Counter            = '% Processor Time'
                        HealthScoreBuckets = @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        IsDescending       = $true
                        Ensure             = 'Present'
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return $null
                    }
                }

                It "Should return Ensure=Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Web application $($testParams.WebAppUrl) was not found"
                }
            }

            Context -Name "Specified Counter is not present, but should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl          = 'http://sites.sharepoint.com'
                        Category           = 'Processor'
                        Counter            = '% Processor Time'
                        HealthScoreBuckets = @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        IsDescending       = $true
                        Ensure             = 'Present'
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $httpThrottleSettings = @{}
                        $httpThrottleSettings = $httpThrottleSettings | Add-Member -MemberType ScriptMethod -Name AddPerformanceMonitor -Value {
                        } -PassThru
                        $httpThrottleSettings = $httpThrottleSettings | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscThrottleSettingsUpdated = $true
                        } -PassThru

                        $webApp = @{
                            DisplayName          = 'Sites'
                            HttpThrottleSettings = $httpThrottleSettings
                        }
                        return $webApp
                    }

                    Mock -CommandName Get-SPWebApplicationHttpThrottlingMonitor -MockWith {
                        $associatedHealthScoreCalculator = @{}
                        $associatedHealthScoreCalculator = $associatedHealthScoreCalculator | Add-Member -MemberType ScriptMethod -Name GetScoreBuckets -Value {
                            return @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        } -PassThru

                        return @(
                            @{
                                Category                        = 'Memory'
                                Counter                         = 'Available MBytes'
                                AssociatedHealthScoreCalculator = $associatedHealthScoreCalculator
                            }
                        )
                    }
                }

                It "Should return Ensure=Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
                }

                It "Should return False the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the counter monitor in the set method" {
                    $Global:SPDscThrottleSettingsUpdated = $false
                    Set-TargetResource @testParams
                    $Global:SPDscThrottleSettingsUpdated | Should -Be $true
                }
            }

            Context -Name "Specified Counter is present, but not configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl          = 'http://sites.sharepoint.com'
                        Category           = 'Processor'
                        Counter            = '% Processor Time'
                        HealthScoreBuckets = @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        IsDescending       = $true
                        Ensure             = 'Present'
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $httpThrottleSettings = @{}
                        $httpThrottleSettings = $httpThrottleSettings | Add-Member -MemberType ScriptMethod -Name AddPerformanceMonitor -Value {
                        } -PassThru
                        $httpThrottleSettings = $httpThrottleSettings | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscThrottleSettingsUpdated = $true
                        } -PassThru

                        $webApp = @{
                            DisplayName          = 'Sites'
                            HttpThrottleSettings = $httpThrottleSettings
                        }
                        return $webApp
                    }

                    Mock -CommandName Get-SPWebApplicationHttpThrottlingMonitor -MockWith {
                        $associatedHealthScoreCalculator = @{}
                        $associatedHealthScoreCalculator = $associatedHealthScoreCalculator | Add-Member -MemberType ScriptMethod -Name GetScoreBuckets -Value {
                            return @(100, 90, 80, 70, 60, 50, 40, 30, 20, 10)
                        } -PassThru

                        return @(
                            @{
                                Category                        = 'Processor'
                                Counter                         = '% Processor Time'
                                AssociatedHealthScoreCalculator = $associatedHealthScoreCalculator
                            }
                        )
                    }

                    Mock -CommandName Set-SPWebApplicationHttpThrottlingMonitor -MockWith { }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
                }

                It "Should return False the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should correct the counter monitor in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Set-SPWebApplicationHttpThrottlingMonitor
                }
            }

            Context -Name "Specified Counter is not present and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = 'http://sites.sharepoint.com'
                        Category  = 'Processor'
                        Counter   = '% Processor Time'
                        Ensure    = 'Absent'
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $httpThrottleSettings = @{}
                        $httpThrottleSettings = $httpThrottleSettings | Add-Member -MemberType ScriptMethod -Name AddPerformanceMonitor -Value {
                        } -PassThru
                        $httpThrottleSettings = $httpThrottleSettings | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscThrottleSettingsUpdated = $true
                        } -PassThru

                        $webApp = @{
                            DisplayName          = 'Sites'
                            HttpThrottleSettings = $httpThrottleSettings
                        }
                        return $webApp
                    }

                    Mock -CommandName Get-SPWebApplicationHttpThrottlingMonitor -MockWith {
                        $associatedHealthScoreCalculator = @{}
                        $associatedHealthScoreCalculator = $associatedHealthScoreCalculator | Add-Member -MemberType ScriptMethod -Name GetScoreBuckets -Value {
                            return @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        } -PassThru

                        return @(
                            @{
                                Category                        = 'Memory'
                                Counter                         = 'Available MBytes'
                                AssociatedHealthScoreCalculator = $associatedHealthScoreCalculator
                            }
                        )
                    }
                }

                It "Should return Ensure=Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
                }

                It "Should return True the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Specified Counter is present, but should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = 'http://sites.sharepoint.com'
                        Category  = 'Processor'
                        Counter   = '% Processor Time'
                        Ensure    = 'Absent'
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $httpThrottleSettings = @{}
                        $httpThrottleSettings = $httpThrottleSettings | Add-Member -MemberType ScriptMethod -Name RemovePerformanceMonitor -Value {
                        } -PassThru
                        $httpThrottleSettings = $httpThrottleSettings | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscThrottleSettingsRemoved = $true
                        } -PassThru

                        $webApp = @{
                            DisplayName          = 'Sites'
                            HttpThrottleSettings = $httpThrottleSettings
                        }
                        return $webApp
                    }

                    Mock -CommandName Get-SPWebApplicationHttpThrottlingMonitor -MockWith {
                        $associatedHealthScoreCalculator = @{}
                        $associatedHealthScoreCalculator = $associatedHealthScoreCalculator | Add-Member -MemberType ScriptMethod -Name GetScoreBuckets -Value {
                            return @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                        } -PassThru

                        return @(
                            @{
                                Category                        = 'Processor'
                                Counter                         = '% Processor Time'
                                AssociatedHealthScoreCalculator = $associatedHealthScoreCalculator
                            }
                        )
                    }

                    Mock -CommandName Set-SPWebApplicationHttpThrottlingMonitor -MockWith { }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
                }

                It "Should return False the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the counter monitor in the set method" {
                    $Global:SPDscThrottleSettingsRemoved = $false
                    Set-TargetResource @testParams
                    $Global:SPDscThrottleSettingsRemoved | Should -Be $true
                }
            }

            Context -Name "Specified Counter is present and is correctly configured" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl          = 'http://sites.sharepoint.com'
                        Category           = 'Processor'
                        Counter            = '% Processor Time'
                        CounterInstance    = 0
                        HealthScoreBuckets = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
                        IsDescending       = $false
                        Ensure             = 'Present'
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $webApp = @{
                            DisplayName = 'Sites'
                        }
                        return $webApp
                    }

                    Mock -CommandName Get-SPWebApplicationHttpThrottlingMonitor -MockWith {
                        $associatedHealthScoreCalculator = @{}
                        $associatedHealthScoreCalculator = $associatedHealthScoreCalculator | Add-Member -MemberType ScriptMethod -Name GetScoreBuckets -Value {
                            return @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
                        } -PassThru

                        return @(
                            @{
                                Category                        = 'Processor'
                                Counter                         = '% Processor Time'
                                Instance                        = 0
                                AssociatedHealthScoreCalculator = $associatedHealthScoreCalculator
                            }
                        )
                    }

                    Mock -CommandName Set-SPWebApplicationHttpThrottlingMonitor -MockWith { }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
                }

                It "Should return True the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            WebAppUrl          = "http://example.contoso.local"
                            Category           = 'Processor'
                            Counter            = '% Processor Time'
                            HealthScoreBuckets = @(10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
                            IsDescending       = $true
                            Ensure             = 'Present'
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $spWebApp = [PSCustomObject]@{
                            Url = "http://example.contoso.local"
                        }
                        return $spWebApp
                    }

                    Mock -CommandName Get-SPWebApplicationHttpThrottlingMonitor -MockWith {
                        return @(
                            @{
                                Category = 'Processor'
                                Counter  = '% Processor Time'
                            }
                        )
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPWebAppHttpThrottlingMonitor [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Category             = "Processor";
            Counter              = "% Processor Time";
            Ensure               = "Present";
            HealthScoreBuckets   = @\(10987654321\);
            IsDescending         = \$True;
            PsDscRunAsCredential = \$Credsspfarm;
            WebAppUrl            = "http://example.contoso.local";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
