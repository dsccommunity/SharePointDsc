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
$script:DSCResourceName = 'SPOfficeOnlineServerBinding'
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
                Mock -CommandName Remove-SPWOPIBinding -MockWith { }
                Mock -CommandName New-SPWOPIBinding -MockWith { }
                Mock -CommandName Set-SPWOPIZone -MockWith { }
                Mock -CommandName Get-SPWOPIZone -MockWith { return "internal-https" }
            }

            # Test contexts
            Context -Name "No bindings are set for the specified zone, but they should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Zone    = "internal-https"
                        DnsName = "webapps.contoso.com"
                        Ensure  = "Present"
                    }

                    Mock -CommandName Get-SPWOPIBinding -MockWith {
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
                    Assert-MockCalled New-SPWOPIBinding
                    Assert-MockCalled Set-SPWOPIZone
                }
            }

            Context -Name "Incorrect bindings are set for the specified zone that should be configured" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Zone    = "internal-https"
                        DnsName = "webapps.contoso.com"
                        Ensure  = "Present"
                    }

                    Mock -CommandName Get-SPWOPIBinding -MockWith {
                        return @(
                            @{
                                ServerName = "wrong.contoso.com"
                            }
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
                    Assert-MockCalled Remove-SPWOPIBinding
                    Assert-MockCalled New-SPWOPIBinding
                    Assert-MockCalled Set-SPWOPIZone
                }
            }

            Context -Name "Correct bindings are set for the specified zone" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Zone    = "internal-https"
                        DnsName = "webapps.contoso.com"
                        Ensure  = "Present"
                    }

                    Mock -CommandName Get-SPWOPIBinding -MockWith {
                        return @(
                            @{
                                ServerName = "webapps.contoso.com"
                            }
                        )
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Bindings are set for the specified zone, but they should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Zone    = "internal-https"
                        DnsName = "webapps.contoso.com"
                        Ensure  = "Absent"
                    }

                    Mock -CommandName Get-SPWOPIBinding -MockWith {
                        return @(
                            @{
                                ServerName = "webapps.contoso.com"
                            }
                        )
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the bindings in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPWOPIBinding
                }
            }

            Context -Name "Bindings are not set for the specified zone, and they should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Zone    = "internal-https"
                        DnsName = "webapps.contoso.com"
                        Ensure  = "Absent"
                    }

                    Mock -CommandName Get-SPWOPIBinding -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Zone    = "internal-https"
                            DnsName = "webapps.contoso.com"
                            Ensure  = "Present"
                        }
                    }

                    Mock -CommandName Get-SPWOPIZone -MockWith { return "internal-https" }

                    Mock -CommandName Get-SPWOPIBinding -MockWith {
                        return @(
                            @{
                                ServerName = "webapps.contoso.com"
                            }
                        )
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPOfficeOnlineServerBinding [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            DnsName              = "webapps.contoso.com";
            Ensure               = "Present";
            PsDscRunAsCredential = \$Credsspfarm;
            Zone                 = "internal-https";
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
