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
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -Scriptblock $Global:SPDscHelper.InitializeScript -NoNewScope

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
                }

                It "Should return null from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.AllowDownloadInfected | Should -Be $false
                    $result.ScanOnDownload | Should -Be $false
                    $result.ScanOnUpload | Should -Be $false
                    $result.AttemptToClean | Should -Be $false
                    $result.NumberOfThreads | Should -Be 0
                    $result.TimeoutDuration | Should -Be 0
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }
            }

            Context -Name "The server is in a farm and the incorrect settings have been applied" -Fixture {
                BeforeAll {
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
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscAntivirusUpdated = $false
                It "Should update the antivirus settings" {
                    Set-TargetResource @testParams
                    $Global:SPDscAntivirusUpdated | Should -Be $true
                }
            }

            Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
                BeforeAll {
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
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            IsSingleInstance      = "Yes"
                            AllowDownloadInfected = $false
                            ScanOnDownload        = $false
                            ScanOnUpload          = $true
                            AttemptToClean        = $true
                            NumberOfThreads       = 5
                            TimeoutDuration       = 30
                        }
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPAntivirusSettings AntivirusSettings
        {
            AllowDownloadInfected = $False;
            AttemptToClean        = $True;
            IsSingleInstance      = "Yes";
            NumberOfThreads       = 5;
            PsDscRunAsCredential  = $Credsspfarm;
            ScanOnDownload        = $False;
            ScanOnUpload          = $True;
            TimeoutDuration       = 30;
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
