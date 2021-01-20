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
$script:DSCResourceName = 'SPAppDomain'
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
                Mock -CommandName Set-SPAppDomain -MockWith { }
                Mock -CommandName Set-SPAppSiteSubscriptionName -MockWith { }
            }

            # Test contexts
            Context -Name "No app URLs have been configured locally" -Fixture {
                BeforeAll {
                    $testParams = @{
                        AppDomain = "apps.contoso.com"
                        Prefix    = "apps"
                    }

                    Mock -CommandName Get-SPAppDomain -MockWith { }
                    Mock -CommandName Get-SPAppSiteSubscriptionName -MockWith { }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should save settings when the set method is run" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPAppDomain
                    Assert-MockCalled Set-SPAppSiteSubscriptionName
                }
            }

            Context -Name "Incorrect app URLs have been configured locally" -Fixture {
                BeforeAll {
                    $testParams = @{
                        AppDomain = "apps.contoso.com"
                        Prefix    = "apps"
                    }

                    Mock -CommandName Get-SPAppDomain -MockWith { return "wrong.domain" }
                    Mock -CommandName Get-SPAppSiteSubscriptionName -MockWith { return "wrongprefix" }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should save settings when the set method is run" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPAppDomain
                    Assert-MockCalled Set-SPAppSiteSubscriptionName
                }
            }

            Context -Name "Correct app URLs have been configured locally" -Fixture {
                BeforeAll {
                    $testParams = @{
                        AppDomain = "apps.contoso.com"
                        Prefix    = "apps"
                    }

                    Mock -CommandName Get-SPAppDomain -MockWith { return $testParams.AppDomain }
                    Mock -CommandName Get-SPAppSiteSubscriptionName -MockWith { $testParams.Prefix }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
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
                            AppDomain = 'contosoapps.local'
                            Prefix    = 'app'
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApps = @()

                        $spServiceApp = [PSCustomObject]@{
                            TypeName = "AppManagementServiceApplication"
                            Property = "String"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = 'AppManagementServiceApplication'
                            }
                        } -PassThru -Force

                        $spServiceApps += $spServiceApp

                        $spServiceApp2 = [PSCustomObject]@{
                            TypeName = "OtherServiceApp"
                            Property = "String"
                        }
                        $spServiceApp2 = $spServiceApp2 | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = 'OtherServiceApp'
                            }
                        } -PassThru -Force

                        $spServiceApps += $spServiceApp2

                        return $spServiceApps
                    }

                    Mock -CommandName Get-SPAppDomain -MockWith { return 'contosoapps.local' }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPAppDomain [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            AppDomain            = "contosoapps.local";
            Prefix               = "app";
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
