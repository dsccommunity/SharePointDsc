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
$script:DSCResourceName = 'SPAccessServiceApp'
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
                $getTypeFullName = "Microsoft.Office.Access.Services.MossHost.AccessServicesWebServiceApplication"

                # Mocks for all contexts
                Mock -CommandName New-SPAccessServicesApplication -MockWith { }
                Mock -CommandName Set-SPAccessServicesApplication -MockWith { }
                Mock -CommandName Remove-SPServiceApplication -MockWith { }

                try
                {
                    [Microsoft.SharePoint.SPServiceContext]
                }
                catch
                {
                    $CsharpCode2 = @"
    namespace Microsoft.SharePoint {
    public enum SPSiteSubscriptionIdentifier { Default };

    public class SPServiceContext {
        public static string GetContext(System.Object[] serviceApplicationProxyGroup, SPSiteSubscriptionIdentifier siteSubscriptionId) {
            return "";
        }
    }
    }
"@
                    Add-Type -TypeDefinition $CsharpCode2
                }
            }

            # Test contexts
            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test Access Services App"
                        DatabaseServer  = "SQL.contoso.local"
                        ApplicationPool = "Test App Pool"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
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
                    Assert-MockCalled New-SPAccessServicesApplication
                }
            }

            Context -Name "When service applications exist in the current farm but the specific Access Services app does not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test Access Services App"
                        DatabaseServer  = "SQL.contoso.local"
                        ApplicationPool = "Test App Pool"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = $testParams.Name
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
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
            }

            Context -Name "When a service application exists and is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test Access Services App"
                        DatabaseServer  = "SQL.contoso.local"
                        ApplicationPool = "Test App Pool"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Access Services Web Service Application"
                            DisplayName     = $testParams.Name
                            DatabaseServer  = $testParams.DatabaseServer
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPAccessServicesDatabaseServer -MockWith {
                        return @{
                            ServerName = $testParams.DatabaseServer
                        }
                    }
                }

                It "Should return Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When the service application exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "-"
                        DatabaseServer  = "-"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Access Services Web Service Application"
                            DisplayName     = $testParams.Name
                            DatabaseServer  = $testParams.DatabaseServer
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPAccessServicesDatabaseServer -MockWith {
                        return @{
                            ServerName = $testParams.DatabaseServer
                        }
                    }
                }

                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove service application cmdlet in the set method" {
                    Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPServiceApplication
                }
            }

            Context -Name "When the service application doesn't exist and it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "-"
                        DatabaseServer  = "-"
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
                            Name            = "Access Services Service Application"
                            DatabaseServer  = "SQL01"
                            ApplicationPool = "Service App Pool"
                            Ensure          = "Present"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Access Services Web Service Application"
                            DisplayName     = "Access Services Service Application"
                            Name            = "Access Services Service Application"
                            DatabaseServer  = "SQL01"
                            ApplicationPool = "Service App Pool"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
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
        SPAccessServiceApp AccessServicesServiceApplication
        {
            ApplicationPool      = "Service App Pool";
            DatabaseServer       = $ConfigurationData.NonNodeData.DatabaseServer;
            Ensure               = "Present";
            Name                 = "Access Services Service Application";
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
