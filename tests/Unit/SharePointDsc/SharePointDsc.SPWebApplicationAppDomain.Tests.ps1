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
$script:DSCResourceName = 'SPWebApplicationAppDomain'
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
                Mock -CommandName New-SPWebApplicationAppDomain -MockWith { }
                Mock -CommandName Remove-SPWebApplicationAppDomain -MockWith { }
                Mock -CommandName Start-Sleep -MockWith { }
            }

            # Test contexts
            Context -Name "No app domain settings have been configured for the specified web app and zone" -Fixture {
                BeforeAll {
                    $testParams = @{
                        AppDomain = "contosointranetapps.com"
                        WebAppUrl = "http://portal.contoso.com"
                        Zone      = "Default"
                        Port      = 80;
                        SSL       = $false
                    }

                    Mock -CommandName Get-SPWebApplicationAppDomain -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).AppDomain | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the new app domain entry" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPWebApplicationAppDomain
                }
            }

            Context -Name "An app domain has been configured for the specified web app and zone but it's not correct" -Fixture {
                BeforeAll {
                    $testParams = @{
                        AppDomain = "contosointranetapps.com"
                        WebAppUrl = "http://portal.contoso.com"
                        Zone      = "Default"
                        Port      = 80;
                        SSL       = $false
                    }

                    Mock -CommandName Get-SPWebApplicationAppDomain -MockWith {
                        return @{
                            AppDomain   = "wrong.domain"
                            UrlZone     = $testParams.Zone
                            Port        = $testParams.Port
                            IsSchemeSSL = $testParams.SSL
                        }
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).AppDomain | Should -Be "wrong.domain"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the new app domain entry" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPWebApplicationAppDomain
                    Assert-MockCalled New-SPWebApplicationAppDomain
                }
            }

            Context -Name "The correct app domain has been configued for the requested web app and zone" -Fixture {
                BeforeAll {
                    $testParams = @{
                        AppDomain = "contosointranetapps.com"
                        WebAppUrl = "http://portal.contoso.com"
                        Zone      = "Default"
                        Port      = 80;
                        SSL       = $false
                    }

                    Mock -CommandName Get-SPWebApplicationAppDomain -MockWith {
                        return @{
                            AppDomain   = $testParams.AppDomain
                            UrlZone     = $testParams.Zone
                            Port        = $testParams.Port
                            IsSchemeSSL = $testParams.SSL
                        }
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).AppDomain | Should -Be $testParams.AppDomain
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The functions operate without optional parameters included" -Fixture {
                BeforeAll {
                    $testParams = @{
                        AppDomain = "contosointranetapps.com"
                        WebAppUrl = "http://portal.contoso.com"
                        Zone      = "Default"
                    }

                    Mock -CommandName Get-SPWebApplicationAppDomain -MockWith {
                        return @{
                            AppDomain   = "invalid.domain"
                            UrlZone     = $testParams.Zone
                            Port        = $testParams.Port
                            IsSchemeSSL = $testParams.SSL
                        }
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).AppDomain | Should -Be "invalid.domain"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the new app domain entry" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPWebApplicationAppDomain
                    Assert-MockCalled New-SPWebApplicationAppDomain
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            AppDomain = "contosointranetapps.com"
                            WebAppUrl = "http://portal.contoso.com"
                            Zone      = "Default";
                            Port      = 80;
                            SSL       = $false;
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $spWebApp = [PSCustomObject]@{
                            Name = "SharePoint Sites"
                            Url  = "http://portal.contoso.com"
                        }
                        return $spWebApp
                    }

                    Mock -CommandName Get-SPWebApplicationAppDomain -MockWith {
                        return @{
                            AppDomain = "contosointranetapps.com"
                        }
                    }
                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPWebApplicationAppDomain [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            AppDomain            = "contosointranetapps.com";
            Port                 = 80;
            PsDscRunAsCredential = \$Credsspfarm;
            SSL                  = \$False;
            WebAppUrl            = "http://portal.contoso.com";
            Zone                 = "Default";
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
