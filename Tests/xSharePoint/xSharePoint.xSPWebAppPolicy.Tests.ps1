[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
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
            WebAppUrl = "http://sites.contoso.com"
            UserName = "CONTOSO\Brian"
            PermissionLevel = "Full Control"
            ActAsSystemUser = $true
        }

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        try { [Microsoft.SharePoint.Administration.SPPolicyRoleType] }
        catch {
            Add-Type @"
namespace Microsoft.SharePoint.Administration {
    public enum SPPolicyRoleType { FullRead, FullControl, DenyWrite, DenyAll };
}        
"@
        }  

        Mock Get-SPWebApplication { 
            $webApp = @{
                Url = $testParams.WebAppUrl
                PolicyRoles = New-Object Object |
                                Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                Policies = @()
            }
            $webApp = $webApp | Add-Member ScriptMethod Update {
                $Global:xSPWebApplicationUpdateCalled = $true
            } -PassThru
            return @($webApp)
        }

        Context "No web app policy exists for the specified user" {
            It "returns null from the get method" {
            
            }

            It "returns false from the set method" {
            
            }

            It "creates a new policy" {
            
            }
        }

        Context "A policy exists for the user but the policy permission applied is wrong" {
            It "returns the current values from the get method" {
            
            }

            It "returns false from the test method" {
            
            }

            It "updates the existing policy" {
            
            }
        }

        Context "A policy exists for the user that is correct" {
            It "returns the current values from the get method" {
            
            }

            It "returns true from the test method" {
            
            }
        }

        Context "Policies of all permissions can be used to update an existing policies" {
            It "creates a full control policy" {
            
            }

            It "creates a full read policy" {
            
            }

            It "creates a deny write policy" {
            
            }

            It "creates a deny all policy" {
            
            }
        }

        $testParams.Remove("ActAsSystemUser")
        Context "Policies can be created and updated without the system account parameter" {
            It "creates a new policy without the system account paramter" {
            
            }

            It "updates an existing policy without the system account paramter" {
            
            }
        }
    }    
}