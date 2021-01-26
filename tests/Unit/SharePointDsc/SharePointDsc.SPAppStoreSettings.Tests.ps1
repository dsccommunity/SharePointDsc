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
$script:DSCResourceName = 'SPAppStoreSettings'
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
                Mock -CommandName Set-SPAppAcquisitionConfiguration -MockWith { }
                Mock -CommandName Set-SPOfficeStoreAppsDefaultActivation -MockWith { }

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
            Context -Name "The specified web application does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl          = "https://sharepoint.contoso.com"
                        AllowAppPurchases  = $true
                        AllowAppsForOffice = $true
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return $null
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).WebAppUrl | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception when executed" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified web application does not exist."
                }
            }

            Context -Name "The specified settings do not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl          = "https://sharepoint.contoso.com"
                        AllowAppPurchases  = $true
                        AllowAppsForOffice = $true
                    }

                    Mock -CommandName Get-SPAppAcquisitionConfiguration -MockWith {
                        return @{
                            Enabled = $false
                        }
                    }
                    Mock -CommandName Get-SPOfficeStoreAppsDefaultActivation -MockWith {
                        return @{
                            Enable = $false
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            Url = "https://sharepoint.contoso.com"
                        }
                    }
                }

                It "Should return values from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.AllowAppPurchases | Should -Be $false
                    $result.AllowAppsForOffice | Should -Be $false
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the settings" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPAppAcquisitionConfiguration
                    Assert-MockCalled Set-SPOfficeStoreAppsDefaultActivation
                }
            }

            Context -Name "The specified settings match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl          = "https://sharepoint.contoso.com"
                        AllowAppPurchases  = $true
                        AllowAppsForOffice = $true
                    }

                    Mock -CommandName Get-SPAppAcquisitionConfiguration -MockWith {
                        return @{
                            Enabled = $true
                        }
                    }
                    Mock -CommandName Get-SPOfficeStoreAppsDefaultActivation -MockWith {
                        return @{
                            Enable = $true
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            Url = "https://sharepoint.contoso.com"
                        }
                    }
                }

                It "Should return values from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.AllowAppPurchases | Should -Be $true
                    $result.AllowAppsForOffice | Should -Be $true
                }

                It "Should returns false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The specified setting does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl         = "https://sharepoint.contoso.com"
                        AllowAppPurchases = $true
                    }

                    Mock -CommandName Get-SPAppAcquisitionConfiguration -MockWith {
                        return @{
                            Enabled = $false
                        }
                    }
                    Mock -CommandName Get-SPOfficeStoreAppsDefaultActivation -MockWith {
                        return @{
                            Enable = $true
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            Url = "https://sharepoint.contoso.com"
                        }
                    }
                }

                It "Should return values from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.AllowAppPurchases | Should -Be $false
                    $result.AllowAppsForOffice | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the settings" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPAppAcquisitionConfiguration
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            WebAppUrl          = "http://sharepoint.contoso.com"
                            AllowAppPurchases  = $true
                            AllowAppsForOffice = $true
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            Name = "SharePoint Web Application"
                            Url  = "https://sharepoint.contoso.com"
                        }
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPAppStoreSettings SharePointWebApplication[0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            AllowAppPurchases    = \$True;
            AllowAppsForOffice   = \$True;
            PsDscRunAsCredential = \$Credsspfarm;
            WebAppUrl            = "http://sharepoint.contoso.com";
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
