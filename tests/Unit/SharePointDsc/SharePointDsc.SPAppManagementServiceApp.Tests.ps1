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
$script:DSCResourceName = 'SPAppManagementServiceApp'
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

                #initialise tests
                $getTypeFullName = "Microsoft.SharePoint.AppManagement.AppManagementServiceApplication"

                # Mocks for all contexts
                Mock -CommandName Remove-SPServiceApplication -MockWith { }
            }

            # Test contexts
            Context -Name "When no service applications exist in the current farm but it should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        Ensure          = "Present"
                        DatabaseServer  = "TestServer\Instance"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                    Mock -CommandName New-SPAppManagementServiceApplication -MockWith { return  @(@{ }) }
                    Mock -CommandName New-SPAppManagementServiceApplicationProxy -MockWith { return $null }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }
                }

                It "Should return false when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPAppManagementServiceApplication
                }
            }

            Context -Name "When service applications exist in the current farm with the same name but is the wrong type" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        Ensure          = "Present"
                        DatabaseServer  = "TestServer\Instance"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = $testParams.Name
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

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }
                }

            }

            Context -Name "When a service application exists and it should, and is also configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        Ensure          = "Present"
                        DatabaseServer  = "TestServer\Instance"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "App Management Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                            return $true
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "AppManagement Proxy"
                            DisplayName = "AppManagement Proxy"
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
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }
                }

                It "Should return true when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When a service application exists and it should, but the app pool is not configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        Ensure          = "Present"
                        DatabaseServer  = "TestServer\Instance"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "App Management Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = "Wrong app pool" }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force

                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscAppServiceUpdateCalled = $true
                        } -PassThru
                        return $spServiceApp
                    }
                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        @{ Name = $testParams.ApplicationPool }
                    }
                }

                It "Should return false when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the update service app cmdlet from the set method" {
                    $Global:SPDscAppServiceUpdateCalled = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPServiceApplicationPool
                    $Global:SPDscAppServiceUpdateCalled | Should -Be $true
                }
            }

            Context -Name "When a service application exists and it should, but no proxy exists" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        Ensure          = "Present"
                        DatabaseServer  = "TestServer\Instance"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "App Management Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                            return $false
                        } -PassThru -Force

                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscAppServiceUpdateCalled = $true
                        } -PassThru
                        return $spServiceApp
                    }
                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        @{ Name = $testParams.ApplicationPool } }
                    Mock -CommandName New-SPAppManagementServiceApplicationProxy -MockWith { return $null }
                }

                It "Should return an empty ProxyName from the get method" {
                    (Get-TargetResource @testParams).ProxyName | Should -Be ""
                }

                It "Should return false when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the update service app cmdlet from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPAppManagementServiceApplicationProxy
                }
            }

            Context -Name "When a service app needs to be created and no database paramsters are provided" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                    Mock -CommandName New-SPAppManagementServiceApplication -MockWith { return  @(@{ }) }
                    Mock -CommandName New-SPAppManagementServiceApplicationProxy -MockWith { return $null }
                }

                It "Should not throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPAppManagementServiceApplication
                }
            }

            Context -Name "When the service application exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "-"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "App Management Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        return $spServiceApp
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove service application cmdlet in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPServiceApplication
                }
            }

            Context -Name "When the serivce application doesn't exist and it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "-"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should returns true when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name            = "AppManagementServiceApp"
                            ProxyName       = "AppManagementServiceApp Proxy"
                            ApplicationPool = "Service App Pool"
                            DatabaseName    = "AppManagementDB"
                            DatabaseServer  = "SQL01"
                            Ensure          = "Present"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName    = "AppManagementServiceApplication"
                            DisplayName = "App Management Service Application"
                            Name        = "App Management Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = 'AppManagementServiceApplication'
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
        SPAppManagementServiceApp AppManagementServiceApplication[0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            ApplicationPool      = "Service App Pool";
            DatabaseName         = "AppManagementDB";
            DatabaseServer       = \$ConfigurationData.NonNodeData.DatabaseServer;
            Ensure               = "Present";
            Name                 = "AppManagementServiceApp";
            ProxyName            = "AppManagementServiceApp Proxy";
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
