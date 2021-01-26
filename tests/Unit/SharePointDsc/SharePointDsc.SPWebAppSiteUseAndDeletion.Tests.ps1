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
$script:DSCResourceName = 'SPWebAppSiteUseAndDeletion'
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
            Context -Name "The server is not part of SharePoint farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                                = "http://example.contoso.local"
                        SendUnusedSiteCollectionNotifications    = $true
                        UnusedSiteNotificationPeriod             = 90
                        AutomaticallyDeleteUnusedSiteCollections = $true
                        UnusedSiteNotificationsBeforeDeletion    = 30
                    }

                    Mock -CommandName Get-SPFarm -MockWith { throw "Unable to detect local farm" }
                }

                It "Should return SendUnusedSiteCollectionNotifications=null from the get method" {
                    (Get-TargetResource @testParams).SendUnusedSiteCollectionNotifications | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }
            }

            Context -Name "The Web Application isn't available" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                                = "http://example.contoso.local"
                        SendUnusedSiteCollectionNotifications    = $true
                        UnusedSiteNotificationPeriod             = 90
                        AutomaticallyDeleteUnusedSiteCollections = $true
                        UnusedSiteNotificationsBeforeDeletion    = 30
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return $null
                    }
                }

                It "Should return SendUnusedSiteCollectionNotifications=null from the get method" {
                    (Get-TargetResource @testParams).SendUnusedSiteCollectionNotifications | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Configured web application could not be found"
                }
            }

            Context -Name "UnusedSiteNotificationsBeforeDeletion is out of range" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                                = "http://example.contoso.local"
                        SendUnusedSiteCollectionNotifications    = $true
                        UnusedSiteNotificationPeriod             = 90
                        AutomaticallyDeleteUnusedSiteCollections = $true
                        UnusedSiteNotificationsBeforeDeletion    = 24
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $returnVal = @{
                            SendUnusedSiteCollectionNotifications    = $false
                            UnusedSiteNotificationPeriod             = @{ TotalDays = 45; }
                            AutomaticallyDeleteUnusedSiteCollections = $false
                            UnusedSiteNotificationsBeforeDeletion    = 28
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                        return $returnVal
                    }

                    Mock -CommandName Get-SPFarm -MockWith { return @{ } }
                }

                It "Should throw an exception - Daily schedule" {
                    Mock -CommandName Get-SPTimerJob -MockWith {
                        return @{
                            Schedule = @{
                                Description = "Daily"
                            }
                        }
                    }
                    $testParams.UnusedSiteNotificationsBeforeDeletion = 24

                    { Set-TargetResource @testParams } | Should -Throw "Value of UnusedSiteNotificationsBeforeDeletion has to be >28 and"
                }

                It "Should throw an exception - Weekly schedule" {
                    Mock -CommandName Get-SPTimerJob -MockWith {
                        return @{
                            Schedule = @{
                                Description = "Weekly"
                            }
                        }
                    }
                    $testParams.UnusedSiteNotificationsBeforeDeletion = 28

                    { Set-TargetResource @testParams } | Should -Throw "Value of UnusedSiteNotificationsBeforeDeletion has to be >4 and"
                }

                It "Should throw an exception - Weekly schedule" {
                    Mock -CommandName Get-SPTimerJob -MockWith {
                        return @{
                            Schedule = @{
                                Description = "Monthly"
                            }
                        }
                    }
                    $testParams.UnusedSiteNotificationsBeforeDeletion = 12

                    { Set-TargetResource @testParams } | Should -Throw "Value of UnusedSiteNotificationsBeforeDeletion has to be >2 and"
                }
            }

            Context -Name "The Dead Site Delete timer job does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                                = "http://example.contoso.local"
                        SendUnusedSiteCollectionNotifications    = $true
                        UnusedSiteNotificationPeriod             = 90
                        AutomaticallyDeleteUnusedSiteCollections = $true
                        UnusedSiteNotificationsBeforeDeletion    = 30
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $returnVal = @{
                            SendUnusedSiteCollectionNotifications    = $false
                            UnusedSiteNotificationPeriod             = @{ TotalDays = 45; }
                            AutomaticallyDeleteUnusedSiteCollections = $false
                            UnusedSiteNotificationsBeforeDeletion    = 28
                        }
                        return $returnVal
                    }

                    Mock -CommandName Get-SPFarm -MockWith { return @{ } }
                    Mock -CommandName Get-SPTimerJob -MockWith { return $null }
                }

                It "Should update the Site Use and Deletion settings" {
                    { Set-TargetResource @testParams } | Should -Throw "Dead Site Delete timer job for web application"
                }
            }

            Context -Name "The server is in a farm and the incorrect settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                                = "http://example.contoso.local"
                        SendUnusedSiteCollectionNotifications    = $true
                        UnusedSiteNotificationPeriod             = 90
                        AutomaticallyDeleteUnusedSiteCollections = $true
                        UnusedSiteNotificationsBeforeDeletion    = 30
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $returnVal = @{
                            SendUnusedSiteCollectionNotifications    = $false
                            UnusedSiteNotificationPeriod             = @{ TotalDays = 45; }
                            AutomaticallyDeleteUnusedSiteCollections = $false
                            UnusedSiteNotificationsBeforeDeletion    = 28
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                        return $returnVal
                    }

                    Mock -CommandName Get-SPFarm -MockWith { return @{ } }
                    Mock -CommandName Get-SPTimerJob -MockWith {
                        return @{
                            Schedule = @{
                                Description = "Daily"
                            }
                        }
                    }
                }

                It "Should return SendUnusedSiteCollectionNotifications=False from the get method" {
                    (Get-TargetResource @testParams).SendUnusedSiteCollectionNotifications | Should -Be $false
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the Site Use and Deletion settings" {
                    $Global:SPDscSiteUseUpdated = $false
                    Set-TargetResource @testParams
                    $Global:SPDscSiteUseUpdated | Should -Be $true
                }
            }

            Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                                = "http://example.contoso.local"
                        SendUnusedSiteCollectionNotifications    = $true
                        UnusedSiteNotificationPeriod             = 90
                        AutomaticallyDeleteUnusedSiteCollections = $true
                        UnusedSiteNotificationsBeforeDeletion    = 30
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $returnVal = @{
                            SendUnusedSiteCollectionNotifications    = $true
                            UnusedSiteNotificationPeriod             = @{ TotalDays = 90; }
                            AutomaticallyDeleteUnusedSiteCollections = $true
                            UnusedSiteNotificationsBeforeDeletion    = 30
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                        return $returnVal
                    }
                    Mock -CommandName Get-SPFarm -MockWith { return @{ } }
                }

                It "Should return SendUnusedSiteCollectionNotifications=True from the get method" {
                    (Get-TargetResource @testParams).SendUnusedSiteCollectionNotifications | Should -Be $true
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            WebAppUrl                                = "http://example.contoso.local"
                            SendUnusedSiteCollectionNotifications    = $true
                            UnusedSiteNotificationPeriod             = 90
                            AutomaticallyDeleteUnusedSiteCollections = $true
                            UnusedSiteNotificationsBeforeDeletion    = 24
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $spWebApp = [PSCustomObject]@{
                            Name = "SharePoint Sites"
                            Url  = "https://intranet.sharepoint.contoso.com"
                        }
                        return $spWebApp
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPWebAppSiteUseAndDeletion [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            AutomaticallyDeleteUnusedSiteCollections = \$True;
            PsDscRunAsCredential                     = \$Credsspfarm;
            SendUnusedSiteCollectionNotifications    = \$True;
            UnusedSiteNotificationPeriod             = 90;
            UnusedSiteNotificationsBeforeDeletion    = 24;
            WebAppUrl                                = "http://example.contoso.local";
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
