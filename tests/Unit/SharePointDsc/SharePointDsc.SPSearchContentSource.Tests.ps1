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
$script:DSCResourceName = 'SPSearchContentSource'
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
                Add-Type -TypeDefinition @"
        namespace Microsoft.Office.Server.Search.Administration {
            [System.Flags]
            public enum DaysOfWeek {
                Monday = 1,
                Tuesday = 2,
                Wednesday = 4,
                Thursday = 8,
                Friday = 16,
                Saturday = 32,
                Sunday = 64,
                Weekdays = 128,
                Weekends = 256,
                AllDays = 512
            }

            public class DailySchedule {
                public int RepeatDuration {get; set;}
                public int RepeatInterval {get; set;}
                public int StartHour {get; set;}
                public int StartMinute {get; set;}
                public int DaysInterval {get; set;}
            }

            public class WeeklySchedule {
                public int RepeatDuration {get; set;}
                public int RepeatInterval {get; set;}
                public int StartHour {get; set;}
                public int StartMinute {get; set;}
                public int WeeksInterval {get; set;}
                public Microsoft.Office.Server.Search.Administration.DaysOfWeek DaysOfWeek {get; set;}
            }
        }
"@

                # Mocks for all contexts
                Mock -CommandName Start-Sleep -MockWith { }
                Mock -CommandName Set-SPEnterpriseSearchCrawlContentSource -MockWith { }
                Mock -CommandName Remove-SPEnterpriseSearchCrawlContentSource -MockWith { }

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
            Context -Name "LimitPageDepth should not be used with Content Source Type SharePoint" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        LimitPageDepth    = 2
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlVirtualServers"
                        Ensure            = "Present"
                    }
                }

                It "Should create the content source in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for SharePoint content sources"
                }

                It "Should create the content source in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for SharePoint content sources"
                }
            }

            Context -Name "LimitServerHops should not be used with Content Source Type SharePoint" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        LimitServerHops   = 2
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlVirtualServers"
                        Ensure            = "Present"
                    }
                }

                It "Should create the content source in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for SharePoint content sources"
                }

                It "Should create the content source in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for SharePoint content sources"
                }
            }

            Context -Name "CrawlSetting=Custom should not be used with Content Source Type SharePoint" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "Custom"
                        Ensure            = "Present"
                    }
                }

                It "Should create the content source in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Parameter CrawlSetting can only be set to CrawlVirtualServers or CrawlSites for SharePoint content sources"
                }

                It "Should create the content source in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter CrawlSetting can only be set to CrawlVirtualServers or CrawlSites for SharePoint content sources"
                }
            }

            Context -Name "LimitServerHops should not be used with Content Source Type Website" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Website"
                        LimitServerHops   = 2
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }
                }

                It "Should create the content source in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for Website content sources"
                }

                It "Should create the content source in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for Website content sources"
                }
            }

            Context -Name "ContinuousCrawl should not be used with Content Source Type SharePoint" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Website"
                        ContinuousCrawl   = $true
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }
                }

                It "Should create the content source in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Parameter ContinuousCrawl is not valid for Website content sources"
                }

                It "Should create the content source in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter ContinuousCrawl is not valid for Website content sources"
                }
            }

            Context -Name "LimitPageDepth should not be used with Content Source Type FileShare" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "FileShare"
                        LimitPageDepth    = 2
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }
                }

                It "Should create the content source in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for FileShare content sources"
                }

                It "Should create the content source in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for FileShare content sources"
                }
            }

            Context -Name "LimitServerHops should not be used with Content Source Type FileShare" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "FileShare"
                        LimitServerHops   = 2
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }
                }

                It "Should create the content source in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for FileShare content sources"
                }

                It "Should create the content source in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for FileShare content sources"
                }
            }

            Context -Name "CrawlSetting=Custom should not be used with Content Source Type FileShare" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "FileShare"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "Custom"
                        Ensure            = "Present"
                    }
                }

                It "Should create the content source in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Parameter CrawlSetting can only be set to custom for website content sources"
                }

                It "Should create the content source in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter CrawlSetting can only be set to custom for website content sources"
                }
            }

            Context -Name "A SharePoint content source doesn't exist but should" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlVirtualServers"
                        Ensure            = "Present"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }

                    Mock -CommandName New-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Type                     = "SharePoint"
                            SharePointCrawlBehavior  = "CrawlVirtualServers"
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            EnableContinuousCrawls   = $false
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the content source in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName New-SPEnterpriseSearchCrawlContentSource
                    Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A SharePoint content source does exist and should" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlSites"
                        Ensure            = "Present"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "SharePoint"
                            SharePointCrawlBehavior  = "CrawlSites"
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            EnableContinuousCrawls   = $false
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A SharePoint content source does exist and shouldn't" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlVirtualServers"
                        Ensure            = "Absent"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "SharePoint"
                            SharePointCrawlBehavior  = "CrawlVirtualServers"
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            EnableContinuousCrawls   = $false
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the content source in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A SharePoint content source doesn't exist and shouldn't" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlVirtualServers"
                        Ensure            = "Absent"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A SharePoint source that uses continuous crawl has incorrect settings applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlVirtualServers"
                        ContinuousCrawl   = $true
                        Ensure            = "Present"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "SharePoint"
                            SharePointCrawlBehavior  = "CrawlVirtualServers"
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://wrong.site"
                                }
                            )
                            EnableContinuousCrawls   = $true
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should disable continuous crawl and then re-enable it when updating the content source" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource -ParameterFilter {
                        $EnableContinuousCrawls -eq $false
                    }
                    Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource -ParameterFilter {
                        $EnableContinuousCrawls -eq $true
                    }
                }
            }

            Context -Name "A website content source doesn't exist but should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Website"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                    Mock -CommandName New-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Type                     = "Web"
                            MaxPageEnumerationDepth  = [System.Int32]::MaxValue
                            MaxSiteEnumerationDepth  = 0
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the content source in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName New-SPEnterpriseSearchCrawlContentSource
                    Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A website content source does exist and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Website"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "Web"
                            MaxPageEnumerationDepth  = [System.Int32]::MaxValue
                            MaxSiteEnumerationDepth  = 0
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A website content source does exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Website"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Absent"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "Web"
                            MaxPageEnumerationDepth  = [System.Int32]::MaxValue
                            MaxSiteEnumerationDepth  = 0
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the content source in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A website content source doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Website"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Absent"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A website content source has incorrect crawl depth settings applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Website"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "Web"
                            MaxPageEnumerationDepth  = 0
                            MaxSiteEnumerationDepth  = 0
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the settings in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A file share content source doesn't exist but should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Fileshare"
                        Addresses         = @("\\server\share")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                    Mock -CommandName New-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Type                     = "File"
                            FollowDirectories        = $true
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "file:///server/share"
                                }
                            )
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the content source in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName New-SPEnterpriseSearchCrawlContentSource
                    Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A file share content source does exist and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Fileshare"
                        Addresses         = @("\\server\share")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "File"
                            FollowDirectories        = $true
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "file:///server/share"
                                }
                            )
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A file share content source does exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Fileshare"
                        Addresses         = @("\\server\share")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Absent"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "File"
                            FollowDirectories        = $true
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "file:///server/share"
                                }
                            )
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the content source in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A file share content source doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Fileshare"
                        Addresses         = @("\\server\share")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Absent"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A file share content source has incorrect crawl depth settings applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Fileshare"
                        Addresses         = @("\\server\share")
                        CrawlSetting      = "CrawlEverything"
                        Ensure            = "Present"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "File"
                            FollowDirectories        = $false
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "file:///server/share"
                                }
                            )
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the settings in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A content source has a full schedule that does not match the desired schedule" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlVirtualServers"
                        Ensure            = "Present"
                        FullSchedule      = (New-CimInstance -ClassName MSFT_SPSearchCrawlSchedule -Property @{
                                ScheduleType                = "Daily"
                                StartHour                   = "0"
                                StartMinute                 = "0"
                                CrawlScheduleRepeatDuration = "1440"
                                CrawlScheduleRepeatInterval = "5"
                            } -ClientOnly)
                    }

                    $Global:SPDscContentSourceLoopCount = 0

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        $schedule = New-Object -TypeName Microsoft.Office.Server.Search.Administration.DailySchedule
                        $schedule.RepeatDuration = 1439
                        $schedule.RepeatInterval = 5
                        $schedule.StartHour = 0
                        $schedule.StartMinute = 0
                        $schedule.DaysInterval = 1

                        if ($Global:SPDscContentSourceLoopCount -le 8)
                        {
                            $crawlStatus = "Running"
                        }
                        else
                        {
                            $crawlStatus = "Idle"
                        }
                        $returnval = @{
                            Name                     = "Example content source"
                            Type                     = "SharePoint"
                            SharePointCrawlBehavior  = "CrawlVirtualServers"
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            EnableContinuousCrawls   = $false
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $schedule
                            CrawlPriority            = "Normal"
                            CrawlStatus              = $crawlStatus
                        }
                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name StopCrawl `
                            -Value {
                        } -PassThru -Force

                        $Global:SPDscContentSourceLoopCount++
                        return $returnval
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscContentSourceLoopCount = 0
                It "Should update the schedule in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource -ParameterFilter { $ScheduleType -eq "Full" }
                }
            }

            Context -Name "A content source has a full schedule that does match the desired schedule" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        Addresses         = @("http://site.contoso.com")
                        CrawlSetting      = "CrawlVirtualServers"
                        Ensure            = "Present"
                        FullSchedule      = (New-CimInstance -ClassName MSFT_SPSearchCrawlSchedule -Property @{
                                ScheduleType                = "Daily"
                                StartHour                   = "0"
                                StartMinute                 = "0"
                                CrawlScheduleRepeatDuration = "1440"
                                CrawlScheduleRepeatInterval = "5"
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        $schedule = New-Object -TypeName Microsoft.Office.Server.Search.Administration.DailySchedule
                        $schedule.RepeatDuration = 1440
                        $schedule.RepeatInterval = 5
                        $schedule.StartHour = 0
                        $schedule.StartMinute = 0
                        $schedule.DaysInterval = 1
                        return @{
                            Name                     = "Example content source"
                            Type                     = "SharePoint"
                            SharePointCrawlBehavior  = "CrawlVirtualServers"
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            EnableContinuousCrawls   = $false
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $schedule
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A content source has a incremental schedule that does not match the desired schedule" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "Example content source"
                        ServiceAppName      = "Search Service Application"
                        ContentSourceType   = "SharePoint"
                        Addresses           = @("http://site.contoso.com")
                        CrawlSetting        = "CrawlVirtualServers"
                        Ensure              = "Present"
                        IncrementalSchedule = (New-CimInstance -ClassName MSFT_SPSearchCrawlSchedule -Property @{
                                ScheduleType            = "Weekly"
                                StartHour               = "0"
                                StartMinute             = "0"
                                CrawlScheduleDaysOfWeek = @("Monday", "Wednesday")
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        $schedule = New-Object -TypeName Microsoft.Office.Server.Search.Administration.WeeklySchedule
                        $schedule.StartHour = 0
                        $schedule.StartMinute = 0
                        $schedule.DaysOfWeek = [enum]::Parse([Microsoft.Office.Server.Search.Administration.DaysOfWeek], "Monday, Wednesday, Friday")
                        return @{
                            Name                     = "Example content source"
                            Type                     = "SharePoint"
                            SharePointCrawlBehavior  = "CrawlVirtualServers"
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            EnableContinuousCrawls   = $false
                            IncrementalCrawlSchedule = $schedule
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the schedule in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource -ParameterFilter { $ScheduleType -eq "Incremental" }
                }
            }

            Context -Name "A content source has a incremental schedule that does match the desired schedule" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "Example content source"
                        ServiceAppName      = "Search Service Application"
                        ContentSourceType   = "SharePoint"
                        Addresses           = @("http://site.contoso.com")
                        CrawlSetting        = "CrawlVirtualServers"
                        Ensure              = "Present"
                        IncrementalSchedule = (New-CimInstance -ClassName MSFT_SPSearchCrawlSchedule -Property @{
                                ScheduleType            = "Weekly"
                                StartHour               = "0"
                                StartMinute             = "0"
                                CrawlScheduleDaysOfWeek = @("Monday", "Wednesday", "Friday")
                            } -ClientOnly)
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        $schedule = New-Object -TypeName Microsoft.Office.Server.Search.Administration.WeeklySchedule
                        $schedule.StartHour = 0
                        $schedule.StartMinute = 0
                        $schedule.DaysOfWeek = [enum]::Parse([Microsoft.Office.Server.Search.Administration.DaysOfWeek], "Monday, Wednesday, Friday")
                        return @{
                            Name                     = "Example content source"
                            Type                     = "SharePoint"
                            SharePointCrawlBehavior  = "CrawlVirtualServers"
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "http://site.contoso.com"
                                }
                            )
                            EnableContinuousCrawls   = $false
                            IncrementalCrawlSchedule = $schedule
                            FullCrawlSchedule        = $null
                            CrawlPriority            = "Normal"
                            CrawlStatus              = "Idle"
                        }
                    }
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A business content source does exist and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Business"
                        LOBSystemSet      = @("MyDataSource", "MyDataSourceInstance")
                        Ensure            = "Present"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "Business"
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "bdc3://segment1/segment2/segment3/MyDataSource/MyDataSourceInstance&fakevalue=1"
                                    Segments    = @("bdc3", "segment1", "segment2", "segment3", "MyDataSource", "MyDataSourceInstance&fakevalue=1")
                                }
                            )
                        }
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return the correct LOBSystemSet from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.LOBSystemSet | Should -Be $testParams.LOBSystemSet
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A business content source does not exist and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Business"
                        LOBSystemSet      = @("MyDataSource", "MyDataSourceInstance")
                        Ensure            = "Present"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }

                    Mock -CommandName New-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Type                     = "Business"
                            SearchApplication        = $testParams.ServiceAppName
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            LOBSystemSet             = $testParams.LOBSystemSet
                            CrawlStatus              = "Idle"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @{
                            Name = "Default Proxy Group"
                        }
                    }
                }

                It "Should return absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the new content source in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName New-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A business content source does exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Business"
                        LOBSystemSet      = @("MyDataSource", "MyDataSourceInstance")
                        Ensure            = "Absent"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name                     = "Example content source"
                            Type                     = "Business"
                            IncrementalCrawlSchedule = $null
                            FullCrawlSchedule        = $null
                            StartAddresses           = @(
                                @{
                                    AbsoluteUri = "bdc3://segment1/segment2/segment3/MyDataSource/MyDataSourceInstance&fakevalue=1"
                                    Segments    = @("bdc3", "segment1", "segment2", "segment3", "MyDataSource", "MyDataSourceInstance&fakevalue=1")
                                }
                            )
                        }
                    }
                }

                It "Should return present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the content source in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "A business content source doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Business"
                        LOBSystemSet      = @("MyDataSource", "MyDataSourceInstance")
                        Ensure            = "Absent"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Invalid Content Source Type" {
                BeforeAll {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Business"
                        Ensure            = "Present"
                    }
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @{
                            Name = "Example content source"
                            Type = "FakeType"
                        }
                    }
                }

                It "Should throw unsupported type error" {
                    { Get-TargetResource @testParams } | Should -Throw "SharePointDsc does not currently support 'FakeType' content sources. Please use only 'SharePoint', 'FileShare', 'Website' or 'Business'."
                }
            }

            Context -Name "SharePoint Content Source with Invalid Parameters" {
                BeforeAll {
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        LimitPageDepth    = 1
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for SharePoint content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for SharePoint content sources"
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        LimitServerHops   = 1
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for SharePoint content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for SharePoint content sources"
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "SharePoint"
                        CrawlSetting      = "Custom"
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter CrawlSetting can only be set to CrawlVirtualServers or CrawlSites for SharePoint content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter CrawlSetting can only be set to CrawlVirtualServers or CrawlSites for SharePoint content sources"
                }
            }

            Context -Name "Website Content Source with Invalid Parameters" {
                BeforeAll {
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Website"
                        ContinuousCrawl   = $true
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter ContinuousCrawl is not valid for Website content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter ContinuousCrawl is not valid for Website content sources"
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Website"
                        LimitServerHops   = 1
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for Website content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for Website content sources"
                }
            }

            Context -Name "FileShare Content Source with Invalid Parameters" {
                BeforeAll {
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "FileShare"
                        LimitPageDepth    = 1
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for FileShare content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for FileShare content sources"
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "FileShare"
                        LimitServerHops   = 1
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for FileShare content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for FileShare content sources"
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "FileShare"
                        CrawlSetting      = "Custom"
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter CrawlSetting can only be set to custom for website content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter CrawlSetting can only be set to custom for website content sources"
                }
            }

            Context -Name "Business Content Source with Invalid Parameters" {
                BeforeAll {
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return $null
                    }
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Business"
                        LimitPageDepth    = 1
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for Business content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitPageDepth is not valid for Business content sources"
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Business"
                        LimitServerHops   = 1
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for Business content sources"
                    { Test-TargetResource @testParams } | Should -Throw "Parameter LimitServerHops is not valid for Business content sources"
                }

                It "Should throw Invalid parameter error" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "Business"
                        ContinuousCrawl   = $true
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "Parameter ContinuousCrawl is not valid for Business content sources"
                }
            }

            Context -Name "Trying to change Content Source Type" {
                BeforeAll {
                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        $returnval = @{
                            Name = "Example content source"
                        }
                        $returnval = $returnval | Add-Member -MemberType NoteProperty `
                            -Name Type `
                            -Value "Business" `
                            -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name StopCrawl `
                                -Value {
                                $null
                            }  -PassThru -Force
                        return $returnval
                    }
                }

                It "Should throw error complaining cannot change type without the force parameter" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "FileShare"
                        Ensure            = "Present"
                    }

                    { Set-TargetResource @testParams } | Should -Throw "The type of the a search content source can not be changed from 'Business' to 'FileShare' without deleting and adding it again. Specify 'Force = `$true' in order to allow DSC to do this, or manually remove the existing content source and re-run the configuration."
                }

                It "Should change the Content Source Type" {
                    $testParams = @{
                        Name              = "Example content source"
                        ServiceAppName    = "Search Service Application"
                        ContentSourceType = "FileShare"
                        Force             = $true
                        Ensure            = "Present"
                    }

                    Set-TargetResource @testParams

                    Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name              = "Local SharePoint Sites"
                            ServiceAppName    = "Search Service Application"
                            ContentSourceType = "SharePoint"
                            Addresses         = @("http://sharepointsite1.contoso.com", "http://sharepointsite2.contoso.com")
                            CrawlSetting      = "CrawlSites"
                            ContinuousCrawl   = $true
                            Priority          = "Normal"
                            Ensure            = "Present"
                        }
                    }

                    Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                        return @(
                            @{
                                Name = "Local SharePoint Sites"
                                Type = "SharePoint"
                            }
                        )
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPSearchContentSource LocalSharePointSites[0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Addresses            = \@\("http://sharepointsite1.contoso.com","http://sharepointsite2.contoso.com"\);
            ContentSourceType    = "SharePoint";
            ContinuousCrawl      = \$True;
            CrawlSetting         = "CrawlSites";
            Ensure               = "Present";
            Name                 = "Local SharePoint Sites";
            Priority             = "Normal";
            PsDscRunAsCredential = \$Credsspfarm;
            ServiceAppName       = "Search Service Application";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")
                    Export-TargetResource -SearchSAName "Search Service Application" | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
