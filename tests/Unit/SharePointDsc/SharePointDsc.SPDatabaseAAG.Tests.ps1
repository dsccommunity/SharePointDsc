[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPDatabaseAAG'
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
                Invoke-Command -Scriptblock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Mocks for all contexts
                Mock -CommandName Add-DatabaseToAvailabilityGroup -MockWith { }
                Mock -CommandName Remove-DatabaseFromAvailabilityGroup -MockWith { }
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    Mock -CommandName Get-SPDscInstalledProductVersion {
                        return @{
                            FileMajorPart = 15
                            FileBuildPart = 4805
                        }
                    }
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
            Context -Name "The database is not in an availability group, but should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase"
                        AGName       = "AGName"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = $testParams.DatabaseName
                                AvailabilityGroup = $null
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the add cmdlet in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-DatabaseToAvailabilityGroup
                }
            }

            Context -Name "Multiple databases matching the name pattern are not in an availability group, but should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "Sample*"
                        AGName       = "AGName"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = "SampleDatabase1"
                                AvailabilityGroup = $null
                            },
                            @{
                                Name              = "SampleDatabase2"
                                AvailabilityGroup = $null
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the add cmdlet in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-DatabaseToAvailabilityGroup
                }
            }

            Context -Name "Single database is not in an availability group, but should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "Sample*"
                        AGName       = "AGName"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = "SampleDatabase1"
                                AvailabilityGroup = $null
                            },
                            @{
                                Name              = "SampleDatabase2"
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the add cmdlet in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-DatabaseToAvailabilityGroup
                }
            }

            Context -Name "The database is not in the availability group and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase"
                        AGName       = "AGName"
                        Ensure       = "Absent"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = $testParams.DatabaseName
                                AvailabilityGroup = $null
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Multiple databases matching the name pattern are not in the availability group and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase*"
                        AGName       = "AGName"
                        Ensure       = "Absent"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = "SampleDatabase1"
                                AvailabilityGroup = $null
                            },
                            @{
                                Name              = "SampleDatabase2"
                                AvailabilityGroup = $null
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The database is in the correct availability group and should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase"
                        AGName       = "AGName"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = $testParams.DatabaseName
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Multiple databases matching the name pattern are in the correct availability group and should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase*"
                        AGName       = "AGName"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = "SampleDatabase1"
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            },
                            @{
                                Name              = "SampleDatabase2"
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The database is in an availability group and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase"
                        AGName       = "AGName"
                        Ensure       = "Absent"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = $testParams.DatabaseName
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove cmdlet in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-DatabaseFromAvailabilityGroup
                }
            }

            Context -Name "Multiple databases matching the name pattern are in an availability group and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase*"
                        AGName       = "AGName"
                        Ensure       = "Absent"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = "SampleDatabase1"
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            },
                            @{
                                Name              = "SampleDatabase2"
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove cmdlet in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-DatabaseFromAvailabilityGroup
                }
            }

            Context -Name "Single database is in an availability group and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase*"
                        AGName       = "AGName"
                        Ensure       = "Absent"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = "SampleDatabase1"
                                AvailabilityGroup = @{
                                    Name = $null
                                }
                            },
                            @{
                                Name              = "SampleDatabase2"
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove cmdlet in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-DatabaseFromAvailabilityGroup
                }
            }

            Context -Name "The database is in the wrong availability group" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase"
                        AGName       = "AGName"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = $testParams.DatabaseName
                                AvailabilityGroup = @{
                                    Name = "WrongAAG"
                                }
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove and add cmdlets in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-DatabaseFromAvailabilityGroup
                    Assert-MockCalled Add-DatabaseToAvailabilityGroup
                }
            }

            Context -Name "Single database is in the wrong availability group" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase"
                        AGName       = "AGName"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = $testParams.DatabaseName
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            },
                            @{
                                Name              = $testParams.DatabaseName
                                AvailabilityGroup = @{
                                    Name = "WrongAAG"
                                }
                            }
                        )
                    }
                }

                It "Should return the current values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove and add cmdlets in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-DatabaseFromAvailabilityGroup
                    Assert-MockCalled Add-DatabaseToAvailabilityGroup
                }
            }

            Context -Name "Specified database is not found" -Fixture {
                BeforeAll {
                    $testParams = @{
                        DatabaseName = "SampleDatabase"
                        AGName       = "AGName"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name              = "WrongDatabase"
                                AvailabilityGroup = @{
                                    Name = $testParams.AGName
                                }
                            }
                        )
                    }
                }

                It "Should return DatabaseName='' from the get method" {
                    (Get-TargetResource @testParams).DatabaseName | Should -Be ""
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified database(s) not found."
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
            {
                Context -Name "An unsupported version of SharePoint is installed on the server" {
                    BeforeAll {
                        $testParams = @{
                            DatabaseName = "SampleDatabase"
                            AGName       = "AGName"
                            Ensure       = "Present"
                        }

                        Mock -CommandName Get-SPDscInstalledProductVersion {
                            return @{
                                FileMajorPart = 15
                                FileBuildPart = 4000
                            }
                        }
                    }

                    It "Should throw when an unsupported version is installed and get is called" {
                        { Get-TargetResource @testParams } | Should -Throw "Adding databases to SQL Always-On Availability Groups require the SharePoint 2013 April 2014 CU to be installed"
                    }

                    It "Should throw when an unsupported version is installed and test is called" {
                        { Test-TargetResource @testParams } | Should -Throw "Adding databases to SQL Always-On Availability Groups require the SharePoint 2013 April 2014 CU to be installed"
                    }

                    It "Should throw when an unsupported version is installed and set is called" {
                        { Set-TargetResource @testParams } | Should -Throw "Adding databases to SQL Always-On Availability Groups require the SharePoint 2013 April 2014 CU to be installed"
                    }
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            DatabaseName = "Content01DB"
                            AGName       = "AAG01"
                            FileShare    = "\\server\share"
                            Ensure       = "Present"
                        }
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $spDatabase = [PSCustomObject]@{
                            AvailabilityGroup = "AAG01"
                            Name              = "Content01DB"
                        }
                        return $spDatabase
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPDatabaseAAG [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            AGName               = "AAG01";
            DatabaseName         = "Content01DB";
            Ensure               = "Present";
            FileShare            = "\\\\server\\share";
            PsDscRunAsCredential = \$Credsspfarm;
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
