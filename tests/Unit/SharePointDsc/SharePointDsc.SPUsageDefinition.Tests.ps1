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
$script:DSCResourceName = 'SPUsageDefinition'
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

                Mock -CommandName Get-SPUsageDefinition -MockWith {
                    return @{
                        Name                 = "Administrative Actions"
                        Retention            = 14
                        DaysToKeepUsageFiles = 1
                        MaxTotalSizeInBytes  = 10000000000000
                        Enabled              = $true
                        UsageDatabaseEnabled = $true
                    }
                }

                Mock -CommandName Set-SPUsageDefinition -MockWith { }

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

            Context -Name "When the Usage Definition passed doesn't exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "MyFakeProvider"
                        DaysRetained         = 14
                        DaysToKeepUsageFiles = 1
                        MaxTotalSizeInBytes  = 10000000000000
                        Enabled              = $true
                        Ensure               = "Present"
                    }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -ne 15)
                    {
                        $testParams.UsageDatabaseEnabled = $true
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an error about a non-existing definition" {
                    { Set-TargetResource @testParams } | Should -Throw ("The specified Usage Definition {" + $testParams.Name + "} could not be found.")
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }
            }

            Context -Name "When the Usage Definition passed doesn't exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name = "Administrative Actions"
                    }
                }

                It "Should throw an error about having to specify a parameter" {
                    { Set-TargetResource @testParams } | Should -Throw "You have to at least specify one parameter: DaysRetained, DaysToKeepUsageFiles, MaxTotalSizeInBytes, Enabled or UsageDatabaseEnabled."
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
            {
                Context -Name "When the parameter UsageDatabaseEnabled is passed for SharePoint 2013" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name                 = "Administrative Actions"
                            DaysRetained         = 14
                            DaysToKeepUsageFiles = 1
                            MaxTotalSizeInBytes  = 10000000000000
                            Enabled              = $true
                            UsageDatabaseEnabled = $true
                            Ensure               = "Present"
                        }
                    }

                    It "Should throw an error about a the incorrect use of the parameter" {
                        { Set-TargetResource @testParams } | Should -Throw "Parameter UsageDatabaseEnabled not supported in SharePoint 2013. Please remove it from the configuration."
                    }
                }
            }

            Context -Name "When the Usage Definition exists, but has incorrect settings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "Administrative Actions"
                        DaysRetained         = 13
                        DaysToKeepUsageFiles = 2
                        MaxTotalSizeInBytes  = 20000000000000
                        Enabled              = $false
                        Ensure               = "Present"
                    }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -ne 15)
                    {
                        $testParams.UsageDatabaseEnabled = $false
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should properly configure the provider" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPUsageDefinition
                }

                It "Should return a DaysRetained of 14 from the Get method" {
                    (Get-TargetResource @testParams).DaysRetained | Should -Be 14
                }
            }

            Context -Name "When the Usage Definition exists and has correct settings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "Administrative Actions"
                        DaysRetained         = 14
                        DaysToKeepUsageFiles = 1
                        MaxTotalSizeInBytes  = 10000000000000
                        Enabled              = $true
                        Ensure               = "Present"
                    }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -ne 15)
                    {
                        $testParams.UsageDatabaseEnabled = $true
                    }
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should return a DaysRetained of 14 from the Get method" {
                    (Get-TargetResource @testParams).DaysRetained | Should -Be 14
                }
            }

            Context -Name "When using Ensure is Absent" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "Administrative Actions"
                        DaysRetained         = 14
                        DaysToKeepUsageFiles = 1
                        MaxTotalSizeInBytes  = 10000000000000
                        Enabled              = $true
                        Ensure               = "Absent"
                    }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -ne 15)
                    {
                        $testParams.UsageDatabaseEnabled = $false
                    }
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "This resource cannot remove a Usage Definition. Please use ensure equals Present."
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name                 = "Administrative Actions"
                            DaysRetained         = 14
                            DaysToKeepUsageFiles = 1
                            MaxTotalSizeInBytes  = 10000000000000
                            Enabled              = $true
                            Ensure               = "Present"
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
        SPUsageDefinition UsageDefinition_AdministrativeActions
        {
            DaysRetained         = 14;
            DaysToKeepUsageFiles = 1;
            Enabled              = $True;
            Ensure               = "Present";
            MaxTotalSizeInBytes  = 10000000000000;
            Name                 = "Administrative Actions";
            PsDscRunAsCredential = $Credsspfarm;
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
