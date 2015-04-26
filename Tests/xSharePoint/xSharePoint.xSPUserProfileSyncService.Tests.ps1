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
            UserProfileServiceAppName = "Managed Metadata Service App"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            FarmAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
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
    }    
}