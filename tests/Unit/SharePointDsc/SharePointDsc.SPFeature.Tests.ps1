[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPFeature'
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
                Mock -CommandName Enable-SPFeature -MockWith { }
                Mock -CommandName Disable-SPFeature -MockWith { }
            }

            # Test contexts
            Context -Name "A feature that is not installed in the farm should be turned on" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name         = "DemoFeature"
                        FeatureScope = "Farm"
                        Url          = "http://site.sharepoint.com"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPFeature -MockWith { return $null }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "A farm scoped feature is not enabled and should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name         = "DemoFeature"
                        FeatureScope = "Farm"
                        Url          = "http://site.sharepoint.com"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPFeature -MockWith {
                        return $null
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should enable the feature in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Enable-SPFeature
                }
            }

            Context -Name "A site collection scoped feature is not enabled and should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name         = "DemoFeature"
                        FeatureScope = "Site"
                        Url          = "http://site.sharepoint.com"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPFeature -MockWith {
                        return $null
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should enable the feature in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Enable-SPFeature
                }
            }

            Context -Name "A farm scoped feature is enabled and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name         = "DemoFeature"
                        FeatureScope = "Farm"
                        Url          = "http://site.sharepoint.com"
                        Ensure       = "Absent"
                    }

                    Mock -CommandName Get-SPFeature -MockWith {
                        return @{ }
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should enable the feature in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Disable-SPFeature
                }
            }

            Context -Name "A site collection scoped feature is enabled and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name         = "DemoFeature"
                        FeatureScope = "Site"
                        Url          = "http://site.sharepoint.com"
                        Ensure       = "Absent"
                    }

                    Mock -CommandName Get-SPFeature -MockWith {
                        return @{ }
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should enable the feature in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Disable-SPFeature
                }
            }

            Context -Name "A farm scoped feature is enabled and should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name         = "DemoFeature"
                        FeatureScope = "Farm"
                        Url          = "http://site.sharepoint.com"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPFeature -MockWith { return @{ } }
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A site collection scoped feature is enabled and should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name         = "DemoFeature"
                        FeatureScope = "Site"
                        Url          = "http://site.sharepoint.com"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPFeature -MockWith { return @{ } }
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A site collection scoped features is enabled but has the wrong version" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name         = "DemoFeature"
                        FeatureScope = "Site"
                        Url          = "http://site.sharepoint.com"
                        Version      = "1.1.0.0"
                        Ensure       = "Present"
                    }

                    Mock -CommandName Get-SPFeature -MockWith { return @{ Version = "1.0.0.0" } }
                }

                It "Should return the version from the get method" {
                    (Get-TargetResource @testParams).Version | Should -Be "1.0.0.0"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "reactivates the feature in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Disable-SPFeature
                    Assert-MockCalled Enable-SPFeature
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name         = "Feature 1"
                            FeatureScope = "Farm"
                            Url          = "http://ca.contoso.com"
                            Version      = "1.0.0.0"
                            Ensure       = "Present"
                        }
                    }

                    $spMajorVersion = (Get-SPDscInstalledProductVersion).FileMajorPart

                    Mock -CommandName Get-SPFeature -MockWith {
                        $spFeature = [PSCustomObject]@{
                            DisplayName = "Feature 1"
                            Scope       = "Farm"
                            Version     = $spMajorVersion.ToString()
                        }
                        return $spFeature
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPFeature [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            DependsOn            = "\[SPFarm\]FarmConfig";
            Ensure               = "Present";
            FeatureScope         = "Farm";
            Name                 = "Feature 1";
            PsDscRunAsCredential = \$Credsspfarm;
            Url                  = "http://ca.contoso.com";
            Version              = "1.0.0.0";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource -Scope 'Farm' -DependsOn "[SPFarm]FarmConfig" | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
