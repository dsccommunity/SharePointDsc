[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebAppPermissions"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWebAppPermissions" {
    InModuleScope $ModuleName {
            $testParams = @{
                WebAppUrl      = "http:/sharepoint.contoso.com"
                AllPermissions = $true
            }

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }

        Mock Remove-WebAppPolicy { }
        
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
                WebAppUrl      = "http:/sharepoint.contoso.com"
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
                WebAppUrl      = "http:/sharepoint.contoso.com"
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
                WebAppUrl      = "http:/sharepoint.contoso.com"
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
                WebAppUrl      = "http:/sharepoint.contoso.com"
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

        Context "AllPermissions specified, but FullMask is not set" {
            $testParams = @{
                WebAppUrl      = "http:/sharepoint.contoso.com"
                AllPermissions = $true
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "ManageLists","CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "FullMask is set, but AllPermissions is not specified" {
            $testParams = @{
                WebAppUrl           = "http:/sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "FullMask"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "AllPermissions specified and FullMask is set" {
            $testParams = @{
                WebAppUrl       = "http:/sharepoint.contoso.com"
                AllPermissions  = $true
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "FullMask"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
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
                WebAppUrl           = "http:/sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages","ManagePermissions","ViewUsageData","ManageSubwebs","ManageWeb","AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets","CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages","EnumeratePermissions","BrowseUserInfo","ManageAlerts","UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo","ManagePersonalViews","AddDelPrivateWebParts","UpdatePersonalWebParts"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "List/Site/Personal permissions set, but SitePermissions does not match" {
            $testParams = @{
                WebAppUrl           = "http:/sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "ManageLists","CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages","ViewUsageData","ManageSubwebs","ManageWeb","AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets","CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages","EnumeratePermissions","BrowseUserInfo","ManageAlerts","UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo","ManagePersonalViews","AddDelPrivateWebParts","UpdatePersonalWebParts"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }
        
        Context "List/Site/Personal permissions set, but PersonalPermissions does not match" {
            $testParams = @{
                WebAppUrl           = "http:/sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "ManageLists","CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages","ManagePermissions","ViewUsageData","ManageSubwebs","ManageWeb","AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets","CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages","EnumeratePermissions","BrowseUserInfo","ManageAlerts","UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo","AddDelPrivateWebParts","UpdatePersonalWebParts"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnval
             }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "updates Web App permissions from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "List/Site/Personal permissions set and all permissions match" {
            $testParams = @{
                WebAppUrl           = "http:/sharepoint.contoso.com"
                ListPermissions     = "Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages"
                SitePermissions     = "Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permissions","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information"
                PersonalPermissions = "Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts"
            }

            Mock Get-SPWebApplication {
                $returnval = @{
                    RightsMask = "ManageLists","CancelCheckout","AddListItems","EditListItems","DeleteListItems","ViewListItems","ApproveItems","OpenItems","ViewVersions","DeleteVersions","CreateAlerts","ViewFormPages","ManagePermissions","ViewUsageData","ManageSubwebs","ManageWeb","AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets","CreateGroups","BrowseDirectories","CreateSSCSite","ViewPages","EnumeratePermissions","BrowseUserInfo","ManageAlerts","UseRemoteAPIs","UseClientIntegration","Open","EditMyUserInfo","ManagePersonalViews","AddDelPrivateWebParts","UpdatePersonalWebParts"
                }
                
                $returnval = $returnval | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
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
