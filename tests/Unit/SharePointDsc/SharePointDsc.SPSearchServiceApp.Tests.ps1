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
$script:DSCResourceName = 'SPSearchServiceApp'
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
                Import-Module -Name (Join-Path -Path (Get-Module SharePointDsc -ListAvailable).ModuleBase `
                        -ChildPath "Modules\SharePointDsc.Search\SPSearchServiceApp.psm1" `
                        -Resolve)

                $getTypeFullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"

                Add-Type -TypeDefinition @"
                    namespace Microsoft.Office.Server.Search.Administration {
                        public static class SearchContext {
                            public static object GetContext(string serviceAppName) {
                                return null;
                            }
                        }
                    }
"@

                $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @("DOMAIN\username", $mockPassword)

                # Mocks for all contexts
                Mock -CommandName Start-SPEnterpriseSearchServiceInstance -MockWith { }
                Mock -CommandName Remove-SPServiceApplication -MockWith { }
                Mock -CommandName New-SPEnterpriseSearchServiceApplicationProxy -MockWith { }
                Mock -CommandName Set-SPEnterpriseSearchServiceApplication -MockWith { }
                Mock -CommandName New-SPBusinessDataCatalogServiceApplication -MockWith { }
                Mock -CommandName Set-SPEnterpriseSearchServiceApplication -MockWith { }
                Mock -CommandName Set-SPEnterpriseSearchService -MockWith { }

                Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith {
                    return @{ }
                }
                Mock -CommandName New-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{ }
                }
                Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                    return @{
                        Name = $testParams.ApplicationPool
                    }
                }
                Mock -CommandName New-Object -MockWith {
                    return @{
                        DefaultGatheringAccount = "Domain\username"
                    }
                } -ParameterFilter {
                    $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content"
                }
                Mock -CommandName Get-SPEnterpriseSearchService -MockWith {
                    return @{
                        ProcessIdentity = "DOMAIN\username"
                    }
                }

                Mock -CommandName Get-SPFarm -MockWith {
                    return @{
                        DefaultServiceAccount = @{
                            Name = 'contoso\sa_farm'
                        }
                    }
                }

                Mock -CommandName Get-SPEnterpriseSearchCrawlDatabase -MockWith {
                    return @(
                        @{
                            Database = @{
                                Name                 = 'SP_Search_CrawlStore'
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                    )
                }

                Mock -CommandName Get-SPEnterpriseSearchLinksDatabase -MockWith {
                    return @(
                        @{
                            Database = @{
                                Name                 = 'SP_Search_LinksStore'
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                    )
                }

                Mock -CommandName Confirm-UserIsDBOwner -MockWith {
                    return $true
                }

                Mock -CommandName Set-UserAsDBOwner -MockWith {}

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
            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        Ensure          = "Present"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return $null
                    }
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified service application pool"
                }
            }

            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = 'SP_Search'
                        AlertsEnabled   = $true
                        Ensure          = "Present"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    $global:SPDscCounter = 0
                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        if ($global:SPDscCounter -eq 0)
                        {
                            $global:SPDscCounter++
                            return $null
                        }
                        else
                        {
                            $spServiceApp = [PSCustomObject]@{
                                TypeName            = "Search Service Application"
                                DisplayName         = $testParams.Name
                                Name                = $testParams.Name
                                ApplicationPool     = @{ Name = $testParams.ApplicationPool }
                                AlertsEnabled       = $false
                                Database            = @{
                                    Name                 = $testParams.DatabaseName
                                    NormalizedDataSource = 'SQL01'
                                }
                                SearchAdminDatabase = @{
                                    Name                 = $testParams.DatabaseName
                                    NormalizedDataSource = 'SQL01'
                                }
                            }
                            $spServiceApp = $spServiceApp | Add-Member ScriptMethod Update {
                                $Global:SPDscAlertsEnabledUpdated = $true
                            } -PassThru
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                return @{ FullName = $getTypeFullName }
                            } -PassThru -Force
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                                return $true
                            } -PassThru -Force
                            return $spServiceApp
                        }
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    $global:SPDscCounter = 0

                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPEnterpriseSearchServiceApplication
                }
            }

            Context -Name "When service applications exist in the current farm but the specific search app does not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        Ensure          = "Present"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

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

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPEnterpriseSearchServiceApplication
                }
            }

            Context -Name "When a service application exists but the database permissions are not fixed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                      = "Search Service Application"
                        ApplicationPool           = "SharePoint Search Services"
                        DatabaseName              = "SP_Search"
                        FixFarmAccountPermissions = $true
                        Ensure                    = "Present"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName                    = "Search Service Application"
                            DisplayName                 = $testParams.Name
                            Name                        = $testParams.Name
                            ApplicationPool             = @{ Name = $testParams.ApplicationPool }
                            Database                    = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase         = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            AnalyticsReportingDatabases = @{
                                Name                 = $testParams.DatabaseName + '_AnalyticsReportingStore'
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        return $spServiceApp
                    }


                    Mock -CommandName Confirm-UserIsDBOwner -MockWith {
                        return $false
                    }
                }

                It "Should return FixFarmAccountPermissions=False from the get method" {
                    (Get-TargetResource @testParams).FixFarmAccountPermissions | Should -Be $true
                    Assert-MockCalled Confirm-UserIsDBOwner
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should correct database permissions in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-UserAsDBOwner -Times 4
                }
            }

            Context -Name "When a service application exists and is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = "SP_Search"
                        Ensure          = "Present"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{ Name = $testParams.ApplicationPool }
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
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
                    Assert-MockCalled Get-SPServiceApplication
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When a service application exists and the app pool is not configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = "SP_Search"
                        Ensure          = "Present"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{ Name = "Wrong App Pool Name" }
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
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

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @{
                            Name = "$($testParams.Name) Proxy"
                        }
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the update service app cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Get-SPServiceApplicationPool
                    Assert-MockCalled Set-SPEnterpriseSearchServiceApplication
                }
            }

            Context -Name "When a service application exists and the Proxy Name is not configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ProxyName       = "Search SA Proxy"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = "SP_Search"
                        Ensure          = "Present"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{ Name = $testParams.ApplicationPool }
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
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

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $returnval = @{
                            Name = "$($testParams.Name) Proxy"
                        }
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $global:SPDscProxyUpdateCalled = $true
                        } -PassThru -Force
                        return $returnval
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the service app proxy name in the set method" {
                    $global:SPDscProxyUpdateCalled = $false

                    Set-TargetResource @testParams
                    $global:SPDscProxyUpdateCalled | Should -Be $true
                }
            }

            Context -Name "When a service application exists, but the Proxy doesn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ProxyName       = "Search SA Proxy"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = "SP_Search"
                        Ensure          = "Present"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{ Name = $testParams.ApplicationPool }
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                            return $false
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return $null
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new proxy in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPEnterpriseSearchServiceApplicationProxy
                }
            }

            Context -Name "When the default content access account does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                        = "Search Service Application"
                        ApplicationPool             = "SharePoint Search Services"
                        DatabaseName                = "SP_Search"
                        Ensure                      = "Present"
                        DefaultContentAccessAccount = $mockCredential
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{ Name = $testParams.ApplicationPool }
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
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

                    Mock -CommandName New-Object -MockWith {
                        return @{
                            DefaultGatheringAccount = "WRONG\username"
                        }
                    } -ParameterFilter {
                        $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content"
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @{
                            Name = "$($testParams.Name) Proxy"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "changes the content access account" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Get-SPServiceApplicationPool
                    Assert-MockCalled Set-SPEnterpriseSearchServiceApplication
                }
            }

            Context -Name "When the default content access account does match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                        = "Search Service Application"
                        ApplicationPool             = "SharePoint Search Services"
                        DatabaseName                = "SP_Search"
                        Ensure                      = "Present"
                        DefaultContentAccessAccount = $mockCredential
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{
                                Name = $testParams.ApplicationPool
                            }
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName New-Object -MockWith {
                        return @{
                            DefaultGatheringAccount = "DOMAIN\username"
                        }
                    } -ParameterFilter {
                        $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content"
                    }
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When the search center URL does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = "SP_Search"
                        Ensure          = "Present"
                        SearchCenterUrl = "http://search.sp.contoso.com"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    $Global:SPDscSearchURLUpdated = $false

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{ Name = $testParams.ApplicationPool }
                            SearchCenterUrl     = "http://wrong.url.here"
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member ScriptMethod Update {
                            $Global:SPDscSearchURLUpdated = $true
                        } -PassThru
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                            return $true
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName New-Object -MockWith {
                        return @{
                            DefaultGatheringAccount = "Domain\username"
                        }
                    } -ParameterFilter {
                        $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content"
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @{
                            Name = "$($testParams.Name) Proxy"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the service app in the set method" {
                    Set-TargetResource @testParams
                    $Global:SPDscSearchURLUpdated | Should -Be $true
                }
            }

            Context -Name "When AlertsEnabled does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = "SP_Search"
                        Ensure          = "Present"
                        AlertsEnabled   = $true
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    $Global:SPDscAlertsEnabledUpdated = $false

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{ Name = $testParams.ApplicationPool }
                            AlertsEnabled       = $false
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member ScriptMethod Update {
                            $Global:SPDscAlertsEnabledUpdated = $true
                        } -PassThru
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                            return $true
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName New-Object -MockWith {
                        return @{
                            DefaultGatheringAccount = "Domain\username"
                        }
                    } -ParameterFilter {
                        $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content"
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @{
                            Name = "$($testParams.Name) Proxy"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the service app in the set method" {
                    Set-TargetResource @testParams
                    $Global:SPDscAlertsEnabledUpdated | Should -Be $true
                }
            }

            Context -Name "When the search center URL does match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = "SP_Search"
                        Ensure          = "Present"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{ Name = $testParams.ApplicationPool }
                            SearchCenterUrl     = "http://search.sp.contoso.com"
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName New-Object {
                        return @{
                            DefaultGatheringAccount = "Domain\username"
                        }
                    } -ParameterFilter {
                        $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content"
                    }
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When the service app exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = "SP_Search"
                        Ensure          = "Absent"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{
                                Name = $testParams.ApplicationPool
                            }
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
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
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        Ensure          = "Absent"
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

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

            Context -Name "When the service app exists and is cloud enabled" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        DatabaseName    = "SP_Search"
                        Ensure          = "Present"
                        CloudIndex      = $true
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName            = "Search Service Application"
                            DisplayName         = $testParams.Name
                            Name                = $testParams.Name
                            ApplicationPool     = @{ Name = $testParams.ApplicationPool }
                            CloudIndex          = $true
                            Database            = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                            SearchAdminDatabase = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = 'SQL01'
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{ FullName = $getTypeFullName }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPDscInstalledProductVersion -MockWith {
                        return @{
                            FileMajorPart = 15
                            FileBuildPart = 0
                        }
                    }
                }

                It "Should return false if the version is too low" {
                    (Get-TargetResource @testParams).CloudIndex | Should -Be $false
                }

                It "Should return that the web app is hybrid enabled from the get method" {
                    Mock -CommandName Get-SPDscInstalledProductVersion -MockWith {
                        return @{
                            FileMajorPart = 15
                            FileBuildPart = 5000
                        }
                    }

                    (Get-TargetResource @testParams).CloudIndex | Should -Be $true
                }
            }

            Context -Name "When the service doesn't exist and it should be cloud enabled" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Search Service Application"
                        ApplicationPool = "SharePoint Search Services"
                        Ensure          = "Present"
                        CloudIndex      = $true
                    }

                    Mock Import-Module -MockWith { } -ParameterFilter { $_.Name -eq $ModuleName }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-SPDscInstalledProductVersion -MockWith {
                        return @{
                            FileMajorPart = 15
                            FileBuildPart = 5000
                        }
                    }
                }

                It "Should create the service app in the set method" {
                    Set-TargetResource @testParams
                }

                It "Should throw an error in the set method if the version of SharePoint isn't high enough" {
                    Mock -CommandName Get-SPDscInstalledProductVersion -MockWith {
                        return @{
                            FileMajorPart = 15
                            FileBuildPart = 0
                        }
                    }

                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name                        = "Search Service Application"
                            ProxyName                   = "Search Service Application Proxy"
                            DatabaseName                = "SP_Search"
                            DatabaseServer              = "SQL01"
                            ApplicationPool             = "Service App Pool"
                            SearchCenterUrl             = "http://sharepoint.contoso.com/sites/search/Pages/search.aspx"
                            DefaultContentAccessAccount = $mockCredential
                            CloudIndex                  = $false
                            AlertsEnabled               = $true
                            Ensure                      = "Present"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName     = "Search Service Application"
                            Name            = "Search Service Application"
                            ApplicationPool = @{
                                Name = "Service App Pool"
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "SearchServiceApplication"
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Read-TargetResource -MockWith { }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPSearchServiceApp SearchServiceApplication
        {
            AlertsEnabled               = $True;
            ApplicationPool             = "Service App Pool";
            DatabaseName                = "SP_Search";
            DatabaseServer              = $ConfigurationData.NonNodeData.DatabaseServer;
            DefaultContentAccessAccount = $Credsusername;
            Ensure                      = "Present";
            Name                        = "Search Service Application";
            ProxyName                   = "Search Service Application Proxy";
            PsDscRunAsCredential        = $Credsspfarm;
            SearchCenterUrl             = "http://sharepoint.contoso.com/sites/search/Pages/search.aspx";
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
