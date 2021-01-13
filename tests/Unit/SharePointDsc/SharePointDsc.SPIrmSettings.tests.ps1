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
$script:DSCResourceName = 'SPIrmSettings'
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

                # Initialize tests

                # Mocks for all contexts
                Mock -CommandName Get-SPFarm -MockWith {
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
                        IsSingleInstance = "Yes"
                        Ensure           = "Present"
                        RMSserver        = "https://myRMSserver.local"
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw "Unable to detect local farm"
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }
            }

            Context -Name "IRM settings match desired settings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Ensure           = "Present"
                        RMSserver        = "https://myRMSserver.local"
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        $returnVal = @{
                            IrmSettings = @{
                                IrmRMSEnabled    = $true
                                IrmRMSUseAD      = $false
                                IrmRMSCertServer = "https://myRMSserver.local"
                            }
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $Global:SPDscIRMUpdated = $true
                        } -PassThru
                        return $returnVal
                    }
                }

                It "Should return present in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true in the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "IRM settings do not match desired settings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance = "Yes"
                        Ensure           = "Present"
                        RMSserver        = "https://myRMSserver.local"
                    }

                    Mock -CommandName Get-SPDscContentService -MockWith {
                        $returnVal = @{
                            IrmSettings = @{
                                IrmRMSEnabled    = $false
                                IrmRMSUseAD      = $false
                                IrmRMSCertServer = $null
                            }
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $Global:SPDscIRMUpdated = $true
                        } -PassThru
                        return $returnVal
                    }
                }

                It "Should return absent in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false in the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscIRMUpdated = $false
                It "Should apply the settings in the set method" {
                    Set-TargetResource @testParams
                    $Global:SPDscIRMUpdated | Should -Be $true
                }

                It "Should throw when UseAD and RMSserver are both supplied" {
                    $testParams.Add("UseADRMS", $true)
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            IsSingleInstance = "Yes"
                            UseADRMS         = $false
                            RMSserver        = "https://rms.contoso.com"
                            Ensure           = "Present"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Access Services Web Service Application"
                            DisplayName     = "Access Services Service Application"
                            Name            = "Access Services Service Application"
                            DatabaseServer  = "SQL01"
                            ApplicationPool = "Service App Pool"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPIrmSettings [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Ensure               = "Present";
            IsSingleInstance     = "Yes";
            PsDscRunAsCredential = \$Credsspfarm;
            RMSserver            = "https://rms.contoso.com";
            UseADRMS             = \$False;
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")
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
