[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPUserProfileSyncService"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPUserProfileSyncService" {
    InModuleScope $ModuleName {
        $testParams = @{
            UserProfileServiceAppName = "User Profile Service Service App"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
        }

        Context "Validate get method" {
            It "Retrieves the data from SharePoint" {
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceInstance" }
                Get-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when user profile sync service doesn't exist" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the user profile sync service is running and should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Status = "Online"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the user profile sync service is not running and should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Status = "Disabled"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }

            $testParams.Ensure = "Absent"

            It "Fails when the user profile sync service is running and should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Status = "Online"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the user profile sync service is not running and should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Status = "Disabled"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
        }

        $testParams.Ensure = "Present"
        $Global:xSharePointUPACheck = $false

        Context "Validate set method" {
            It "Povisions the user profile sync service where it should be running" {
                Mock Test-xSharePointUserIsLocalAdmin { return $false } -Verifiable 
                Mock Add-xSharePointUserToLocalAdmin -Verifiable
                Mock Remove-xSharePointUserToLocalAdmin -Verifiable

                Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"
                Mock Restart-Service { return $null }

                Mock Set-xSharePointUserProfileSyncMachine { return $null } -Verifiable
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Start-SPServiceInstance" }
                Mock Invoke-xSharePointSPCmdlet { if ($Global:xSharePointUPACheck -eq $false) {
                        $Global:xSharePointUPACheck = $true
                        return @( @{ Status = "Offline"; ID = [Guid]::NewGuid(); TypeName = "User Profile Synchronization Service" }) 
                    } else {
                        return @( @{ Status = "Online"; ID = [Guid]::NewGuid(); TypeName = "User Profile Synchronization Service" })
                    } 
                } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceInstance" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            $testParams.Ensure = "Absent"
            $Global:xSharePointUPACheck = $false

            It "Stops the user profile sync service where it should not be running" {
                Mock Test-xSharePointUserIsLocalAdmin { return $false } -Verifiable 
                Mock Add-xSharePointUserToLocalAdmin -Verifiable
                Mock Remove-xSharePointUserToLocalAdmin -Verifiable

                Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"
                Mock Restart-Service { return $null }

                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Stop-SPServiceInstance" }
                Mock Invoke-xSharePointSPCmdlet { if ($Global:xSharePointUPACheck -eq $false) {
                        $Global:xSharePointUPACheck = $true
                        return @( @{ Status = "Online"; ID = [Guid]::NewGuid(); TypeName = "User Profile Synchronization Service" }) 
                    } else {
                        return @( @{ Status = "Disabled"; ID = [Guid]::NewGuid(); TypeName = "User Profile Synchronization Service" })
                    } 
                } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceInstance" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}