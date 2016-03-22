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
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        try { [Microsoft.SharePoint.Administration.SPPolicyRoleType] }
        catch {
            Add-Type @"
namespace Microsoft.SharePoint.Administration {
    public enum SPPolicyRoleType { FullRead, FullControl, DenyWrite, DenyAll };
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
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }
        
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
        
        Context "No Member parameters at all" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
            }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
            }
        }
        
        Context "ActAsSystemAccount parameter specified without Full Control in Members" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $true
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
                { Set-TargetResource @testParams } | Should throw "Members Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"
            }
        }

        Context "ActAsSystemAccount parameter specified without Full Control in MembersToInclude" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $true
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
                { Set-TargetResource @testParams } | Should throw "MembersToInclude Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"
            }
        }

        Context "The Members parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "contoso\sp_psu"
                        portalsuperreaderaccount = "contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "add user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The Members parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "contoso\sp_psu"
                        portalsuperreaderaccount = "contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "add user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The Members parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the webapp" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                    }
                }
                
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount properties is not configured."
            }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount properties is not configured."
            }
        }

        Context "The MembersToInclude parameter used with SetCacheAccounts to True, but the Cache Users users aren't configured in the webapp" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                    }
                }
                
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount properties is not configured."
            }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount properties is not configured."
            }
        }

        Context "The Members parameter used with SetCacheAccounts to True and the Cache Users users are configured correctly" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\sp_psu"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\sp_psr"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "contoso\sp_psu"
                        portalsuperreaderaccount = "contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The MembersToInclude parameter used with SetCacheAccounts to True and the Cache Users users are configured correctly" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
                SetCacheAccounts=$true
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\sp_psu"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\sp_psr"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "contoso\sp_psu"
                        portalsuperreaderaccount = "contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The MembersToExclude parameter used, but it specifies a Cache User" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToExclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\sp_psr"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\sp_psu"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\sp_psr"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{
                        portalsuperuseraccount = "contoso\sp_psu"
                        portalsuperreaderaccount = "contoso\sp_psr"
                    }
                }
                
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should throw "You cannot exclude the Cache accounts from the Web Application Policy"
            }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "You cannot exclude the Cache accounts from the Web Application Policy"
            }
        }

        Context "The Members parameter contains users that aren't configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user2"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "add user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The Members parameter does not contains users that are configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\user2"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "remove user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The MembersToInclude parameter contains users that are not configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user2"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "add user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The MembersToInclude parameter contains users that are not configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Read"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    },
                    @{
                        UserName = "contoso\user2"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )

                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }



            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The MembersToExclude parameter contains users that are configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToExclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                    @{
                        UserName = "contoso\user2"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru | 
                Add-Member NoteProperty Properties @{} -PassThru
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "remove user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The users in the Members parameter have different settings than configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru
                $roleBindings = $roleBindings | Add-Member ScriptMethod Add {
                    $Global:xSPWebAppPolicyAddCalled = $true
                } -PassThru -Force

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "correct user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The users in the MembersToInclude parameter have different settings than configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Read"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru
                $roleBindings = $roleBindings | Add-Member ScriptMethod Add {
                    $Global:xSPWebAppPolicyAddCalled = $true
                } -PassThru -Force

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "correct user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The users in the Members parameter have different settings than configured in the policy - ActAsSystemAccount" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $true
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru
                $roleBindings = $roleBindings | Add-Member ScriptMethod Add {
                    $Global:xSPWebAppPolicyAddCalled = $true
                } -PassThru -Force

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "correct user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The users in the MembersToInclude parameter have different settings than configured in the policy - ActAsSystemAccount" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $true
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )
                $roleBindings = $roleBindings | Add-Member ScriptMethod RemoveAll {
                    $Global:xSPWebAppPolicyRemoveAllCalled = $true
                } -PassThru
                $roleBindings = $roleBindings | Add-Member ScriptMethod Add {
                    $Global:xSPWebAppPolicyAddCalled = $true
                } -PassThru -Force

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                $policies = $policies | Add-Member ScriptMethod Add {
                    $policy = @{
                        IsSystemUser = $false
                    }
                    $policy = $policy | Add-Member ScriptProperty PolicyRoleBindings {
                        return New-Object Object | Add-Member ScriptMethod Add {} -PassThru
                    } -PassThru
                    return $policy
                } -PassThru -Force
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "correct user policy from the set method" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "The users in the Members parameter have the same settings as configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                Members = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The users in the MembersToInclude parameter have the same  settings as configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToInclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $false
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The users in the MembersToExclude parameter aren't configured in the policy" {
            $testParams = @{
                WebAppUrl   = "http:/sharepoint.contoso.com"
                MembersToExclude = @(
                    (New-CimInstance -ClassName MSFT_xSPWebAppPolicy -Property @{
                        Username           = "contoso\user2"
                    } -ClientOnly)
                )
            }
            Mock Get-SPWebApplication { 
                $roleBindings = @(
                    @{
                        Name = "Full Control"
                    }
                )

                $policies = @(
                    @{
                        UserName = "contoso\user1"
                        PolicyRoleBindings = $roleBindings
                        IsSystemUser = $false
                    }   
                )
                 
                $webApp = @{
                    Url = $testParams.WebAppUrl
                    PolicyRoles = New-Object Object |
                                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                    Policies = $policies
                    Properties = @{}
                }
                return @($webApp)
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}