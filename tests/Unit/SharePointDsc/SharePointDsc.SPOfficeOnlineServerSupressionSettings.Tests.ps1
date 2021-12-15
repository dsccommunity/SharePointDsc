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
$script:DSCResourceName = 'SPOfficeOnlineServerSupressionSettings'
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
                Mock -CommandName Remove-SPWOPISuppressionSetting -MockWith { }
                Mock -CommandName New-SPWOPISuppressionSetting -MockWith { }
            }

            # Test contexts
            Context -Name "Supression settings do not exist, but they should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Extension = "pdf"
                        Action    = "view", "edit"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Get-SPWOPISuppressionSetting -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the bindings in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPWOPISuppressionSetting -Times 2
                }
            }

            Context -Name "Suppression settings exist, but should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Extension = "pdf"
                        Ensure    = "Absent"
                    }

                    Mock -CommandName Get-SPWOPISuppressionSetting -MockWith {
                        return @(
                            "PDF VIEW",
                            "XLS VIEW",
                            "XLS EDIT",
                            "PDF EMBEDVIEW"
                        )
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the old bindings and create the new bindings in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPWOPISuppressionSetting -Times 2
                }
            }

            Context -Name "Suppression settings exist, but are incorrect" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Extension = "pdf"
                        Action    = "view", "edit"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Get-SPWOPISuppressionSetting -MockWith {
                        return @(
                            "PDF VIEW",
                            "XLS VIEW",
                            "XLS EDIT",
                            "PDF EMBEDVIEW"
                        )
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the old bindings and create the new bindings in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPWOPISuppressionSetting -Times 1
                    Assert-MockCalled Remove-SPWOPISuppressionSetting -Times 1
                }
            }

            Context -Name "Supression settings do not exists and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Extension = "pdf"
                        Ensure    = "Absent"
                    }

                    Mock -CommandName Get-SPWOPISuppressionSetting -MockWith {
                        return @(
                            "XLS VIEW",
                            "XLS EDIT"
                        )
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Supression settings exist and are correct" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Extension = "pdf"
                        Action    = "view", "edit"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Get-SPWOPISuppressionSetting -MockWith {
                        return @(
                            "PDF VIEW",
                            "XLS VIEW",
                            "XLS EDIT",
                            "PDF EDIT"
                        )
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Ensure is Present, but Actions parameter is missing" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Extension = "pdf"
                        Ensure    = "Present"
                    }
                }

                It "Should throw an exception from the Set method" {
                    { Set-TargetResource @testParams } | Should -Throw "You have to specify the Actions parameter if Ensure is not set to Absent"
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Extension = "pdf"
                            Action    = "view", "edit"
                            Ensure    = "Present"
                        }
                    }

                    Mock -CommandName Get-SPWOPISuppressionSetting -MockWith {
                        return @(
                            "PDF VIEW",
                            "PDF EDIT"
                        )
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPOfficeOnlineServerSupressionSettings 'PDF'
        {
            Action               = @("view","edit");
            Ensure               = "Present";
            Extension            = "pdf";
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
