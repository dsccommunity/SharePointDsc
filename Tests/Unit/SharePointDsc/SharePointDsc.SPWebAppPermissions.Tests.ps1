[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPWebAppPermissions"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        try { [Microsoft.SharePoint.SPBasePermissions] }
        catch {
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

        # Test contexts
        Context -Name "The web application doesn't exist" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                AllPermissions = $true
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "The specified web application could not be found."
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "The specified web application could not be found."
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "The specified web application could not be found."
            }
        }

        Context -Name "AllPermissions specified together with one of the other parameters" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                AllPermissions = $true
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }
            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw ("Do not specify parameters " + `
                        "ListPermissions, SitePermissions or PersonalPermissions when " + `
                        "specifying parameter AllPermissions")
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw ("Do not specify parameters " + `
                        "ListPermissions, SitePermissions or PersonalPermissions when " + `
                        "specifying parameter AllPermissions")
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw ("Do not specify parameters " + `
                        "ListPermissions, SitePermissions or PersonalPermissions when " + `
                        "specifying parameter AllPermissions")
            }
        }

        Context -Name "Not all three parameters specified" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw ("One of the parameters " + `
                            "ListPermissions, SitePermissions or PersonalPermissions is missing")
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw ("One of the parameters " + `
                            "ListPermissions, SitePermissions or PersonalPermissions is missing")
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw ("One of the parameters " + `
                            "ListPermissions, SitePermissions or PersonalPermissions is missing")
            }
        }

        Context -Name "Approve items without Edit Items" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Delete Items","View Items","Approve Items","Open Items",
                                        "View Versions","Delete Versions","Create Alerts",
                                        "View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Edit Items is required when specifying Approve Items"
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Edit Items is required when specifying Approve Items"
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Edit Items is required when specifying Approve Items"
            }
        }

        Context -Name "View Items missing for various other parameters" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","Approve Items","Open Items",
                                        "View Versions","Delete Versions","Create Alerts",
                                        "View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw ("View Items is required when " + `
                        "specifying Manage Lists, Override List Behaviors, Add Items, Edit " + `
                        "Items, Delete Items, Approve Items, Open Items, View Versions, Delete " + `
                        "Versions, Create Alerts, Manage Permissions, Manage Web Site, Add and " + `
                        "Customize Pages, Manage Alerts, Use Client Integration Features, " + `
                        "Manage Personal Views, Add/Remove Personal Web Parts or Update " + `
                        "Personal Web Parts")
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw ("View Items is required when " + `
                        "specifying Manage Lists, Override List Behaviors, Add Items, Edit " + `
                        "Items, Delete Items, Approve Items, Open Items, View Versions, Delete " + `
                        "Versions, Create Alerts, Manage Permissions, Manage Web Site, Add and " + `
                        "Customize Pages, Manage Alerts, Use Client Integration Features, " + `
                        "Manage Personal Views, Add/Remove Personal Web Parts or Update " + `
                        "Personal Web Parts")
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw ("View Items is required when " + `
                        "specifying Manage Lists, Override List Behaviors, Add Items, Edit " + `
                        "Items, Delete Items, Approve Items, Open Items, View Versions, Delete " + `
                        "Versions, Create Alerts, Manage Permissions, Manage Web Site, Add and " + `
                        "Customize Pages, Manage Alerts, Use Client Integration Features, " + `
                        "Manage Personal Views, Add/Remove Personal Web Parts or Update " + `
                        "Personal Web Parts")
            }
        }

        Context -Name "View Versions or Manage Permissions without Open Items" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items",
                                        "Approve Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw ("Open Items is required when " + `
                            "specifying View Versions or Manage Permissions")
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw ("Open Items is required when " + `
                            "specifying View Versions or Manage Permissions")
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw ("Open Items is required when " + `
                            "specifying View Versions or Manage Permissions")
            }
        }

        Context -Name "Delete Versions or Manage Permissions without View Versions" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items",
                                        "Approve Items","Open Items","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw ("View Versions is required " + `
                                "when specifying Delete Versions or Manage Permissions")
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw ("View Versions is required " + `
                                "when specifying Delete Versions or Manage Permissions")
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw ("View Versions is required " + `
                                "when specifying Delete Versions or Manage Permissions")
            }
        }
        
        Context -Name "Manage Alerts without Create Alerts" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Create Alerts is required when specifying Manage Alerts"
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Create Alerts is required when specifying Manage Alerts"
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Create Alerts is required when specifying Manage Alerts"
            }
        }

        Context -Name "Manage Web Site without Add and Customize Pages" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Apply Themes and Borders","Apply Style Sheets",
                                        "Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }
            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Add and Customize Pages is required when specifying Manage Web Site"
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Add and Customize Pages is required when specifying Manage Web Site"
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Add and Customize Pages is required when specifying Manage Web Site"
            }
        }

        Context -Name "Manage Permissions, Manage Web Site, Add and Customize Pages or Enumerate Permissions without Browse Directories" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }
            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw ("Browse Directories is " + `
                            "required when specifying Manage Permissions, Manage Web Site, " + `
                            "Add and Customize Pages or Enumerate Permissions")
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw ("Browse Directories is " + `
                            "required when specifying Manage Permissions, Manage Web Site, " + `
                            "Add and Customize Pages or Enumerate Permissions")
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw ("Browse Directories is " + `
                            "required when specifying Manage Permissions, Manage Web Site, " + `
                            "Add and Customize Pages or Enumerate Permissions")
            }
        }
    
        Context -Name "View Pages missing for various other parameters" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","Enumerate Permissions",
                                        "Browse User Information","Manage Alerts",
                                        "Use Remote Interfaces","Use Client Integration Features",
                                        "Open","Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }
            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw ("View Pages is required when " + `
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
                { Test-TargetResource @testParams } | Should throw ("View Pages is required when " + `
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
                { Set-TargetResource @testParams } | Should throw ("View Pages is required when " + `
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
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Browse User Information","Manage Alerts",
                                        "Use Remote Interfaces","Use Client Integration Features",
                                        "Open","Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Enumerate Permissions is required when specifying Manage Permissions or Manage Web Site"
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Enumerate Permissions is required when specifying Manage Permissions or Manage Web Site"
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Enumerate Permissions is required when specifying Manage Permissions or Manage Web Site"
            }
        }

        Context -Name "Manage Permissions, Create Subsites, Manage Web Site, Create Groups, Use Self-Service Site Creation, Enumerate Permissions or Edit Personal User Information without Browse User Information" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Manage Alerts",
                                        "Use Remote Interfaces","Use Client Integration Features",
                                        "Open","Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }
            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw ("Browse User Information is " + `
                            "required when specifying Manage Permissions, Create Subsites, " + `
                            "Manage Web Site, Create Groups, Use Self-Service Site Creation, " + `
                            "Enumerate Permissions or Edit Personal User Information")
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw ("Browse User Information is " + `
                            "required when specifying Manage Permissions, Create Subsites, " + `
                            "Manage Web Site, Create Groups, Use Self-Service Site Creation, " + `
                            "Enumerate Permissions or Edit Personal User Information")
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw ("Browse User Information is " + `
                            "required when specifying Manage Permissions, Create Subsites, " + `
                            "Manage Web Site, Create Groups, Use Self-Service Site Creation, " + `
                            "Enumerate Permissions or Edit Personal User Information")
            }
        }

        Context -Name "Use Client Integration Features without Use Remote Interfaces" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Use Remote Interfaces is required when specifying Use Client Integration Features"
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Use Remote Interfaces is required when specifying Use Client Integration Features"
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Use Remote Interfaces is required when specifying Use Client Integration Features"
            }
        }

        Context -Name "Open is required when specifying any of the other permissions" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Open is required when specifying any of the other permissions"
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Open is required when specifying any of the other permissions"
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Open is required when specifying any of the other permissions"
            }
        }

        Context -Name "Add/Remove Personal Web Parts without Update Personal Web Parts" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts"
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
            }

            It "Should return exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
            }

            It "Should return exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
            }
        }

        Context -Name "AllPermissions specified, but FullMask is not set" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                AllPermissions = $true
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $returnval = @{
                    RightsMask = @("ManageLists","CancelCheckout","AddListItems","EditListItems",
                                   "DeleteListItems","ViewListItems","ApproveItems","OpenItems",
                                   "ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages")
                }
                
                $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "Should update Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "FullMask is set, but AllPermissions is not specified" -Fixture {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
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

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "Should update Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "AllPermissions specified and FullMask is set" -Fixture {
            $testParams = @{
                WebAppUrl       = "http://sharepoint.contoso.com"
                AllPermissions  = $true
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

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "List/Site/Personal permissions set, but ListPermissions does not match" -Fixture {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $returnval = @{
                    RightsMask = @("CancelCheckout","AddListItems","EditListItems","DeleteListItems",
                                   "ViewListItems","ApproveItems","OpenItems","ViewVersions",
                                   "DeleteVersions","CreateAlerts","ViewFormPages",
                                   "ManagePermissions","ViewUsageData","ManageSubwebs","ManageWeb",
                                   "AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets",
                                   "CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages",
                                   "EnumeratePermissions","BrowseUserInfo","ManageAlerts","UseRemoteAPIs",
                                   "UseClientIntegration","Open","EditMyUserInfo","ManagePersonalViews",
                                   "AddDelPrivateWebParts","UpdatePersonalWebParts")
                }
                
                $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "Should update Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "List/Site/Personal permissions set, but SitePermissions does not match" -Fixture {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $returnval = @{
                    RightsMask = @("ManageLists","CancelCheckout","AddListItems","EditListItems",
                                   "DeleteListItems","ViewListItems","ApproveItems","OpenItems",
                                   "ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages",
                                   "ViewUsageData","ManageSubwebs","ManageWeb",
                                   "AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets",
                                   "CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages",
                                   "EnumeratePermissions","BrowseUserInfo","ManageAlerts",
                                   "UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo",
                                   "ManagePersonalViews","AddDelPrivateWebParts",
                                   "UpdatePersonalWebParts")
                }
                
                $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "Should update Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }
        
        Context -Name "List/Site/Personal permissions set, but PersonalPermissions does not match" -Fixture {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $returnval = @{
                    RightsMask = @("ManageLists","CancelCheckout","AddListItems","EditListItems",
                                   "DeleteListItems","ViewListItems","ApproveItems","OpenItems",
                                   "ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages",
                                   "ManagePermissions","ViewUsageData","ManageSubwebs","ManageWeb",
                                   "AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets",
                                   "CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages",
                                   "EnumeratePermissions","BrowseUserInfo","ManageAlerts",
                                   "UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo",
                                   "AddDelPrivateWebParts","UpdatePersonalWebParts")
                }
                
                $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "Should update Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context -Name "List/Site/Personal permissions set and all permissions match" -Fixture {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = @("Manage Lists","Override List Behaviors", "Add Items",
                                        "Edit Items","Delete Items","View Items","Approve Items",
                                        "Open Items","View Versions","Delete Versions",
                                        "Create Alerts","View Application Pages")
                SitePermissions     = @("Manage Permissions","View Web Analytics Data",
                                        "Create Subsites","Manage Web Site",
                                        "Add and Customize Pages","Apply Themes and Borders",
                                        "Apply Style Sheets","Create Groups","Browse Directories",
                                        "Use Self-Service Site Creation","View Pages",
                                        "Enumerate Permissions","Browse User Information",
                                        "Manage Alerts","Use Remote Interfaces",
                                        "Use Client Integration Features","Open",
                                        "Edit Personal User Information")
                PersonalPermissions = @("Manage Personal Views","Add/Remove Personal Web Parts",
                                        "Update Personal Web Parts")
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $returnval = @{
                    RightsMask = @("ManageLists","CancelCheckout","AddListItems","EditListItems",
                                   "DeleteListItems","ViewListItems","ApproveItems","OpenItems",
                                   "ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages",
                                   "ManagePermissions","ViewUsageData","ManageSubwebs","ManageWeb",
                                   "AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets",
                                   "CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages",
                                   "EnumeratePermissions","BrowseUserInfo","ManageAlerts",
                                   "UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo",
                                   "ManagePersonalViews","AddDelPrivateWebParts",
                                   "UpdatePersonalWebParts")
                }
                
                $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
