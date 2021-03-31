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
$script:DSCResourceName = 'SPMachineTranslationServiceApp'
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

                #Initialize Tests
                $getTypeFullName = "Microsoft.Office.TranslationServices.TranslationServiceApplication"

                # Mocks for all contexts
                Mock -CommandName New-SPTranslationServiceApplication -MockWith { return @{ } }
                Mock -CommandName Get-SPServiceApplication -MockWith { }
                Mock -CommandName Remove-SPServiceApplication -MockWith { }
            }

            # Test contexts
            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Translation Service"
                        ProxyName       = "Machine Translation Service App Proxy"
                        ApplicationPool = "SharePoint Service Applications"
                        DatabaseServer  = "SPDB"
                        DatabaseName    = "Translation"
                        Ensure          = "Present"
                    }

                    Mock -CommandName New-SPTranslationServiceApplication -MockWith {
                        $returnVal = @{
                            Name = $testParams.Name
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected -Value {
                            return $true
                        } -PassThru

                        return $returnVal
                    }
                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = $testParams.ProxyName
                            DisplayName = $testParams.ProxyName
                        }
                        $proxy = $proxy | Add-Member -MemberType ScriptMethod `
                            -Name Delete `
                            -Value { } `
                            -PassThru
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
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
                    Assert-MockCalled New-SPTranslationServiceApplication
                }
            }

            Context -Name "When service applications exist in the current farm but the specific Translation app does not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Translation Service"
                        ApplicationPool = "SharePoint Service Applications"
                        DatabaseServer  = "SPDB"
                        DatabaseName    = "Translation"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = $testParams.Name
                            Name        = $testParams.Name
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

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "When a service application exists and is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Translation Service"
                        ProxyName       = "Machine Translation Service App Proxy"
                        ApplicationPool = "SharePoint Service Applications"
                        DatabaseServer  = "SPDB"
                        DatabaseName    = "Translation"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Machine Translation Service"
                            DisplayName     = $testParams.Name
                            Name            = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return (@{
                                    FullName = $getTypeFullName
                                })
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                            return $true
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = $testParams.ProxyName
                            DisplayName = $testParams.ProxyName
                        }
                        $proxy = $proxy | Add-Member -MemberType ScriptMethod `
                            -Name Delete `
                            -Value { } `
                            -PassThru
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When a service application exists and the app pool is not configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Translation Service"
                        ApplicationPool = "SharePoint Service Applications"
                        DatabaseServer  = "SPDB"
                        DatabaseName    = "Translation"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Machine Translation Service"
                            DisplayName     = $testParams.Name
                            Name            = $testParams.Name
                            ApplicationPool = @{
                                Name = "Wrong App Pool Name"
                            }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return (@{
                                    FullName = $getTypeFullName
                                })
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName Set-SPTranslationServiceApplication -MockWith {}
                }

                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the set service app cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Get-SPServiceApplication
                    Assert-MockCalled  Set-SPTranslationServiceApplication
                }
            }

            Context -Name "When the service application exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Translation Service"
                        ApplicationPool = "SharePoint Service Applications"
                        DatabaseServer  = "SPDB"
                        DatabaseName    = "Translation"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Machine Translation Service"
                            DisplayName     = $testParams.Name
                            Name            = $testParams.Name
                            ApplicationPool = @{
                                Name = "Wrong App Pool Name"
                            }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return (@{
                                    FullName = $getTypeFullName
                                })
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

                    Assert-MockCalled Get-SPServiceApplication
                    Assert-MockCalled Remove-SPServiceApplication
                }
            }

            Context -Name "When the service application doesn't exist and it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Translation Service"
                        ApplicationPool = "SharePoint Service Applications"
                        DatabaseServer  = "SPDB"
                        DatabaseName    = "Translation"
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
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name            = "Translation Service Application"
                            ProxyName       = "Translation Service Application Proxy"
                            ApplicationPool = "Service App Pool"
                            DatabaseServer  = "SQL01"
                            DatabaseName    = "Translation"
                            Ensure          = "Present"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName    = "TranslationServiceApplication"
                            DisplayName = "Translation Service Application"
                            Name        = "Translation Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "TranslationServiceApplication"
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
        SPMachineTranslationServiceApp [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            ApplicationPool      = "Service App Pool";
            DatabaseName         = "Translation";
            DatabaseServer       = \$ConfigurationData.NonNodeData.DatabaseServer;
            Ensure               = "Present";
            Name                 = "Translation Service Application";
            ProxyName            = "Translation Service Application Proxy";
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
