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


# No valid Web app specified
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
        
# Members specified with MembersToInclude
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
        
# Members specified with MembersToExclude
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
        
# ActAsSystemAccount specified without Full Control in Members
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

# ActAsSystemAccount specified without Full Control in MembersToInclude
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

# Members parameter has extra users
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

# Members parameter is missing users
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

# MembersToInclude is missing users
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

# MembersToInclude parameter does not contain users that are in the policy
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

# MembersToExclude has extra users
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

# Members user has incorrect settings: Permission level
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

# MembersToInclude user has incorrect settings: Permission level
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

# Members user has incorrect settings: Act as System Account
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

# MembersToInclude user has incorrect settings: Act as System Account
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

# Members is ok
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

# MembersToInclude is ok
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

# MembersToExclude is ok
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

<####################
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
        }#>
    }    
}