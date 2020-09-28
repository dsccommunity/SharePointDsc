[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPBCSServiceApp'
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
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                #Initialise tests
                $getTypeFullName = "Microsoft.SharePoint.BusinessData.SharedService.BdcServiceApplication"

                # Mocks for all contexts
                Mock -CommandName Remove-SPServiceApplication -MockWith { }
            }

            # Test contexts
            Context -Name "When no service applications exist in the current farm and it should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ProxyName       = "TestApp Proxy"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        DatabaseServer  = "TestServer\Instance"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                    Mock -CommandName New-SPBusinessDataCatalogServiceApplication -MockWith {
                        $returnVal = @{
                            Name = "ServiceApp"
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected -Value {
                            return $true
                        } -PassThru

                        return $returnVal
                    }
                    Mock -CommandName New-SPBusinessDataCatalogServiceApplicationProxy -MockWith { }
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

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }
                }

                It "Should return false when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPBusinessDataCatalogServiceApplication
                }
            }

            Context -Name "When Ensure=Present but DatabaseName isn't specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                    Mock -CommandName New-SPBusinessDataCatalogServiceApplication -MockWith { }
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter DatabaseName and DatabaseServer are required when Ensure=Present"
                }
            }

            Context -Name "When service applications exist in the current farm with the same name but is the wrong type" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        DatabaseServer  = "TestServer\Instance"
                        Ensure          = "Present"
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
                        ProxyName       = "TestApp Proxy"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        DatabaseServer  = "TestServer\Instance"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Business Data Connectivity Service Application"
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

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When a service application exists and it should, but the app pool is not configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        DatabaseServer  = "TestServer\Instance"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Business Data Connectivity Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = "Wrong App Pool Name" }
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
                    Mock -CommandName Get-SPServiceApplicationPool -MockWith { return @{ Name = $testParams.ApplicationPool } }
                    Mock -CommandName Set-SPBusinessDataCatalogServiceApplication -MockWith { }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the update service app cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Get-SPServiceApplicationPool
                    Assert-MockCalled Set-SPBusinessDataCatalogServiceApplication -ParameterFilter { $ApplicationPool.Name -eq $testParams.ApplicationPool }
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
                            TypeName        = "Business Data Connectivity Service Application"
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

                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
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

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
