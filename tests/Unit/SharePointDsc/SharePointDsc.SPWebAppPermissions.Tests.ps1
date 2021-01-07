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
$script:DSCResourceName = 'SPWebAppPermissions'
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
                try
                {
                    [Microsoft.SharePoint.SPBasePermissions]
                }
                catch
                {
                    Add-Type -TypeDefinition @"
        namespace Microsoft.SharePoint {
            public enum SPBasePermissions {
                FullMask, EmptyMask, ManageLists, CancelCheckout, AddListItems, EditListItems, DeleteListItems,
                ViewListItems, ApproveItems, OpenItems, ViewVersions, DeleteVersions, CreateAlerts,
                ViewFormPages, ManagePermissions, ViewUsageData, ManageSubwebs, ManageWeb, AddAndCustomizePages,
                ApplyThemeAndBorder, ApplyStyleSheets, CreateGroups, BrowseDirectories,CreateSSCSite, ViewPages,
                EnumeratePermissions, BrowseUserInfo, ManageAlerts, UseRemoteAPIs, UseClientIntegration, Open,
                EditMyUserInfo, ManagePersonalViews, AddDelPrivateWebParts, UpdatePersonalWebParts
            };
        }
"@
                }
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
            Context -Name "The web application doesn't exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl      = "http://sharepoint.contoso.com"
                        AllPermissions = $true
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.ListPermissions | Should -BeNullOrEmpty
                    $result.SitePermissions | Should -BeNullOrEmpty
                    $result.PersonalPermissions | Should -BeNullOrEmpty
                }

                It "Should return exception from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "The specified web application could not be found."
                }
            }

            Context -Name "AllPermissions specified together with one of the other parameters" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        AllPermissions      = $true
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw ("Do not specify parameters " + `
                            "ListPermissions, SitePermissions or PersonalPermissions when " + `
                            "specifying parameter AllPermissions")
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw ("Do not specify parameters " + `
                            "ListPermissions, SitePermissions or PersonalPermissions when " + `
                            "specifying parameter AllPermissions")
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("Do not specify parameters " + `
                            "ListPermissions, SitePermissions or PersonalPermissions when " + `
                            "specifying parameter AllPermissions")
                }
            }

            Context -Name "Not all three parameters specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw ("One of the parameters " + `
                            "ListPermissions, SitePermissions or PersonalPermissions is missing")
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw ("One of the parameters " + `
                            "ListPermissions, SitePermissions or PersonalPermissions is missing")
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("One of the parameters " + `
                            "ListPermissions, SitePermissions or PersonalPermissions is missing")
                }
            }

            Context -Name "Approve items without Edit Items" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Delete Items", "View Items", "Approve Items", "Open Items",
                            "View Versions", "Delete Versions", "Create Alerts",
                            "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Edit Items is required when specifying Approve Items"
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Edit Items is required when specifying Approve Items"
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Edit Items is required when specifying Approve Items"
                }
            }

            Context -Name "View Items missing for various other parameters" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "Approve Items", "Open Items",
                            "View Versions", "Delete Versions", "Create Alerts",
                            "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw ("View Items is required when " + `
                            "specifying Manage Lists, Override List Behaviors, Add Items, Edit " + `
                            "Items, Delete Items, Approve Items, Open Items, View Versions, Delete " + `
                            "Versions, Create Alerts, Manage Permissions, Manage Web Site, Add and " + `
                            "Customize Pages, Manage Alerts, Use Client Integration Features, " + `
                            "Manage Personal Views, Add/Remove Personal Web Parts or Update " + `
                            "Personal Web Parts")
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw ("View Items is required when " + `
                            "specifying Manage Lists, Override List Behaviors, Add Items, Edit " + `
                            "Items, Delete Items, Approve Items, Open Items, View Versions, Delete " + `
                            "Versions, Create Alerts, Manage Permissions, Manage Web Site, Add and " + `
                            "Customize Pages, Manage Alerts, Use Client Integration Features, " + `
                            "Manage Personal Views, Add/Remove Personal Web Parts or Update " + `
                            "Personal Web Parts")
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("View Items is required when " + `
                            "specifying Manage Lists, Override List Behaviors, Add Items, Edit " + `
                            "Items, Delete Items, Approve Items, Open Items, View Versions, Delete " + `
                            "Versions, Create Alerts, Manage Permissions, Manage Web Site, Add and " + `
                            "Customize Pages, Manage Alerts, Use Client Integration Features, " + `
                            "Manage Personal Views, Add/Remove Personal Web Parts or Update " + `
                            "Personal Web Parts")
                }
            }

            Context -Name "View Versions or Manage Permissions without Open Items" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items",
                            "Approve Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw ("Open Items is required when " + `
                            "specifying View Versions or Manage Permissions")
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw ("Open Items is required when " + `
                            "specifying View Versions or Manage Permissions")
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("Open Items is required when " + `
                            "specifying View Versions or Manage Permissions")
                }
            }

            Context -Name "Delete Versions or Manage Permissions without View Versions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items",
                            "Approve Items", "Open Items", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw ("View Versions is required " + `
                            "when specifying Delete Versions or Manage Permissions")
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw ("View Versions is required " + `
                            "when specifying Delete Versions or Manage Permissions")
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("View Versions is required " + `
                            "when specifying Delete Versions or Manage Permissions")
                }
            }

            Context -Name "Manage Alerts without Create Alerts" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Create Alerts is required when specifying Manage Alerts"
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Create Alerts is required when specifying Manage Alerts"
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Create Alerts is required when specifying Manage Alerts"
                }
            }

            Context -Name "Manage Web Site without Add and Customize Pages" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Apply Themes and Borders", "Apply Style Sheets",
                            "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Add and Customize Pages is required when specifying Manage Web Site"
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Add and Customize Pages is required when specifying Manage Web Site"
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Add and Customize Pages is required when specifying Manage Web Site"
                }
            }

            Context -Name "Manage Permissions, Manage Web Site, Add and Customize Pages or Enumerate Permissions without Browse Directories" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw ("Browse Directories is " + `
                            "required when specifying Manage Permissions, Manage Web Site, " + `
                            "Add and Customize Pages or Enumerate Permissions")
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw ("Browse Directories is " + `
                            "required when specifying Manage Permissions, Manage Web Site, " + `
                            "Add and Customize Pages or Enumerate Permissions")
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("Browse Directories is " + `
                            "required when specifying Manage Permissions, Manage Web Site, " + `
                            "Add and Customize Pages or Enumerate Permissions")
                }
            }

            Context -Name "View Pages missing for various other parameters" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "Enumerate Permissions",
                            "Browse User Information", "Manage Alerts",
                            "Use Remote Interfaces", "Use Client Integration Features",
                            "Open", "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw ("View Pages is required when " + `
                            "specifying Manage Lists, Override List Behaviors, Add Items, Edit " + `
                            "Items, Delete Items, View Items, Approve Items, Open Items, View " + `
                            "Versions, Delete Versions, Create Alerts, Manage Permissions, View " + `
                            "Web Analytics Data, Create Subsites, Manage Web Site, Add and " + `
                            "Customize Pages, Apply Themes and Borders, Apply Style Sheets, Create " + `
                            "Groups, Browse Directories, Use Self-Service Site Creation, Enumerate " + `
                            "Permissions, Manage Alerts, Manage Personal Views, Add/Remove Personal " + `
                            "Web Parts or Update Personal Web Parts")
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw ("View Pages is required when " + `
                            "specifying Manage Lists, Override List Behaviors, Add Items, Edit " + `
                            "Items, Delete Items, View Items, Approve Items, Open Items, View " + `
                            "Versions, Delete Versions, Create Alerts, Manage Permissions, View " + `
                            "Web Analytics Data, Create Subsites, Manage Web Site, Add and " + `
                            "Customize Pages, Apply Themes and Borders, Apply Style Sheets, Create " + `
                            "Groups, Browse Directories, Use Self-Service Site Creation, Enumerate " + `
                            "Permissions, Manage Alerts, Manage Personal Views, Add/Remove Personal " + `
                            "Web Parts or Update Personal Web Parts")
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("View Pages is required when " + `
                            "specifying Manage Lists, Override List Behaviors, Add Items, Edit " + `
                            "Items, Delete Items, View Items, Approve Items, Open Items, View " + `
                            "Versions, Delete Versions, Create Alerts, Manage Permissions, View " + `
                            "Web Analytics Data, Create Subsites, Manage Web Site, Add and " + `
                            "Customize Pages, Apply Themes and Borders, Apply Style Sheets, Create " + `
                            "Groups, Browse Directories, Use Self-Service Site Creation, Enumerate " + `
                            "Permissions, Manage Alerts, Manage Personal Views, Add/Remove Personal " + `
                            "Web Parts or Update Personal Web Parts")
                }
            }

            Context -Name "Manage Permissions or Manage Web Site without Enumerate Permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Browse User Information", "Manage Alerts",
                            "Use Remote Interfaces", "Use Client Integration Features",
                            "Open", "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Enumerate Permissions is required when specifying Manage Permissions or Manage Web Site"
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Enumerate Permissions is required when specifying Manage Permissions or Manage Web Site"
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Enumerate Permissions is required when specifying Manage Permissions or Manage Web Site"
                }
            }

            Context -Name "Manage Permissions, Create Subsites, Manage Web Site, Create Groups, Use Self-Service Site Creation, Enumerate Permissions or Edit Personal User Information without Browse User Information" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Manage Alerts",
                            "Use Remote Interfaces", "Use Client Integration Features",
                            "Open", "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }
                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw ("Browse User Information is " + `
                            "required when specifying Manage Permissions, Create Subsites, " + `
                            "Manage Web Site, Create Groups, Use Self-Service Site Creation, " + `
                            "Enumerate Permissions or Edit Personal User Information")
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw ("Browse User Information is " + `
                            "required when specifying Manage Permissions, Create Subsites, " + `
                            "Manage Web Site, Create Groups, Use Self-Service Site Creation, " + `
                            "Enumerate Permissions or Edit Personal User Information")
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("Browse User Information is " + `
                            "required when specifying Manage Permissions, Create Subsites, " + `
                            "Manage Web Site, Create Groups, Use Self-Service Site Creation, " + `
                            "Enumerate Permissions or Edit Personal User Information")
                }
            }

            Context -Name "Use Client Integration Features without Use Remote Interfaces" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Use Remote Interfaces is required when specifying Use Client Integration Features"
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Use Remote Interfaces is required when specifying Use Client Integration Features"
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Use Remote Interfaces is required when specifying Use Client Integration Features"
                }
            }

            Context -Name "Open is required when specifying any of the other permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Open is required when specifying any of the other permissions"
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Open is required when specifying any of the other permissions"
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Open is required when specifying any of the other permissions"
                }
            }

            Context -Name "Add/Remove Personal Web Parts without Update Personal Web Parts" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = "Manage Personal Views", "Add/Remove Personal Web Parts"
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith { return $null }
                }

                It "Should return exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
                }

                It "Should return exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
                }

                It "Should return exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
                }
            }

            Context -Name "AllPermissions specified, but FullMask is not set" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl      = "http://sharepoint.contoso.com"
                        AllPermissions = $true
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            RightsMask = @("ManageLists", "CancelCheckout", "AddListItems", "EditListItems",
                                "DeleteListItems", "ViewListItems", "ApproveItems", "OpenItems",
                                "ViewVersions", "DeleteVersions", "CreateAlerts", "ViewFormPages")
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return $returnval
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update Web App permissions from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "FullMask is set, but AllPermissions is not specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            RightsMask = "FullMask"
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return $returnval
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update Web App permissions from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "AllPermissions specified and FullMask is set" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl      = "http://sharepoint.contoso.com"
                        AllPermissions = $true
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            RightsMask = "FullMask"
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return $returnval
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "List/Site/Personal permissions set, but ListPermissions does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            RightsMask = @("CancelCheckout", "AddListItems", "EditListItems", "DeleteListItems",
                                "ViewListItems", "ApproveItems", "OpenItems", "ViewVersions",
                                "DeleteVersions", "CreateAlerts", "ViewFormPages",
                                "ManagePermissions", "ViewUsageData", "ManageSubwebs", "ManageWeb",
                                "AddAndCustomizePages", "ApplyThemeAndBorder", "ApplyStyleSheets",
                                "CreateGroups", "BrowseDirectories", "CreateSSCSite", "ViewPages",
                                "EnumeratePermissions", "BrowseUserInfo", "ManageAlerts", "UseRemoteAPIs",
                                "UseClientIntegration", "Open", "EditMyUserInfo", "ManagePersonalViews",
                                "AddDelPrivateWebParts", "UpdatePersonalWebParts")
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return $returnval
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update Web App permissions from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "List/Site/Personal permissions set, but SitePermissions does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            RightsMask = @("ManageLists", "CancelCheckout", "AddListItems", "EditListItems",
                                "DeleteListItems", "ViewListItems", "ApproveItems", "OpenItems",
                                "ViewVersions", "DeleteVersions", "CreateAlerts", "ViewFormPages",
                                "ViewUsageData", "ManageSubwebs", "ManageWeb",
                                "AddAndCustomizePages", "ApplyThemeAndBorder", "ApplyStyleSheets",
                                "CreateGroups", "BrowseDirectories", "CreateSSCSite", "ViewPages",
                                "EnumeratePermissions", "BrowseUserInfo", "ManageAlerts",
                                "UseRemoteAPIs", "UseClientIntegration", "Open", "EditMyUserInfo",
                                "ManagePersonalViews", "AddDelPrivateWebParts",
                                "UpdatePersonalWebParts")
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return $returnval
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update Web App permissions from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "List/Site/Personal permissions set, but PersonalPermissions does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            RightsMask = @("ManageLists", "CancelCheckout", "AddListItems", "EditListItems",
                                "DeleteListItems", "ViewListItems", "ApproveItems", "OpenItems",
                                "ViewVersions", "DeleteVersions", "CreateAlerts", "ViewFormPages",
                                "ManagePermissions", "ViewUsageData", "ManageSubwebs", "ManageWeb",
                                "AddAndCustomizePages", "ApplyThemeAndBorder", "ApplyStyleSheets",
                                "CreateGroups", "BrowseDirectories", "CreateSSCSite", "ViewPages",
                                "EnumeratePermissions", "BrowseUserInfo", "ManageAlerts",
                                "UseRemoteAPIs", "UseClientIntegration", "Open", "EditMyUserInfo",
                                "AddDelPrivateWebParts", "UpdatePersonalWebParts")
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return $returnval
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update Web App permissions from the set method" {
                    $Global:SPDscWebApplicationUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "List/Site/Personal permissions set and all permissions match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl           = "http://sharepoint.contoso.com"
                        ListPermissions     = @("Manage Lists", "Override List Behaviors", "Add Items",
                            "Edit Items", "Delete Items", "View Items", "Approve Items",
                            "Open Items", "View Versions", "Delete Versions",
                            "Create Alerts", "View Application Pages")
                        SitePermissions     = @("Manage Permissions", "View Web Analytics Data",
                            "Create Subsites", "Manage Web Site",
                            "Add and Customize Pages", "Apply Themes and Borders",
                            "Apply Style Sheets", "Create Groups", "Browse Directories",
                            "Use Self-Service Site Creation", "View Pages",
                            "Enumerate Permissions", "Browse User Information",
                            "Manage Alerts", "Use Remote Interfaces",
                            "Use Client Integration Features", "Open",
                            "Edit Personal User Information")
                        PersonalPermissions = @("Manage Personal Views", "Add/Remove Personal Web Parts",
                            "Update Personal Web Parts")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $returnval = @{
                            RightsMask = @("ManageLists", "CancelCheckout", "AddListItems", "EditListItems",
                                "DeleteListItems", "ViewListItems", "ApproveItems", "OpenItems",
                                "ViewVersions", "DeleteVersions", "CreateAlerts", "ViewFormPages",
                                "ManagePermissions", "ViewUsageData", "ManageSubwebs", "ManageWeb",
                                "AddAndCustomizePages", "ApplyThemeAndBorder", "ApplyStyleSheets",
                                "CreateGroups", "BrowseDirectories", "CreateSSCSite", "ViewPages",
                                "EnumeratePermissions", "BrowseUserInfo", "ManageAlerts",
                                "UseRemoteAPIs", "UseClientIntegration", "Open", "EditMyUserInfo",
                                "ManagePersonalViews", "AddDelPrivateWebParts",
                                "UpdatePersonalWebParts")
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return $returnval
                    }
                }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            WebAppUrl           = "https://intranet.sharepoint.contoso.com"
                            ListPermissions     = "Manage Lists", "Override List Behaviors", "Add Items", "Edit Items", "Delete Items", "View Items", "Approve Items", "Open Items", "View Versions", "Delete Versions", "Create Alerts", "View Application Pages"
                            SitePermissions     = "Manage Permissions", "View Web Analytics Data", "Create Subsites", "Manage Web Site", "Add and Customize Pages", "Apply Themes and Borders", "Apply Style Sheets", "Create Groups", "Browse Directories", "Use Self-Service Site Creation", "View Pages", "Enumerate Permissions", "Browse User Information", "Manage Alerts", "Use Remote Interfaces", "Use Client Integration Features", "Open", "Edit Personal User Information"
                            PersonalPermissions = "Manage Personal Views", "Add/Remove Personal Web Parts", "Update Personal Web Parts"
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
        SPWebAppPermissions [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            ListPermissions      = \@\("Manage Lists","Override List Behaviors","Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"\);
            PersonalPermissions  = \@\("Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"\);
            PsDscRunAsCredential = \$Credsspfarm;
            SitePermissions      = \@\("Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"\);
            WebAppUrl            = "https://intranet.sharepoint.contoso.com";
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
