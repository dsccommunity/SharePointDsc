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
$script:DSCResourceName = 'SPServiceAppPool'
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
                Mock -CommandName New-SPServiceApplicationPool -MockWith { }
                Mock -CommandName Set-SPServiceApplicationPool -MockWith { }
                Mock -CommandName Remove-SPServiceApplicationPool -MockWith { }
            }

            # Test contexts
            Context -Name "A service account pool does not exist but should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name           = "Service pool"
                        ServiceAccount = "DEMO\svcSPServiceApps"
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the set method to create a new service account pool" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPServiceApplicationPool
                }
            }

            Context -Name "A service account pool exists but has the wrong service account" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name           = "Service pool"
                        ServiceAccount = "DEMO\svcSPServiceApps"
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name               = $testParams.Name
                            ProcessAccountName = "WRONG\account"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the set method to update the service account pool" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Set-SPServiceApplicationPool
                }
            }

            Context -Name "A service account pool exists and uses the correct account" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name           = "Service pool"
                        ServiceAccount = "DEMO\svcSPServiceApps"
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name               = $testParams.Name
                            ProcessAccountName = $testParams.ServiceAccount
                        }
                    }
                }

                It "retrieves present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When the service app pool exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name           = "Service pool"
                        ServiceAccount = "DEMO\svcSPServiceApps"
                        Ensure         = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name               = $testParams.Name
                            ProcessAccountName = $testParams.ServiceAccount
                        }
                    }
                }

                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPServiceApplicationPool
                }
            }

            Context -Name "When the service app pool doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name           = "Service pool"
                        ServiceAccount = "DEMO\svcSPServiceApps"
                        Ensure         = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name           = "SharePoint Service Applications"
                            ServiceAccount = "Demo\ServiceAccount"
                            Ensure         = "Present"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        $spServiceAppPool = [PSCustomObject]@{
                            DisplayName = "SharePoint Service Applications"
                            Name        = "SharePoint Service Applications"
                        }
                        return $spServiceAppPool
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPServiceAppPool SharePointServiceApplications
        {
            Ensure               = "Present";
            Name                 = "SharePoint Service Applications";
            PsDscRunAsCredential = $Credsspfarm;
            ServiceAccount       = "Demo\ServiceAccount";
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
