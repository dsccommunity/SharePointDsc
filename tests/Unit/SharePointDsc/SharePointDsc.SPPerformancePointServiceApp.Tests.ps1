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
$script:DSCResourceName = 'SPPerformancePointServiceApp'
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

                #Initialize tests
                $getTypeFullName = "Microsoft.PerformancePoint.Scorecards.BIMonitoringServiceApplication"

                # Mocks for all contexts
                Mock -CommandName Remove-SPServiceApplication -MockWith { }
                Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                Mock -CommandName New-SPPerformancePointServiceApplication -MockWith { }
                Mock -CommandName New-SPPerformancePointServiceApplicationProxy -MockWith { }
            }

            # Test contexts
            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test Performance Point App"
                        ApplicationPool = "Test App Pool"
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPPerformancePointServiceApplication
                }
            }

            Context -Name "When service applications exist in the current farm but the specific Performance Point app does not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test Performance Point App"
                        ApplicationPool = "Test App Pool"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = $testParams.Name
                        }
                        $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = "Microsoft.Office.UnKnownWebServiceApplication"
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }
                }

                It "Should return null from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }
            }

            Context -Name "When a service application exists and is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test Performance Point App"
                        ApplicationPool = "Test App Pool"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "PerformancePoint Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                        }
                        $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When a service application exists and is not configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test Performance Point App"
                        ApplicationPool = "Test App Pool"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Access Services Web Service Application"
                            DisplayName     = $testParams.Name
                            DatabaseServer  = $testParams.DatabaseName
                            ApplicationPool = @{ Name = "Wrong app pool name" }
                        }
                        $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the update service app cmdlet from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPServiceApplicationPool
                }
            }

            Context -Name "When the service application exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "-"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "PerformancePoint Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = "Wrong App Pool Name" }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        return $spServiceApp
                    }
                }

                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove service application cmdlet in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPServiceApplication
                }
            }

            Context -Name "When the serivce application doesn't exist and it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "-"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name            = "PerformancePoint Service Application"
                            ProxyName       = "PerformancePoint Service Application Proxy"
                            ApplicationPool = "Service App Pool"
                            DatabaseName    = "PerformancePointDB"
                            DatabaseServer  = "SQL01"
                            Ensure          = "Present"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName    = "BIMonitoringServiceApplication"
                            DisplayName = "PerformancePoint Service Application"
                            Name        = "PerformancePoint Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "BIMonitoringServiceApplication"
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
        SPPerformancePointServiceApp PerformancePointServiceApplication
        {
            ApplicationPool      = "Service App Pool";
            DatabaseName         = "PerformancePointDB";
            DatabaseServer       = $ConfigurationData.NonNodeData.DatabaseServer;
            Ensure               = "Present";
            Name                 = "PerformancePoint Service Application";
            ProxyName            = "PerformancePoint Service Application Proxy";
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
