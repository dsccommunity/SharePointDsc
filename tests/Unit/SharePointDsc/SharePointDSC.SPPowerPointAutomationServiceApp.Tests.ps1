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
$script:DSCResourceName = 'SPPowerPointAutomationServiceApp'
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
                $getTypeFullName = "Microsoft.Office.Server.PowerPoint.Administration.PowerPointConversionServiceApplication"

                # Mocks for all
                Mock -CommandName Get-SPServiceApplication -MockWith { }
                Mock -CommandName Get-SPServiceApplicationPool -MockWith { }
                Mock -CommandName Get-SPServiceApplicationProxy -MockWith { }

                Mock -CommandName New-SPPowerPointConversionServiceApplication -MockWith { }
                Mock -CommandName New-SPPowerPointConversionServiceApplicationProxy -MockWith { }
                Mock -CommandName Remove-SPServiceApplication -MockWith { }

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
            Context -Name "When Ensure is Absent and we specify additional paramters" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                            = "Power Point Automation Service Application"
                        ProxyName                       = "Power Point Automation Service Application Proxy"
                        ApplicationPool                 = "SharePoint Services App Pool"
                        CacheExpirationPeriodInSeconds  = 600
                        MaximumConversionsPerWorker     = 5
                        WorkerKeepAliveTimeoutInSeconds = 120
                        WorkerProcessCount              = 3
                        WorkerTimeoutInSeconds          = 300
                        Ensure                          = "Absent"
                    }
                }

                It "Should throw an exception as additional parameters are not allowed when Ensure = 'Absent'" {
                    { Get-TargetResource @testParams } | Should -Throw "You cannot use any of the parameters when Ensure is specified as Absent"
                    { Test-TargetResource @testParams } | Should -Throw "You cannot use any of the parameters when Ensure is specified as Absent"
                    { Set-TargetResource @testParams } | Should -Throw "You cannot use any of the parameters when Ensure is specified as Absent"
                }
            }

            Context -Name "When Ensure is Present but we don't specify an ApplicationPool" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                            = "Power Point Automation Service Application"
                        ProxyName                       = "Power Point Automation Service Application Proxy"
                        CacheExpirationPeriodInSeconds  = 600
                        MaximumConversionsPerWorker     = 5
                        WorkerKeepAliveTimeoutInSeconds = 120
                        WorkerProcessCount              = 3
                        WorkerTimeoutInSeconds          = 300
                        Ensure                          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return $null
                    }
                }

                It "Should throw an exception as additional parameters are not allowed when Ensure = 'Absent'" {
                    { Get-TargetResource @testParams } | Should -Throw "An Application Pool is required to configure the PowerPoint Automation Service Application"
                    { Test-TargetResource @testParams } | Should -Throw "An Application Pool is required to configure the PowerPoint Automation Service Application"
                    { Set-TargetResource @testParams } | Should -Throw "An Application Pool is required to configure the PowerPoint Automation Service Application"
                }
            }



            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                            = "Power Point Automation Service Application"
                        ProxyName                       = "Power Point Automation Service Application Proxy"
                        ApplicationPool                 = "SharePoint Services App Pool"
                        CacheExpirationPeriodInSeconds  = 600
                        MaximumConversionsPerWorker     = 5
                        WorkerKeepAliveTimeoutInSeconds = 120
                        WorkerProcessCount              = 3
                        WorkerTimeoutInSeconds          = 300
                        Ensure                          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName New-SPPowerPointConversionServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName                     = $testParams.Name
                            ApplicationPool                 = @{ Name = $testParams.ApplicationPool }
                            CacheExpirationPeriodInSeconds  = 0
                            MaximumConversionsPerWorker     = 0
                            WorkerKeepAliveTimeoutInSeconds = 0
                            WorkerProcessCount              = 0
                            WorkerTimeoutInSeconds          = 0
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            return @{
                                DisplayName                     = $testParams.Name
                                ApplicationPool                 = @{ Name = $testParams.ApplicationPool }
                                CacheExpirationPeriodInSeconds  = $testParams.CacheExpirationPeriodInSeconds
                                MaximumConversionsPerWorker     = $testParams.MaximumConversionsPerWorker
                                WorkerKeepAliveTimeoutInSeconds = $testParams.WorkerKeepAliveTimeoutInSeconds
                                WorkerProcessCount              = $testParams.WorkerProcessCount
                                WorkerTimeoutInSeconds          = $testParams.WorkerTimeoutInSeconds
                            }
                        } -PassThru -Force
                        return $($spServiceApp)
                    }

                    Mock -CommandName New-SPPowerPointConversionServiceApplicationProxy -MockWith { }
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
                It "Should create a new PowerPoint Automation Service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPServiceApplicationPool -Times 1
                    Assert-MockCalled New-SPPowerPointConversionServiceApplication -Times 1
                    Assert-MockCalled New-SPPowerPointConversionServiceApplicationProxy -Times 1
                }

            }

            Context -Name "When service applications exist in the current farm but the specific PowerPoint Automation Services app does not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                            = "Power Point Automation Service Application"
                        ProxyName                       = "Power Point Automation Service Application Proxy"
                        ApplicationPool                 = "SharePoint Services App Pool"
                        CacheExpirationPeriodInSeconds  = 600
                        MaximumConversionsPerWorker     = 5
                        WorkerKeepAliveTimeoutInSeconds = 120
                        WorkerProcessCount              = 3
                        WorkerTimeoutInSeconds          = 300
                        Ensure                          = "Present"
                    }


                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName New-SPPowerPointConversionServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName                     = $testParams.Name
                            ApplicationPool                 = @{ Name = $testParams.ApplicationPool }
                            CacheExpirationPeriodInSeconds  = 0
                            MaximumConversionsPerWorker     = 0
                            WorkerKeepAliveTimeoutInSeconds = 0
                            WorkerProcessCount              = 0
                            WorkerTimeoutInSeconds          = 0
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            return @{
                                DisplayName                     = $testParams.Name
                                ApplicationPool                 = @{ Name = $testParams.ApplicationPool }
                                CacheExpirationPeriodInSeconds  = $testParams.CacheExpirationPeriodInSeconds
                                MaximumConversionsPerWorker     = $testParams.MaximumConversionsPerWorker
                                WorkerKeepAliveTimeoutInSeconds = $testParams.WorkerKeepAliveTimeoutInSeconds
                                WorkerProcessCount              = $testParams.WorkerProcessCount
                                WorkerTimeoutInSeconds          = $testParams.WorkerTimeoutInSeconds
                            }
                        } -PassThru -Force
                        return $($spServiceApp)
                    }

                    Mock -CommandName New-SPPowerPointConversionServiceApplicationProxy -MockWith { }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = "Microsoft.Office.UnKnownWebServiceApplication"
                            }
                        } -PassThru -Force
                        return $($spServiceApp)
                    }
                }

                It "Should return 'Absent' from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }
                It "Should return 'false' from the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
                It "Should create a new Power Point Automation Service Application from the Set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled  Get-SPServiceApplicationPool
                    Assert-MockCalled New-SPPowerPointConversionServiceApplication
                    Assert-MockCalled New-SPPowerPointConversionServiceApplicationProxy
                }
            }

            Context -Name "When service applications should exist but the application pool doesn't exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                            = "Power Point Automation Service Application"
                        ProxyName                       = "Power Point Automation Service Application Proxy"
                        ApplicationPool                 = "SharePoint Services App Pool"
                        CacheExpirationPeriodInSeconds  = 600
                        MaximumConversionsPerWorker     = 5
                        WorkerKeepAliveTimeoutInSeconds = 120
                        WorkerProcessCount              = 3
                        WorkerTimeoutInSeconds          = 300
                        Ensure                          = "Present"
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
                        return $($spServiceApp)
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return $null
                    }
                }

                It "Should return 'Absent' from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }
                It "Should return 'false' from the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
                It "Should create a new Power Point Automation Service Application from the Set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified application pool does not exist"
                }
            }

            Context -Name "When a service application exists and is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                            = "Power Point Automation Service Application"
                        ProxyName                       = "Power Point Automation Service Application Proxy"
                        ApplicationPool                 = "SharePoint Services App Pool"
                        CacheExpirationPeriodInSeconds  = 600
                        MaximumConversionsPerWorker     = 5
                        WorkerKeepAliveTimeoutInSeconds = 120
                        WorkerProcessCount              = 3
                        WorkerTimeoutInSeconds          = 300
                        Ensure                          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName                     = $testParams.Name
                            ApplicationPool                 = @{ Name = $testParams.ApplicationPool }
                            CacheExpirationPeriodInSeconds  = $testParams.CacheExpirationPeriodInSeconds
                            MaximumConversionsPerWorker     = $testParams.MaximumConversionsPerWorker
                            WorkerKeepAliveTimeoutInSeconds = $testParams.WorkerKeepAliveTimeoutInSeconds
                            WorkerProcessCount              = $testParams.WorkerProcessCount
                            WorkerTimeoutInSeconds          = $testParams.WorkerTimeoutInSeconds
                        }
                        $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
                            }
                        } -PassThru -Force

                        $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected `
                            -Value {
                            return $true
                        } -PassThru -Force

                        return $($spServiceApp)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @{
                            Name = $testParams.ProxyName
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

            Context -Name "When a service application exists but has a new Proxy Assignment" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                            = "Power Point Automation Service Application"
                        ProxyName                       = "Power Point Automation Service Application Proxy"
                        ApplicationPool                 = "SharePoint Services App Pool"
                        CacheExpirationPeriodInSeconds  = 600
                        MaximumConversionsPerWorker     = 5
                        WorkerKeepAliveTimeoutInSeconds = 120
                        WorkerProcessCount              = 3
                        WorkerTimeoutInSeconds          = 300
                        Ensure                          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName                     = $testParams.Name
                            ApplicationPool                 = @{ Name = $testParams.ApplicationPool }
                            CacheExpirationPeriodInSeconds  = $testParams.CacheExpirationPeriodInSeconds
                            MaximumConversionsPerWorker     = $testParams.MaximumConversionsPerWorker
                            WorkerKeepAliveTimeoutInSeconds = $testParams.WorkerKeepAliveTimeoutInSeconds
                            WorkerProcessCount              = $testParams.WorkerProcessCount
                            WorkerTimeoutInSeconds          = $testParams.WorkerTimeoutInSeconds

                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
                            }
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType SCriptMethod `
                            -Name IsConnected `
                            -Value {
                            return $true
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value {
                            return @{
                                DisplayName                     = $testParams.Name
                                ApplicationPool                 = @{ Name = $testParams.ApplicationPool }
                                CacheExpirationPeriodInSeconds  = $testParams.CacheExpirationPeriodInSeconds
                                MaximumConversionsPerWorker     = $testParams.MaximumConversionsPerWorker
                                WorkerKeepAliveTimeoutInSeconds = $testParams.WorkerKeepAliveTimeoutInSeconds
                                WorkerProcessCount              = $testParams.WorkerProcessCount
                                WorkerTimeoutInSeconds          = $testParams.WorkerTimeoutInSeconds
                            }
                        } -PassThru -Force

                        return $($spServiceApp)
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $spServiceAppProxy = [PSCustomObject]@{
                            Name = "$($testParams.ProxyName) other"
                        }
                        $spServiceAppProxy | Add-Member -MemberType SCriptMethod `
                            -Name Delete `
                            -Value {
                            return $null
                        } -PassThru -Force

                        return $spServiceAppProxy
                    }
                }

                It "Should return Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
                It "Should call Get-SPServiceApplicationProxy when Set method is called." {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPServiceApplicationProxy
                }
            }

            Context -Name "When a service application exists but has a new Application Pool Assignment" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                            = "Power Point Automation Service Application"
                        ProxyName                       = "Power Point Automation Service Application Proxy"
                        ApplicationPool                 = "SharePoint Services App Pool"
                        CacheExpirationPeriodInSeconds  = 600
                        MaximumConversionsPerWorker     = 5
                        WorkerKeepAliveTimeoutInSeconds = 120
                        WorkerProcessCount              = 3
                        WorkerTimeoutInSeconds          = 300
                        Ensure                          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = "Other SharePoint Services App Pool" }
                        }
                        $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }
                }

                It "Should return Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }
                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "When the service application exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name   = "Power Point Automation Service Application"
                        Ensure = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = $getTypeFullName
                            }
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

            Context -Name "When the service application doesn't exist and it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name   = "Power Point Automation Service Application"
                        Ensure = "Absent"
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

            Context -Name "When a service application doesn't exists but it should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                            = "Power Point Automation Service Application"
                        ProxyName                       = "Power Point Automation Service Application Proxy"
                        ApplicationPool                 = "SharePoint Services App Pool"
                        CacheExpirationPeriodInSeconds  = 600
                        MaximumConversionsPerWorker     = 5
                        WorkerKeepAliveTimeoutInSeconds = 120
                        WorkerProcessCount              = 3
                        WorkerTimeoutInSeconds          = 300
                        Ensure                          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }
                }

                It "Should return Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

        }
    }
}
finally
{
    Invoke-TestCleanup
}
