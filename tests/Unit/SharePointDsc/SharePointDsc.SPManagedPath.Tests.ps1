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
$script:DSCResourceName = 'SPManagedPath'
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
                Mock -CommandName New-SPManagedPath -MockWith { }
                Mock -CommandName Remove-SPManagedPath -MockWith { }
            }

            # Test contexts
            Context -Name "The managed path does not exist and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl   = "http://sites.sharepoint.com"
                        RelativeUrl = "teams"
                        Explicit    = $false
                        HostHeader  = $false
                        Ensure      = "Present"
                    }

                    Mock -CommandName Get-SPManagedPath -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a host header path in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPManagedPath
                }

                $testParams.HostHeader = $true
                It "Should create a host header path in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPManagedPath
                }
            }

            Context -Name "The path exists but is of the wrong type" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl   = "http://sites.sharepoint.com"
                        RelativeUrl = "teams"
                        Explicit    = $false
                        HostHeader  = $false
                        Ensure      = "Present"
                    }

                    Mock -CommandName Get-SPManagedPath -MockWith {
                        return @{
                            Name = $testParams.RelativeUrl
                            Type = "ExplicitInclusion"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "The path exists and is the correct type" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl   = "http://sites.sharepoint.com"
                        RelativeUrl = "teams"
                        Explicit    = $false
                        HostHeader  = $false
                        Ensure      = "Present"
                    }

                    Mock -CommandName Get-SPManagedPath -MockWith {
                        return @{
                            Name = $testParams.RelativeUrl
                            Type = "WildcardInclusion"
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

            Context -Name "The managed path exists but shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl   = "http://sites.sharepoint.com"
                        RelativeUrl = "teams"
                        Explicit    = $false
                        HostHeader  = $false
                        Ensure      = "Absent"
                    }

                    Mock -CommandName Get-SPManagedPath -MockWith {
                        return @{
                            Name = $testParams.RelativeUrl
                            Type = "WildcardInclusion"
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove cmdlet from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPManagedPath
                }
            }

            Context -Name "The managed path doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl   = "http://sites.sharepoint.com"
                        RelativeUrl = "teams"
                        Explicit    = $false
                        HostHeader  = $false
                        Ensure      = "Absent"
                    }

                    Mock -CommandName Get-SPManagedPath -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the set method" {
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
                            WebAppUrl   = "http://sharepoint.contoso.com"
                            RelativeUrl = "teams"
                            Explicit    = $false
                            HostHeader  = $true
                            Ensure      = "Present"
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $spWebApp = [PSCustomObject]@{
                            Url = "http://sharepoint.contoso.com"
                        }
                        return $spWebApp
                    }

                    Mock -CommandName Get-SPManagedPath -MockWith {
                        $spManagedPath = [PSCustomObject]@{
                            Name = "teams"
                            Type = "WildcardInclusion"
                        }
                        return $spManagedPath
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPManagedPath [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Ensure               = "Present";
            Explicit             = \$False;
            HostHeader           = \$True;
            PsDscRunAsCredential = \$Credsspfarm;
            RelativeUrl          = "teams";
            WebAppUrl            = "http://sharepoint.contoso.com";
        }
        SPManagedPath [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Ensure               = "Present";
            Explicit             = \$False;
            HostHeader           = \$True;
            PsDscRunAsCredential = \$Credsspfarm;
            RelativeUrl          = "teams";
            WebAppUrl            = "http://sharepoint.contoso.com";
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
