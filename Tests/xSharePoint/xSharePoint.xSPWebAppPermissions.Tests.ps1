[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebAppPolicy"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWebAppPolicy" {
    InModuleScope $ModuleName {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $true
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user2"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
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

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "returns null from the set method" {
                { Set-TargetResource @testParams } | Should throw "Web application does not exist"
            }
        }

#AllPermissions specified together with one of the other parameters
#Not all three parameters specified
#AllPermissions specified, but FullMask is not set
#FullMask is set, but AllPermissions is not specified
#AllPermissions specified and FullMask is set
#List/Site/Personal permissions set, but ListPermissions does not match
#List/Site/Personal permissions set, but SitePermissions does not match
#List/Site/Personal permissions set, but PersonalPermissions does not match
#List/Site/Personal permissions set and all permissions match

        Context "Members and MembersToInclude parameters used simultaniously" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
            }
        }
    }    
}
