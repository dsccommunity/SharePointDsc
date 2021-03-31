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
$script:DSCResourceName = 'SPWorkManagementServiceApp'
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

                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    # Initialize tests
                    $getTypeFullName = "Microsoft.Office.Server.WorkManagement.WorkManagementServiceApplication"

                    # Mocks for all contexts
                    Mock -CommandName Remove-SPServiceApplication -MockWith { }
                    Mock -CommandName New-SPWorkManagementServiceApplication -MockWith { }
                    Mock -CommandName New-SPWorkManagementServiceApplicationProxy -MockWith { }

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
            }

            # Test contexts
            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
            {
                Context -Name "When a service application exists and Ensure equals 'Absent'" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name   = "Test Work Management App"
                            Ensure = "Absent"
                        }

                        Mock -CommandName Get-SPServiceApplication {
                            $spServiceApp = [pscustomobject]@{
                                DisplayName     = $testParams.Name
                                Name            = $testParams.Name
                                ApplicationPool = @{ Name = "Wrong App Pool Name" }
                            }
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                return @{ FullName = $getTypeFullName }
                            } -PassThru -Force
                            return $spServiceApp
                        }
                    }

                    It "Should return true when the Test method is called" {
                        Test-TargetResource @testParams | Should -Be $false
                    }

                    It "Should call the remove service app cmdlet from the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled Remove-SPServiceApplication
                    }
                }

                Context -Name "When Ensure=Present and ApplicationPool parameter is missing" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name   = "Test Work Management App"
                            Ensure = "Present"
                        }

                        Mock -CommandName Get-SPServiceApplication { return $null }
                    }

                    It "Should throw an exception in the set method" {
                        { Set-TargetResource @testParams } | Should -Throw "Parameter ApplicationPool is required unless service is being removed(Ensure='Absent')"
                    }
                }

                Context -Name "When no service applications exist in the current farm" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name            = "Test Work Management App"
                            ApplicationPool = "Test App Pool"
                            ProxyName       = "Test Work Management App Proxy"
                        }

                        Mock -CommandName Get-SPServiceApplication { return $null }
                    }

                    It "Should return null from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                    }

                    It "Should return false when the Test method is called" {
                        Test-TargetResource @testParams | Should -Be $false
                    }

                    It "Should create a new service application in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled New-SPWorkManagementServiceApplication
                    }
                }

                Context -Name "When service applications exist in the current farm but the specific Work Management app does not" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name            = "Test Work Management App"
                            ApplicationPool = "Test App Pool"
                        }

                        Mock -CommandName Get-SPServiceApplication {
                            $spServiceApp = [pscustomobject]@{
                                DisplayName = $testParams.Name
                                Name        = $testParams.Name
                            }
                            $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                return @{ FullName = "Microsoft.Office.UnKnownWebServiceApplication" }
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

                    It "Should create a new service application in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled New-SPWorkManagementServiceApplication
                    }
                }

                Context -Name "When a service application exists and is configured correctly" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name                                          = "Test Work Management App"
                            ApplicationPool                               = "Test App Pool"
                            MinimumTimeBetweenEwsSyncSubscriptionSearches = 10
                            MinimumTimeBetweenProviderRefreshes           = 10
                            MinimumTimeBetweenSearchQueries               = 10
                            NumberOfSubscriptionSyncsPerEwsSyncRun        = 10
                            NumberOfUsersEwsSyncWillProcessAtOnce         = 10
                            NumberOfUsersPerEwsSyncBatch                  = 10
                        }

                        Mock -CommandName Get-SPServiceApplication {
                            $spServiceApp = [pscustomobject]@{
                                DisplayName     = $testParams.Name
                                Name            = $testParams.Name
                                ApplicationPool = @{ Name = $testParams.ApplicationPool }
                                AdminSettings   = @{
                                    MinimumTimeBetweenEwsSyncSubscriptionSearches = (New-TimeSpan -Minutes 10)
                                    MinimumTimeBetweenProviderRefreshes           = (New-TimeSpan -Minutes 10)
                                    MinimumTimeBetweenSearchQueries               = (New-TimeSpan -Minutes 10)
                                    NumberOfSubscriptionSyncsPerEwsSyncRun        = 10
                                    NumberOfUsersEwsSyncWillProcessAtOnce         = 10
                                    NumberOfUsersPerEwsSyncBatch                  = 10
                                }
                            }
                            $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                return @{ FullName = $getTypeFullName }
                            } -PassThru -Force
                            return $spServiceApp
                        }
                    }

                    It "Should return values from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                    }

                    It "Should return true when the Test method is called" {
                        Test-TargetResource @testParams | Should -Be $true
                    }
                }

                Context -Name "When a service application exists and is not configured correctly" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            Name                                          = "Test Work Management App"
                            ApplicationPool                               = "Test App Pool"
                            MinimumTimeBetweenEwsSyncSubscriptionSearches = 20
                            MinimumTimeBetweenProviderRefreshes           = 20
                            MinimumTimeBetweenSearchQueries               = 20
                            NumberOfSubscriptionSyncsPerEwsSyncRun        = 20
                            NumberOfUsersEwsSyncWillProcessAtOnce         = 20
                            NumberOfUsersPerEwsSyncBatch                  = 20
                        }

                        Mock -CommandName Get-SPServiceApplication {
                            $spServiceApp = [pscustomobject]@{
                                DisplayName     = $testParams.Name
                                Name            = $testParams.Name
                                ApplicationPool = @{ Name = "Wrong App Pool Name" }
                                AdminSettings   = @{
                                    MinimumTimeBetweenEwsSyncSubscriptionSearches = (New-TimeSpan -Minutes 10)
                                    MinimumTimeBetweenProviderRefreshes           = (New-TimeSpan -Minutes 10)
                                    MinimumTimeBetweenSearchQueries               = (New-TimeSpan -Minutes 10)
                                    NumberOfSubscriptionSyncsPerEwsSyncRun        = 10
                                    NumberOfUsersEwsSyncWillProcessAtOnce         = 10
                                    NumberOfUsersPerEwsSyncBatch                  = 10
                                }
                            }
                            $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                return @{ FullName = $getTypeFullName }
                            } -PassThru -Force
                            return $spServiceApp
                        }
                        Mock -CommandName Set-SPWorkManagementServiceApplication { }
                    }

                    It "Should return values from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                    }

                    It "Should return false when the Test method is called" {
                        Test-TargetResource @testParams | Should -Be $false
                    }

                    It "Should call the update service app cmdlet from the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled Set-SPWorkManagementServiceApplication
                        Assert-MockCalled Get-SPServiceApplication
                    }
                }

                Context -Name "Running ReverseDsc Export" -Fixture {
                    BeforeAll {
                        Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                        Mock -CommandName Write-Host -MockWith { }

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Name                                          = "Work Management Service Application"
                                ProxyName                                     = "Work Management Service Application Proxy"
                                ApplicationPool                               = "SharePoint web services"
                                MinimumTimeBetweenEwsSyncSubscriptionSearches = 10
                                MinimumTimeBetweenProviderRefreshes           = 10
                                MinimumTimeBetweenSearchQueries               = 10
                                NumberOfSubscriptionSyncsPerEwsSyncRun        = 10
                                NumberOfUsersEwsSyncWillProcessAtOnce         = 10
                                NumberOfUsersPerEwsSyncBatch                  = 10
                                Ensure                                        = "Present"
                            }
                        }

                        Mock -CommandName Get-SPServiceApplication -MockWith {
                            $spServiceApp = [PSCustomObject]@{
                                DisplayName = "Work Management Service Application"
                                Name        = "Work Management Service Application"
                            }
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                -Name GetType `
                                -Value {
                                return @{
                                    Name = "WorkManagementServiceApplication"
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
        SPWorkManagementServiceApp WorkManagementServiceApplication
        {
            ApplicationPool                               = "SharePoint web services";
            Ensure                                        = "Present";
            MinimumTimeBetweenEwsSyncSubscriptionSearches = 10;
            MinimumTimeBetweenProviderRefreshes           = 10;
            MinimumTimeBetweenSearchQueries               = 10;
            Name                                          = "Work Management Service Application";
            NumberOfSubscriptionSyncsPerEwsSyncRun        = 10;
            NumberOfUsersEwsSyncWillProcessAtOnce         = 10;
            NumberOfUsersPerEwsSyncBatch                  = 10;
            ProxyName                                     = "Work Management Service Application Proxy";
            PsDscRunAsCredential                          = $Credsspfarm;
        }

'@
                    }

                    It "Should return valid DSC block from the Export method" {
                        Export-TargetResource | Should -Be $result
                    }
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
            {
                Context -Name "Trying to use SPWorkManagementServiceApp in SP2016/SP2019, not available" -Fixture {
                    BeforeAll {
                        # Initialize tests
                        $getTypeFullName = "Microsoft.Office.Server.WorkManagement.WorkManagementServiceApplication"

                        $testParams = @{
                            Name                                          = "Test Work Management App"
                            ApplicationPool                               = "Test App Pool"
                            MinimumTimeBetweenEwsSyncSubscriptionSearches = 20
                            MinimumTimeBetweenProviderRefreshes           = 20
                            MinimumTimeBetweenSearchQueries               = 20
                            NumberOfSubscriptionSyncsPerEwsSyncRun        = 20
                            NumberOfUsersEwsSyncWillProcessAtOnce         = 20
                            NumberOfUsersPerEwsSyncBatch                  = 20
                        }
                    }

                    It "Should throw an exception in the Get method" {
                        { Get-TargetResource @testParams } | Should -Throw "Work Management Service Application is no longer available in SharePoint 2016/2019"
                    }

                    It "Should throw an exception in the Test method" {
                        { Test-TargetResource @testParams } | Should -Throw "Work Management Service Application is no longer available in SharePoint 2016/2019"
                    }

                    It "Should throw an exception in the Set method" {
                        { Set-TargetResource @testParams } | Should -Throw "Work Management Service Application is no longer available in SharePoint 2016/2019"
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
