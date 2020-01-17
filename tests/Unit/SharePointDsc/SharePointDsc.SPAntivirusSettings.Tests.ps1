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
$script:DSCResourceName = 'SPAntivirusSettings'
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
            Context -Name "The server is not part of SharePoint farm" -Fixture {
                $testParams = @{
                    IsSingleInstance      = "Yes"
                    ScanOnDownload        = $true
                    ScanOnUpload          = $true
                    AllowDownloadInfected = $true
                    AttemptToClean        = $true
                    TimeoutDuration       = 60
                    NumberOfThreads       = 5
                }

                Mock -CommandName Get-SPFarm -MockWith {
                    throw "Unable to detect local farm"
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.AllowDownloadInfected | Should Be $false
                    $result.ScanOnDownload | Should Be $false
                    $result.ScanOnUpload | Should Be $false
                    $result.AttemptToClean | Should Be $false
                    $result.NumberOfThreads | Should Be 0
                    $result.TimeoutDuration | Should Be 0
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
                }
            }

            Context -Name "The server is in a farm and the incorrect settings have been applied" -Fixture {
                $testParams = @{
                    IsSingleInstance      = "Yes"
                    ScanOnDownload        = $true
                    ScanOnUpload          = $true
                    AllowDownloadInfected = $true
                    AttemptToClean        = $true
                    TimeoutDuration       = 60
                    NumberOfThreads       = 5
                }

                Mock -CommandName Get-SPDscContentService -MockWith {
                    $returnVal = @{
                        AntivirusSettings = @{
                            AllowDownload       = $false
                            DownloadScanEnabled = $false
                            UploadScanEnabled   = $false
                            CleaningEnabled     = $false
                            NumberOfThreads     = 0
                            Timeout             = @{
                                TotalSeconds = 0;
                            }
                        }
                    }
                    $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscAntivirusUpdated = $true
                    } -PassThru
                    return $returnVal
                }
                Mock -CommandName Get-SPFarm -MockWith { return @{ } }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should Not BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                $Global:SPDscAntivirusUpdated = $false
                It "Should update the antivirus settings" {
                    Set-TargetResource @testParams
                    $Global:SPDscAntivirusUpdated | Should Be $true
                }
            }

            Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
                $testParams = @{
                    IsSingleInstance      = "Yes"
                    ScanOnDownload        = $true
                    ScanOnUpload          = $true
                    AllowDownloadInfected = $true
                    AttemptToClean        = $true
                    TimeoutDuration       = 60
                    NumberOfThreads       = 5
                }

                Mock -CommandName Get-SPDscContentService -MockWith {
                    $returnVal = @{
                        AntivirusSettings = @{
                            AllowDownload       = $true
                            DownloadScanEnabled = $true
                            UploadScanEnabled   = $true
                            CleaningEnabled     = $true
                            NumberOfThreads     = 5
                            Timeout             = @{
                                TotalSeconds = 60;
                            }
                        }
                    }
                    return $returnVal
                }
                Mock -CommandName Get-SPFarm -MockWith { return @{ } }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should Not BeNullOrEmpty
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
