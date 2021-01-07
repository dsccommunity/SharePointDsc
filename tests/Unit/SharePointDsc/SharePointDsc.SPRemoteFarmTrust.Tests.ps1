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
$script:DSCResourceName = 'SPRemoteFarmTrust'
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
                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        Url = $Identity
                    }
                }
                Mock -CommandName Get-SPServiceContext {
                    return @{
                        Site = $Site
                    }
                }
                Mock -CommandName Get-SPAuthenticationRealm {
                    return "14757a87-4d74-4323-83b9-fb1e77e8f22f"
                }
                Mock -CommandName Get-SPAppPrincipal {
                    return @{
                        Site = $Site
                    }
                }
                Mock -CommandName Set-SPAuthenticationRealm { }
                Mock -CommandName Set-SPAppPrincipalPermission { }
                Mock -CommandName Remove-SPAppPrincipalPermission { }
                Mock -CommandName Remove-SPTrustedRootAuthority { }
                Mock -CommandName Remove-SPTrustedSecurityTokenIssuer { }
                Mock -CommandName New-SPTrustedSecurityTokenIssuer {
                    return @{
                        NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                    }
                }
                Mock -CommandName New-SPTrustedRootAuthority {
                    return @{
                        NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                    }
                }
            }

            # Test contexts
            Context -Name "A remote farm trust doesn't exist, but should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "SendingFarm"
                        LocalWebAppUrl  = "https://sharepoint.adventureworks.com"
                        RemoteWebAppUrl = "https://sharepoint.contoso.com"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        return $null
                    }
                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should add the trust in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName New-SPTrustedSecurityTokenIssuer
                    Assert-MockCalled -CommandName New-SPTrustedRootAuthority
                }
            }

            Context -Name "A remote farm trust exists and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "SendingFarm"
                        LocalWebAppUrl  = "https://sharepoint.adventureworks.com"
                        RemoteWebAppUrl = "https://sharepoint.contoso.com"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        return @(
                            @{
                                NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                            }
                        )
                    }
                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A remote farm trust exists and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "SendingFarm"
                        LocalWebAppUrl  = "https://sharepoint.adventureworks.com"
                        RemoteWebAppUrl = "https://sharepoint.contoso.com"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        return @(
                            @{
                                NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                            }
                        )
                    }
                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            NameId = "f5a433c7-69f9-48ef-916b-dde8b5fa6fdb@14757a87-4d74-4323-83b9-fb1e77e8f22f"
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the trust in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Remove-SPTrustedSecurityTokenIssuer
                    Assert-MockCalled -CommandName Remove-SPTrustedRootAuthority
                }
            }

            Context -Name "A remote farm trust doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "SendingFarm"
                        LocalWebAppUrl  = "https://sharepoint.adventureworks.com"
                        RemoteWebAppUrl = "https://sharepoint.contoso.com"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        return $null
                    }
                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name            = "CentralSearchFarm"
                            RemoteWebAppUrl = "https://search.sharepoint.contoso.com"
                            LocalWebAppUrl  = "https://local.sharepoint2.contoso.com"
                            Ensure          = "Present"
                        }
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        return @(
                            @{
                                Id = "CentralSearchFarm"
                            }
                        )
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @(
                            @{
                                Url = "https://local.sharepoint2.contoso.com"
                            }
                        )
                    }

                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            Url = "https://local.sharepoint2.contoso.com"
                        }
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPRemoteFarmTrust [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Ensure               = "Present";
            LocalWebAppUrl       = "https://local.sharepoint2.contoso.com";
            Name                 = "CentralSearchFarm";
            PsDscRunAsCredential = \$Credsspfarm;
            RemoteWebAppUrl      = "https://search.sharepoint.contoso.com";
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
