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
$script:DSCResourceName = 'SPSubscriptionSettingsServiceApp'
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

                # Initialize tests
                $getTypeFullName = "Microsoft.SharePoint.SPSubscriptionSettingsServiceApplication"

                # Mocks for all contexts
                Mock -CommandName New-SPSubscriptionSettingsServiceApplication -MockWith {
                    return @{ }
                }
                Mock -CommandName New-SPSubscriptionSettingsServiceApplicationProxy -MockWith {
                    return @{ }
                }
                Mock -CommandName Set-SPSubscriptionSettingsServiceApplication -MockWith { }
                Mock -CommandName Remove-SPServiceApplication -MockWith { }
            }

            # Test contexts
            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        DatabaseServer  = "TestServer\Instance"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }

                    Mock -CommandName New-SPSubscriptionSettingsServiceApplication -MockWith {
                        return @{ }
                    }

                    Mock -CommandName New-SPSubscriptionSettingsServiceApplicationProxy -MockWith {
                        return @{ }
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
                    Assert-MockCalled New-SPSubscriptionSettingsServiceApplication
                    Assert-MockCalled New-SPSubscriptionSettingsServiceApplicationProxy
                }
            }

            Context -Name "When service applications exist in the current farm but the specific subscription settings service app does not" -Fixture {
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

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }
            }

            Context -Name "When the service application exist in the current farm but has no proxy" -Fixture {
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
                            TypeName        = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                        }

                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType NoteProperty `
                                -Name FullName `
                                -Value $getTypeFullName `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetProperties `
                                -Value {
                                param($x)
                                return @(
                                    (New-Object -TypeName "Object" |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Name `
                                            -Value "Database" `
                                            -PassThru |
                                        Add-Member -MemberType ScriptMethod `
                                            -Name GetValue `
                                            -Value {
                                            param($x)
                                            return (@{
                                                    FullName             = $getTypeFullName
                                                    Name                 = "Test_DB"
                                                    NormalizedDataSource = "TestServer\Instance"
                                                    FailoverServer       = @{
                                                        Name = "DBServer_Failover"
                                                    }
                                                })
                                        } -PassThru
                                    )
                                )
                            } -PassThru
                        } -PassThru -Force

                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected `
                            -Value {
                            param($x)
                            return $false
                        } -PassThru -Force

                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @(
                            @{
                                Name = "Managed Metadata Service Application Proxy"
                            }
                        )
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should create the proxy in the Set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPSubscriptionSettingsServiceApplicationProxy
                }

                It "Should return false from the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "When a service application exists and is configured correctly" -Fixture {
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
                            TypeName        = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                        }

                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType NoteProperty `
                                -Name FullName `
                                -Value $getTypeFullName `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetProperties `
                                -Value {
                                param($x)
                                return @(
                                    (New-Object -TypeName "Object" |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Name `
                                            -Value "Database" `
                                            -PassThru |
                                        Add-Member -MemberType ScriptMethod `
                                            -Name GetValue `
                                            -Value {
                                            param($x)
                                            return (@{
                                                    FullName             = $getTypeFullName
                                                    Name                 = "Test_DB"
                                                    NormalizedDataSource = "TestServer\Instance"
                                                    FailoverServer       = @{
                                                        Name = "DBServer_Failover"
                                                    }
                                                })
                                        } -PassThru
                                    )
                                )
                            } -PassThru
                        } -PassThru -Force

                        return $spServiceApp
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
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        DatabaseName    = "Test_DB"
                        DatabaseServer  = "TestServer\Instance"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [pscustomobject]@{
                            TypeName        = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = "Wrong App Pool Name" }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            $Global:SPDscSubscriptionServiceUpdateCalled = $true
                        } -PassThru

                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType NoteProperty `
                                -Name FullName `
                                -Value $getTypeFullName `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetProperties `
                                -Value {
                                param($x)
                                return @(
                                    (New-Object -TypeName "Object" |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Name `
                                            -Value "Database" `
                                            -PassThru |
                                        Add-Member -MemberType ScriptMethod `
                                            -Name GetValue `
                                            -Value {
                                            param($x)
                                            return (@{
                                                    FullName             = $getTypeFullName
                                                    Name                 = "Test_DB"
                                                    NormalizedDataSource = "TestServer\Instance"
                                                    FailoverServer       = @{
                                                        Name = "DBServer_Failover"
                                                    }
                                                })
                                        } -PassThru
                                    )
                                )
                            } -PassThru
                        } -PassThru -Force

                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationPool {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the update service app cmdlet from the set method" {
                    $Global:SPDscSubscriptionServiceUpdateCalled = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPServiceApplicationPool
                    $Global:SPDscSubscriptionServiceUpdateCalled | Should -Be $true
                }
            }

            Context -Name "When a service app needs to be created and no database parameters are provided" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "Test App Pool"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }
                }

                It "should not throw an exception in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPSubscriptionSettingsServiceApplication
                    Assert-MockCalled New-SPSubscriptionSettingsServiceApplicationProxy
                }
            }

            Context -Name "When the service app exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "-"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            New-Object -TypeName "Object" |
                            Add-Member -MemberType NoteProperty `
                                -Name FullName `
                                -Value $getTypeFullName `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetProperties `
                                -Value {
                                param($x)
                                return @(
                                    (New-Object -TypeName "Object" |
                                        Add-Member -MemberType NoteProperty `
                                            -Name Name `
                                            -Value "Database" `
                                            -PassThru |
                                        Add-Member -MemberType ScriptMethod `
                                            -Name GetValue `
                                            -Value {
                                            param($x)
                                            return (@{
                                                    FullName             = $getTypeFullName
                                                    Name                 = "Test_DB"
                                                    NormalizedDataSource = "TestServer\Instance"
                                                    FailoverServer       = @{
                                                        Name = "DBServer_Failover"
                                                    }
                                                })
                                        } -PassThru
                                    )
                                )
                            } -PassThru
                        } -PassThru -Force
                        return $spServiceApp
                    }
                }

                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPServiceApplication
                }
            }

            Context -Name "When the service app doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "-"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
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
