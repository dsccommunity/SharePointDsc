[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPServiceAppSecurity"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPServiceAppSecurity - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            ServiceAppName = "Example Service App"
            SecurityType = "SharingPermissions"
            Members = @(
                (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" -ClientOnly -Property @{
                    Username = "CONTOSO\user1"
                    AccessLevel = "Full Control"
                }),
                (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" -ClientOnly -Property @{
                    Username = "CONTOSO\user2"
                    AccessLevel = "Full Control"
                })
            )
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock Test-SPDSCIsADUser { return $true }
        
        Mock New-SPClaimsPrincipal { return @{ Value = "CONTOSO\user2" }}
        Mock Grant-SPObjectSecurity {}
        Mock Revoke-SPObjectSecurity {}
        Mock Set-SPServiceApplicationSecurity {}
        
        Context "The service app that security should be applied to does not exist" {
            
            Mock Get-SPServiceApplication { return $null }
            
            It "should return empty members list from the get method" {
                (Get-TargetResource @testParams).Members | Should BeNullOrEmpty
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        } 
        
        $testParams = @{
            ServiceAppName = "Example Service App"
            SecurityType = "SharingPermissions"
        }
        
        Context "None of the required members properties are provided" {
            
            It "should throw an exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw
            }
            
            It "should throw an exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
        
        $testParams = @{
            ServiceAppName = "Example Service App"
            SecurityType = "SharingPermissions"
            Members = @(
                (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" -ClientOnly -Property @{
                    Username = "CONTOSO\user1"
                    AccessLevel = "Full Control"
                })
            )
            MembersToInclude = @(
                (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" -ClientOnly -Property @{
                    Username = "CONTOSO\user1"
                    AccessLevel = "Full Control"
                })
            )
            MembersToExclude = @("CONTOSO\user2")
        }
        
        Context "All of the members properties are provided" {
            
            It "should throw an exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw
            }
            
            It "should throw an exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
        
        $testParams = @{
            ServiceAppName = "Example Service App"
            SecurityType = "SharingPermissions"
            Members = @(
                (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" -ClientOnly -Property @{
                    Username = "CONTOSO\user1"
                    AccessLevel = "Full Control"
                }),
                (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" -ClientOnly -Property @{
                    Username = "CONTOSO\user2"
                    AccessLevel = "Full Control"
                })
            )
        }
        
        Context "The service app exists and a fixed members list is provided that does not match the current settings" {
            
            Mock Get-SPServiceApplication { return @{} }
            Mock Get-SPServiceApplicationSecurity { return @{
                AccessRules = @(
                    @{
                        Name = "CONTOSO\user1"
                        AllowedRights = "Read"
                    }
                )
            }}
            
            It "should return a list of current members from the get method" {
                (Get-TargetResource @testParams).Members | Should Not BeNullOrEmpty
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should call the update cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Grant-SPObjectSecurity
                Assert-MockCalled Revoke-SPObjectSecurity
                Assert-MockCalled Set-SPServiceApplicationSecurity
            }
        }
        
        Context "The service app exists and a fixed members list is provided that does match the current settings" {
            
            Mock Get-SPServiceApplication { return @{} }
            Mock Get-SPServiceApplicationSecurity { return @{
                AccessRules = @(
                    @{
                        Name = "CONTOSO\user1"
                        AllowedRights = "FullControl"
                    },
                    @{
                        Name = "CONTOSO\user2"
                        AllowedRights = "FullControl"
                    }
                )
            }}
            
            It "should return a list of current members from the get method" {
                (Get-TargetResource @testParams).Members | Should Not BeNullOrEmpty
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams = @{
            ServiceAppName = "Example Service App"
            SecurityType = "SharingPermissions"
            MembersToInclude = @(
                (New-CimInstance -ClassName "MSFT_SPServiceAppSecurityEntry" -ClientOnly -Property @{
                    Username = "CONTOSO\user1"
                    AccessLevel = "Full Control"
                })
            )
            MembersToExclude = @("CONTOSO\user2")
        }
        
        Context "The service app exists and a specific list of members to add and remove is provided, which does not match the desired state" {
            
            Mock Get-SPServiceApplication { return @{} }
            Mock Get-SPServiceApplicationSecurity { return @{
                AccessRules = @(
                    @{
                        Name = "CONTOSO\user2"
                        AllowedRights = "FullControl"
                    }
                )
            }}
            
            It "should return a list of current members from the get method" {
                (Get-TargetResource @testParams).Members | Should Not BeNullOrEmpty
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should call the update cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Grant-SPObjectSecurity
                Assert-MockCalled Revoke-SPObjectSecurity
                Assert-MockCalled Set-SPServiceApplicationSecurity
            }
        }
        
        Context "The service app exists and a specific list of members to add and remove is provided, which does match the desired state" {
            
            Mock Get-SPServiceApplication { return @{} }
            Mock Get-SPServiceApplicationSecurity { return @{
                AccessRules = @(
                    @{
                        Name = "CONTOSO\user1"
                        AllowedRights = "FullControl"
                    }
                )
            }}
            
            It "should return a list of current members from the get method" {
                (Get-TargetResource @testParams).Members | Should Not BeNullOrEmpty
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}