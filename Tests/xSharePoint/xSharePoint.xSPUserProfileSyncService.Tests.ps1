[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPUserProfileSyncService"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPUserProfileSyncService" {
    InModuleScope $ModuleName {
        $testParams = @{
            UserProfileServiceAppName = "User Profile Service Service App"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        Mock Initialize-xSharePointPSSnapin { } -ModuleName "xSharePoint.Util"
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock Get-SPFarm { return @{
            DefaultServiceAccount = @{ Name = $testParams.FarmAccount.Username }
        }}
        Mock Start-SPServiceInstance { }
        Mock Stop-SPServiceInstance { }
        Mock Restart-Service { }
        Mock Add-xSharePointUserToLocalAdmin { } 
        Mock Test-xSharePointUserIsLocalAdmin { return $false }
        Mock Remove-xSharePointUserToLocalAdmin { }
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"

        Context "User profile sync service is not running and should be" {
            Mock Get-SPServiceInstance { if ($Global:xSharePointUPACheck -eq $false) {
                    $Global:xSharePointUPACheck = $true
                    return @( @{ 
                        Status = "Disabled"
                        ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        UserProfileApplicationGuid = [Guid]::Empty
                        TypeName = "User Profile Synchronization Service" 
                    }) 
                } else {
                    return @( @{ 
                        Status = "Online"
                        ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        UserProfileApplicationGuid = [Guid]::NewGuid()
                        TypeName = "User Profile Synchronization Service" 
                    })
                }
            } 

            It "returns absent from the get method" {
                $Global:xSharePointUPACheck = $false
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                $Global:xSharePointUPACheck = $false
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the start service cmdlet from the set method" {
                $Global:xSharePointUPACheck = $false
                Mock Set-xSharePointUserProfileSyncMachine { } 
                Set-TargetResource @testParams 

                Assert-MockCalled Start-SPServiceInstance
            }
        }

        Context "User profile sync service is running and should be" {
            Mock Get-SPServiceInstance { return @( @{ 
                        Status = "Online"
                        ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        UserProfileApplicationGuid = [Guid]::NewGuid()
                        TypeName = "User Profile Synchronization Service" 
                    })
            } 
        
            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        $testParams.Ensure = "Absent"

        Context "User profile sync service is running and shouldn't be" {
            Mock Get-SPServiceInstance { if ($Global:xSharePointUPACheck -eq $false) {
                    $Global:xSharePointUPACheck = $true
                    return @( @{ 
                        Status = "Online"
                        ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        UserProfileApplicationGuid = [Guid]::NewGuid()
                        TypeName = "User Profile Synchronization Service" 
                    }) 
                } else {
                    return @( @{ 
                        Status = "Disabled"
                        ID = [Guid]::Empty
                        UserProfileApplicationGuid = [Guid]::Empty
                        TypeName = "User Profile Synchronization Service" 
                    })
                }
            } 

            It "returns present from the get method" {
                $Global:xSharePointUPACheck = $false
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                $Global:xSharePointUPACheck = $false
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the start service cmdlet from the set method" {
                $Global:xSharePointUPACheck = $false
                Mock Set-xSharePointUserProfileSyncMachine { } -ModuleName "xSharePoint.UserProfileService"
                Set-TargetResource @testParams 

                Assert-MockCalled Stop-SPServiceInstance
            }
        }

        Context "User profile sync service is not running and shouldn't be" {
            Mock Get-SPServiceInstance { return @( @{ 
                        Status = "Disabled"
                        ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        UserProfileApplicationGuid = [Guid]::Empty
                        TypeName = "User Profile Synchronization Service" 
                    })
            } 

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}