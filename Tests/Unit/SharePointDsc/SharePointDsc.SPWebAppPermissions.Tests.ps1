[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPWebAppPermissions"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPWebAppPermissions" {
    InModuleScope $ModuleName {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                AllPermissions = $true
            }

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        try { [Microsoft.SharePoint.SPBasePermissions] }
        catch {
            Add-Type @"
namespace Microsoft.SharePoint {
    public enum SPBasePermissions { FullMask, EmptyMask, ManageLists, CancelCheckout, AddListItems, EditListItems, DeleteListItems, ViewListItems, ApproveItems, OpenItems, ViewVersions, DeleteVersions, CreateAlerts, ViewFormPages, ManagePermissions, ViewUsageData, ManageSubwebs, ManageWeb, AddAndCustomizePages, ApplyThemeAndBorder, ApplyStyleSheets, CreateGroups, BrowseDirectories,CreateSSCSite, ViewPages, EnumeratePermissions, BrowseUserInfo, ManageAlerts, UseRemoteAPIs, UseClientIntegration, Open, EditMyUserInfo, ManagePersonalViews, AddDelPrivateWebParts, UpdatePersonalWebParts};
}
"@
        }

        Context "The web application doesn't exist" {
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "The specified web application could not be found."
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "The specified web application could not be found."
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "The specified web application could not be found."
            }
        }

        Context "AllPermissions specified together with one of the other parameters" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                AllPermissions = $true
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Do not specify parameters ListPermissions, SitePermissions or PersonalPermissions when specifying parameter AllPermissions"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Do not specify parameters ListPermissions, SitePermissions or PersonalPermissions when specifying parameter AllPermissions"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Do not specify parameters ListPermissions, SitePermissions or PersonalPermissions when specifying parameter AllPermissions"
            }
        }

        Context "Not all three parameters specified" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "One of the parameters ListPermissions, SitePermissions or PersonalPermissions is missing"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "One of the parameters ListPermissions, SitePermissions or PersonalPermissions is missing"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "One of the parameters ListPermissions, SitePermissions or PersonalPermissions is missing"
            }
        }

        Context "Approve items without Edit Items" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Edit Items is required when specifying Approve Items"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Edit Items is required when specifying Approve Items"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Edit Items is required when specifying Approve Items"
            }
        }

        Context "View Items missing for various other parameters" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "View Items is required when specifying Manage Lists, Override List Behaviors, Add Items, Edit Items, Delete Items, Approve Items, Open Items, View Versions, Delete Versions, Create Alerts, Manage Permissions, Manage Web Site, Add and Customize Pages, Manage Alerts, Use Client Integration Features, Manage Personal Views, Add/Remove Personal Web Parts or Update Personal Web Parts"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "View Items is required when specifying Manage Lists, Override List Behaviors, Add Items, Edit Items, Delete Items, Approve Items, Open Items, View Versions, Delete Versions, Create Alerts, Manage Permissions, Manage Web Site, Add and Customize Pages, Manage Alerts, Use Client Integration Features, Manage Personal Views, Add/Remove Personal Web Parts or Update Personal Web Parts"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "View Items is required when specifying Manage Lists, Override List Behaviors, Add Items, Edit Items, Delete Items, Approve Items, Open Items, View Versions, Delete Versions, Create Alerts, Manage Permissions, Manage Web Site, Add and Customize Pages, Manage Alerts, Use Client Integration Features, Manage Personal Views, Add/Remove Personal Web Parts or Update Personal Web Parts"
            }
        }

        Context "View Versions or Manage Permissions without Open Items" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Open Items is required when specifying View Versions or Manage Permissions"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Open Items is required when specifying View Versions or Manage Permissions"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Open Items is required when specifying View Versions or Manage Permissions"
            }
        }

        Context "Delete Versions or Manage Permissions without View Versions" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "View Versions is required when specifying Delete Versions or Manage Permissions"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "View Versions is required when specifying Delete Versions or Manage Permissions"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "View Versions is required when specifying Delete Versions or Manage Permissions"
            }
        }
        
        Context "Manage Alerts without Create Alerts" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Create Alerts is required when specifying Manage Alerts"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Create Alerts is required when specifying Manage Alerts"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Create Alerts is required when specifying Manage Alerts"
            }
        }

        Context "Manage Web Site without Add and Customize Pages" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Add and Customize Pages is required when specifying Manage Web Site"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Add and Customize Pages is required when specifying Manage Web Site"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Add and Customize Pages is required when specifying Manage Web Site"
            }
        }

        Context "Manage Permissions, Manage Web Site, Add and Customize Pages or Enumerate Permissions without Browse Directories" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Browse Directories is required when specifying Manage Permissions, Manage Web Site, Add and Customize Pages or Enumerate Permissions"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Browse Directories is required when specifying Manage Permissions, Manage Web Site, Add and Customize Pages or Enumerate Permissions"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Browse Directories is required when specifying Manage Permissions, Manage Web Site, Add and Customize Pages or Enumerate Permissions"
            }
        }
    
        Context "View Pages missing for various other parameters" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "View Pages is required when specifying Manage Lists, Override List Behaviors, Add Items, Edit Items, Delete Items, View Items, Approve Items, Open Items, View Versions, Delete Versions, Create Alerts, Manage Permissions, View Web Analytics Data, Create Subsites, Manage Web Site, Add and Customize Pages, Apply Themes and Borders, Apply Style Sheets, Create Groups, Browse Directories, Use Self-Service Site Creation, Enumerate Permissions, Manage Alerts, Manage Personal Views, Add/Remove Personal Web Parts or Update Personal Web Parts"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "View Pages is required when specifying Manage Lists, Override List Behaviors, Add Items, Edit Items, Delete Items, View Items, Approve Items, Open Items, View Versions, Delete Versions, Create Alerts, Manage Permissions, View Web Analytics Data, Create Subsites, Manage Web Site, Add and Customize Pages, Apply Themes and Borders, Apply Style Sheets, Create Groups, Browse Directories, Use Self-Service Site Creation, Enumerate Permissions, Manage Alerts, Manage Personal Views, Add/Remove Personal Web Parts or Update Personal Web Parts"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "View Pages is required when specifying Manage Lists, Override List Behaviors, Add Items, Edit Items, Delete Items, View Items, Approve Items, Open Items, View Versions, Delete Versions, Create Alerts, Manage Permissions, View Web Analytics Data, Create Subsites, Manage Web Site, Add and Customize Pages, Apply Themes and Borders, Apply Style Sheets, Create Groups, Browse Directories, Use Self-Service Site Creation, Enumerate Permissions, Manage Alerts, Manage Personal Views, Add/Remove Personal Web Parts or Update Personal Web Parts"
            }
        }

        Context "Manage Permissions or Manage Web Site without Enumerate Permissions" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Enumerate Permissions is required when specifying Manage Permissions or Manage Web Site"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Enumerate Permissions is required when specifying Manage Permissions or Manage Web Site"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Enumerate Permissions is required when specifying Manage Permissions or Manage Web Site"
            }
        }

        Context "Manage Permissions, Create Subsites, Manage Web Site, Create Groups, Use Self-Service Site Creation, Enumerate Permissions or Edit Personal User Information without Browse User Information" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Browse User Information is required when specifying Manage Permissions, Create Subsites, Manage Web Site, Create Groups, Use Self-Service Site Creation, Enumerate Permissions or Edit Personal User Information"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Browse User Information is required when specifying Manage Permissions, Create Subsites, Manage Web Site, Create Groups, Use Self-Service Site Creation, Enumerate Permissions or Edit Personal User Information"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Browse User Information is required when specifying Manage Permissions, Create Subsites, Manage Web Site, Create Groups, Use Self-Service Site Creation, Enumerate Permissions or Edit Personal User Information"
            }
        }

        Context "Use Client Integration Features without Use Remote Interfaces" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Use Remote Interfaces is required when specifying Use Client Integration Features"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Use Remote Interfaces is required when specifying Use Client Integration Features"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Use Remote Interfaces is required when specifying Use Client Integration Features"
            }
        }

        Context "Open is required when specifying any of the other permissions" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Open is required when specifying any of the other permissions"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Open is required when specifying any of the other permissions"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Open is required when specifying any of the other permissions"
            }
        }

        Context "Add/Remove Personal Web Parts without Update Personal Web Parts" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts"
            }
            Mock Get-SPWebApplication { return $null }

            It "returns exception from the get method" {
                { Get-TargetResource @testParams } | Should throw "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
            }

            It "returns exception from the test method" {
                { Test-TargetResource @testParams } | Should throw "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
            }

            It "returns exception from the set method" {
                { Set-TargetResource @testParams } | Should throw "Update Personal Web Parts is required when specifying Add/Remove Personal Web Parts"
            }
        }

        Context "AllPermissions specified, but FullMask is not set" {
            $testParams = @{
                WebAppUrl      = "http://sharepoint.contoso.com"
                AllPermissions = $true
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "ManageLists","CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:SPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "FullMask is set, but AllPermissions is not specified" {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "FullMask"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:SPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "AllPermissions specified and FullMask is set" {
            $testParams = @{
                WebAppUrl       = "http://sharepoint.contoso.com"
                AllPermissions  = $true
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "FullMask"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:SPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "List/Site/Personal permissions set, but ListPermissions does not match" {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages","ManagePermissions","ViewUsageData","ManageSubwebs","ManageWeb","AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets","CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages","EnumeratePermissions","BrowseUserInfo","ManageAlerts","UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo","ManagePersonalViews","AddDelPrivateWebParts","UpdatePersonalWebParts"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:SPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "List/Site/Personal permissions set, but SitePermissions does not match" {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "ManageLists","CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages","ViewUsageData","ManageSubwebs","ManageWeb","AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets","CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages","EnumeratePermissions","BrowseUserInfo","ManageAlerts","UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo","ManagePersonalViews","AddDelPrivateWebParts","UpdatePersonalWebParts"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:SPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPWebApplicationUpdateCalled | Should Be $true
            }
        }
        
        Context "List/Site/Personal permissions set, but PersonalPermissions does not match" {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "ManageLists","CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages","ManagePermissions","ViewUsageData","ManageSubwebs","ManageWeb","AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets","CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages","EnumeratePermissions","BrowseUserInfo","ManageAlerts","UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo","AddDelPrivateWebParts","UpdatePersonalWebParts"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:SPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:SPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "List/Site/Personal permissions set and all permissions match" {
            $testParams = @{
                WebAppUrl           = "http://sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "ManageLists","CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages","ManagePermissions","ViewUsageData","ManageSubwebs","ManageWeb","AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets","CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages","EnumeratePermissions","BrowseUserInfo","ManageAlerts","UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo","ManagePersonalViews","AddDelPrivateWebParts","UpdatePersonalWebParts"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:SPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
