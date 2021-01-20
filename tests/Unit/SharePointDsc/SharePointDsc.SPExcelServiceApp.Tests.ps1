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
$script:DSCResourceName = 'SPExcelServiceApp'
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
                    $getTypeFullName = "Microsoft.Office.Excel.Server.MossHost.ExcelServerWebServiceApplication"

                    # Mocks for all contexts
                    Mock -CommandName Remove-SPServiceApplication -MockWith { }
                    Mock -CommandName New-SPExcelServiceApplication -MockWith { }
                    Mock -CommandName Get-SPExcelFileLocation -MockWith { }
                    Mock -CommandName Set-SPExcelServiceApplication -MockWith { }
                    Mock -CommandName New-SPExcelFileLocation -MockWith { }
                    Mock -CommandName Set-SPExcelFileLocation -MockWith { }
                    Mock -CommandName Remove-SPExcelFileLocation -MockWith { }
                }

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
            switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15
                {
                    Context -Name "When no service applications exist in the current farm" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name            = "Test Excel Services App"
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
                            Assert-MockCalled New-SPExcelServiceApplication
                        }
                    }

                    Context -Name "When service applications exist in the current farm but the specific Excel Services app does not" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name            = "Test Excel Services App"
                                ApplicationPool = "Test App Pool"
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

                            Mock -CommandName Get-SPServiceApplication -MockWith { return @(@{
                                        TypeName = "Some other service app type"
                                    }) }
                        }

                        It "Should return absent from the Get method" {
                            (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                        }

                    }

                    Context -Name "When a service application exists and is configured correctly" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name            = "Test Excel Services App"
                                ApplicationPool = "Test App Pool"
                            }

                            Mock -CommandName Get-SPServiceApplication -MockWith {
                                $spServiceApp = [PSCustomObject]@{
                                    TypeName        = "Excel Services Application Web Service Application"
                                    DisplayName     = $testParams.Name
                                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                                }
                                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
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

                    Context -Name "When the service application exists but it shouldn't" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name            = "Test App"
                                ApplicationPool = "-"
                                Ensure          = "Absent"
                            }

                            Mock -CommandName Get-SPServiceApplication -MockWith {
                                $spServiceApp = [PSCustomObject]@{
                                    TypeName        = "Excel Services Application Web Service Application"
                                    DisplayName     = $testParams.Name
                                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
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

                    Context -Name "When the service application doesn't exist and it shouldn't" -Fixture {
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

                    Context -Name "When the service app should have trusted locations, but doesn't" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name                 = "Test Excel Services App"
                                ApplicationPool      = "Test App Pool"
                                TrustedFileLocations = @(
                                    (New-CimInstance -ClassName MSFT_SPExcelFileLocation -ClientOnly -Property @{
                                            Address         = "http://"
                                            LocationType    = "SharePoint"
                                            WorkbookSizeMax = 10
                                        })
                                )
                            }

                            Mock -CommandName Get-SPServiceApplication -MockWith {
                                $spServiceApp = [PSCustomObject]@{
                                    TypeName        = "Excel Services Application Web Service Application"
                                    DisplayName     = $testParams.Name
                                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                                }
                                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                    return @{ FullName = $getTypeFullName }
                                } -PassThru -Force
                                return $spServiceApp
                            }

                            Mock -CommandName Get-SPExcelFileLocation -MockWith {
                                return @()
                            }
                        }

                        It "Should return no trusted location results from the get method" {
                            (Get-TargetResource @testParams).TrustedFileLocations | Should -BeNullOrEmpty
                        }

                        It "Should return false from the test method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "Should create the trusted location in the set method" {
                            Set-TargetResource @testParams
                            Assert-MockCalled -CommandName New-SPExcelFileLocation
                        }
                    }

                    Context -Name "When the service app should have trusted locations, but the settings don't match" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name                 = "Test Excel Services App"
                                ApplicationPool      = "Test App Pool"
                                TrustedFileLocations = @(
                                    (New-CimInstance -ClassName MSFT_SPExcelFileLocation -ClientOnly -Property @{
                                            Address         = "http://"
                                            LocationType    = "SharePoint"
                                            WorkbookSizeMax = 10
                                        })
                                )
                            }

                            Mock -CommandName Get-SPServiceApplication -MockWith {
                                $spServiceApp = [PSCustomObject]@{
                                    TypeName        = "Excel Services Application Web Service Application"
                                    DisplayName     = $testParams.Name
                                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                                }
                                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                    return @{ FullName = $getTypeFullName }
                                } -PassThru -Force
                                return $spServiceApp
                            }

                            Mock -CommandName Get-SPExcelFileLocation -MockWith {
                                return @(@{
                                        Address         = "http://"
                                        LocationType    = "SharePoint"
                                        WorkbookSizeMax = 2
                                    })
                            }
                        }

                        It "Should return trusted location results from the get method" {
                            (Get-TargetResource @testParams).TrustedFileLocations | Should -Not -BeNullOrEmpty
                        }

                        It "Should return false from the test method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "Should update the trusted location in the set method" {
                            Set-TargetResource @testParams
                            Assert-MockCalled -CommandName Set-SPExcelFileLocation
                        }
                    }

                    Context -Name "When the service app should have trusted locations, and does" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name                 = "Test Excel Services App"
                                ApplicationPool      = "Test App Pool"
                                TrustedFileLocations = @(
                                    (New-CimInstance -ClassName MSFT_SPExcelFileLocation -ClientOnly -Property @{
                                            Address         = "http://"
                                            LocationType    = "SharePoint"
                                            WorkbookSizeMax = 10
                                        })
                                )
                            }

                            Mock -CommandName Get-SPServiceApplication -MockWith {
                                $spServiceApp = [PSCustomObject]@{
                                    TypeName        = "Excel Services Application Web Service Application"
                                    DisplayName     = $testParams.Name
                                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                                }
                                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                    return @{ FullName = $getTypeFullName }
                                } -PassThru -Force
                                return $spServiceApp
                            }

                            Mock -CommandName Get-SPExcelFileLocation -MockWith {
                                return @(@{
                                        Address         = "http://"
                                        LocationType    = "SharePoint"
                                        WorkbookSizeMax = 10
                                    })
                            }
                        }

                        It "Should return trusted location results from the get method" {
                            (Get-TargetResource @testParams).TrustedFileLocations | Should -Not -BeNullOrEmpty
                        }

                        It "Should return true from the test method" {
                            Test-TargetResource @testParams | Should -Be $true
                        }
                    }

                    Context -Name "When the service app should have trusted locations, and does but also has an extra one that should be removed" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name                 = "Test Excel Services App"
                                ApplicationPool      = "Test App Pool"
                                TrustedFileLocations = @(
                                    (New-CimInstance -ClassName MSFT_SPExcelFileLocation -ClientOnly -Property @{
                                            Address         = "http://"
                                            LocationType    = "SharePoint"
                                            WorkbookSizeMax = 10
                                        })
                                )
                            }

                            Mock -CommandName Get-SPServiceApplication -MockWith {
                                $spServiceApp = [PSCustomObject]@{
                                    TypeName        = "Excel Services Application Web Service Application"
                                    DisplayName     = $testParams.Name
                                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                                }
                                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                    return @{ FullName = $getTypeFullName }
                                } -PassThru -Force
                                return $spServiceApp
                            }

                            Mock -CommandName Get-SPExcelFileLocation -MockWith {
                                return @(@{
                                        Address         = "http://"
                                        LocationType    = "SharePoint"
                                        WorkbookSizeMax = 10
                                    },
                                    @{
                                        Address         = "https://"
                                        LocationType    = "SharePoint"
                                        WorkbookSizeMax = 10
                                    })
                            }
                        }

                        It "Should return trusted location results from the get method" {
                            (Get-TargetResource @testParams).TrustedFileLocations | Should -Not -BeNullOrEmpty
                        }

                        It "Should return false from the test method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "Should remove the trusted location in the set method" {
                            Set-TargetResource @testParams
                            Assert-MockCalled -CommandName Remove-SPExcelFileLocation
                        }
                    }
                }
                16
                {
                    Context -Name "All methods throw exceptions as Excel Services doesn't exist in 2016/2019" -Fixture {
                        It "Should throw on the get method" {
                            { Get-TargetResource @testParams } | Should -Throw
                        }

                        It "Should throw on the test method" {
                            { Test-TargetResource @testParams } | Should -Throw
                        }

                        It "Should throw on the set method" {
                            { Set-TargetResource @testParams } | Should -Throw
                        }
                    }
                }
                Default
                {
                    throw [Exception] "A supported version of SharePoint was not used in testing"
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name                                      = "Excel Service Application"
                            ApplicationPool                           = "Service App Pool"
                            Ensure                                    = "Present"
                            TrustedFileLocations                      = @("http://sharepoint.contoso.com/lib")
                            CachingOfUnusedFilesEnable                = $true
                            CrossDomainAccessAllowed                  = $false
                            EncryptedUserConnectionRequired           = 'Connection'
                            ExternalDataConnectionLifetime            = 5
                            FileAccessMethod                          = 'UseFileAccessAccount'
                            LoadBalancingScheme                       = 'RoundRobin'
                            MemoryCacheThreshold                      = 4096
                            PrivateBytesMax                           = 4096
                            SessionsPerUserMax                        = 5
                            SiteCollectionAnonymousSessionsMax        = 5
                            TerminateProcessOnAccessViolation         = $true
                            ThrottleAccessViolationsPerSiteCollection = 5
                            UnattendedAccountApplicationId            = "domain\account"
                            UnusedObjectAgeMax                        = 5
                            WorkbookCache                             = "test"
                            WorkbookCacheSizeMax                      = 5
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName    = "Excel Services Application Web Service Application"
                            DisplayName = "Excel Services Application Web Service Application"
                            Name        = "Excel Services Application Web Service Application"
                        }
                        return $spServiceApp
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPExcelServiceApp [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            ApplicationPool                           = "Service App Pool";
            CachingOfUnusedFilesEnable                = \$True;
            CrossDomainAccessAllowed                  = \$False;
            EncryptedUserConnectionRequired           = "Connection";
            Ensure                                    = "Present";
            ExternalDataConnectionLifetime            = 5;
            FileAccessMethod                          = "UseFileAccessAccount";
            LoadBalancingScheme                       = "RoundRobin";
            MemoryCacheThreshold                      = 4096;
            Name                                      = "Excel Service Application";
            PrivateBytesMax                           = 4096;
            PsDscRunAsCredential                      = \$Credsspfarm;
            SessionsPerUserMax                        = 5;
            SiteCollectionAnonymousSessionsMax        = 5;
            TerminateProcessOnAccessViolation         = \$True;
            ThrottleAccessViolationsPerSiteCollection = 5;
            UnattendedAccountApplicationId            = "domain\\account";
            UnusedObjectAgeMax                        = 5;
            WorkbookCache                             = "test";
            WorkbookCacheSizeMax                      = 5;
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
