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
$script:DSCResourceName = 'SPWebAppProxyGroup'
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
                Mock -CommandName Set-SPWebApplication -MockWith { }
            }

            # Test contexts
            Context -Name "WebApplication does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl            = "https://web.contoso.com"
                        ServiceAppProxyGroup = "Web1ProxyGroup"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith { }
                }

                It "Should return null property from the get method" {
                    (Get-TargetResource @testParams).WebAppUrl | Should -Be $null
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "WebApplication Proxy Group connection matches desired config" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl            = "https://web.contoso.com"
                        ServiceAppProxyGroup = "Web1ProxyGroup"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            ServiceApplicationProxyGroup = @{
                                Name = "Web1ProxyGroup"
                            }
                        }
                    }
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).ServiceAppProxyGroup | Should -Be "Web1ProxyGroup"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "WebApplication Proxy Group connection does not match desired config" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl            = "https://web.contoso.com"
                        ServiceAppProxyGroup = "Default"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            ServiceApplicationProxyGroup = @{
                                Name = "Web1ProxyGroup"
                            }
                        }
                    }
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).ServiceAppProxyGroup | Should -Be "Web1ProxyGroup"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the webapplication from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPWebApplication
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            WebAppUrl            = "https://intranet.sharepoint.contoso.com"
                            ServiceAppProxyGroup = "Proxy Group 1"
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $spWebApp = [PSCustomObject]@{
                            Name                         = "SharePoint Sites"
                            Url                          = "https://intranet.sharepoint.contoso.com"
                            ServiceApplicationProxyGroup = @{
                                FriendlyName = "Proxy Group 1"
                            }
                        }
                        return $spWebApp
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPWebAppProxyGroup [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            PsDscRunAsCredential = \$Credsspfarm;
            ServiceAppProxyGroup = "Proxy Group 1";
            WebAppUrl            = "https://intranet.sharepoint.contoso.com";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")
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
