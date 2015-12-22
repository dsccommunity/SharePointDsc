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


        Context "No web app policy exists for the specified user" {
            Mock Get-SPWebApplication { 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = New-Object Object |
                                    Add-Member ScriptMethod Add {
                                        $policy = @{
                                            IsSystemUser = $false
                                        }
                                        $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                                            return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                                        } -PassThru
                                        return $policy
                                    } -PassThru
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "creates a new policy" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "A policy exists for the user but the policy permission applied is wrong" {
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Deny All"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru | Add-Member ScriptMethod Add {} -PassThru -Force

                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = @(
                        @{
                            UserName = $testParams.UserName
                            PolicyRoleBindings = $roleBindings
                            IsSystemUser = $testParams.ActAsSystemUser
                        }
                    )
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns the current values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            $Global:xSPWebAppPolicyRemoveAllCalled = $false
            It "updates the existing policy" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
                $Global:xSPWebAppPolicyRemoveAllCalled | Should Be $true
            }
        }

        Context "A policy exists for the user that is correct" {
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = $testParams.PermissionLevel
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = @(
                        @{
                            UserName = $testParams.UserName
                            PolicyRoleBindings = $roleBindings
                            IsSystemUser = $testParams.ActAsSystemUser
                        }
                    )
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns the current values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Existing records with a claims based user name allow functions to still operate" {
             Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = $testParams.PermissionLevel
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = @(
                        @{
                            UserName = "i:0#.w|" + $testParams.UserName
                            PolicyRoleBindings = $roleBindings
                            IsSystemUser = $testParams.ActAsSystemUser
                        }
                    )
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }
            Mock New-SPClaimsPrincipal {
                return @{
                    Value = $testParams.UserName
                } 
            }

            It "returns the current values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Policies of all permissions can be used to add new policies" {
            Mock Get-SPWebApplication { 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = New-Object Object |
                                    Add-Member ScriptMethod Add {
                                        $policy = @{
                                            IsSystemUser = $false
                                        }
                                        $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                                            return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                                        } -PassThru
                                        return $policy
                                    } -PassThru
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            $testParams.PermissionLevel = "Full Control"
            $Global:xSPWebApplicationUpdateCalled = $false
            It "creates a full control policy" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }

            $testParams.PermissionLevel = "Full Read"
            $Global:xSPWebApplicationUpdateCalled = $false
            It "creates a full read policy" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }

            $testParams.PermissionLevel = "Deny Write"
            $Global:xSPWebApplicationUpdateCalled = $false
            It "creates a deny write policy" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }

            $testParams.PermissionLevel = "Deny All"
            $Global:xSPWebApplicationUpdateCalled = $false
            It "creates a deny all policy" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        $testParams.Remove("ActAsSystemUser")
        Context "Policies can be created and updated without the system account parameter" {
            It "creates a new policy without the system account paramter" {
                Mock Get-SPWebApplication { 
                    $webApp = @{
                        Url = $testParams.WebAppUrl
                        PolicyRoles = New-Object Object |
                                        Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                        Policies = New-Object Object |
                                        Add-Member ScriptMethod Add { 
                                            return New-Object Object |
                                                Add-Member ScriptProperty PolicyRoleBindings {
                                                    return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                                                } -PassThru | Add-Member ScriptProperty IsSystemUser {} -PassThru
                                        } -PassThru
                    }
                    $webApp = $webApp | Add-Member ScriptMethod Update {
                        $Global:xSPWebApplicationUpdateCalled = $true
                    } -PassThru
                    return @($webApp)
                }

                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }

            It "updates an existing policy without the system account paramter" {
                Mock Get-SPWebApplication { 
                    $roleBindings = @(
                        @{
                            Name = "Full Read"
                        }
                    )
                    $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                        $Global:xSPWebAppPolicyRemoveAllCalled = $true
                    } -PassThru | Add-Member ScriptMethod Add {} -PassThru -Force

                    $webApp = @{
                        Url = $testParams.WebAppUrl
                        PolicyRoles = New-Object Object |
                                        Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                        Policies = @(
                            @{
                                UserName = $testParams.UserName
                                PolicyRoleBindings = $roleBindings
                                IsSystemUser = $testParams.ActAsSystemUser
                            }
                        )
                    }
                    $webApp = $webApp | Add-Member ScriptMethod Update {
                        $Global:xSPWebApplicationUpdateCalled = $true
                    } -PassThru
                    return @($webApp)
                }
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }
    }    
}