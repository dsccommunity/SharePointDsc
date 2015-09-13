[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPUserProfileServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPUserProfileServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "User Profile Service App"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
        }

        Context "Validate get method" {
            It "Retrieves the data from SharePoint" {
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplication" -and $Arguments.Name -eq $testParams.Name } -ModuleName "xSharePoint.ServiceApplications"
                Get-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when user profile service app doesn't exist" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the user profile service app exists and uses the correct app pool" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ApplicationPool = $testParams.ApplicationPool
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the user profile service app exists but uses the wrong app pool" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ApplicationPool = "wrong pool"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Creates a new service app where none exists, adding user to the local admin group" {
                Mock Test-xSharePointUserIsLocalAdmin { return $false } -Verifiable 
                Mock Add-xSharePointUserToLocalAdmin -Verifiable
                Mock Remove-xSharePointUserToLocalAdmin -Verifiable

                Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"
                
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplication" -and $Arguments.Name -eq $testParams.Name } -ModuleName "xSharePoint.ServiceApplications"
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPProfileServiceApplication" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPProfileServiceApplicationProxy" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            It "Creates a new service app where none exists, without adding user to the local admin group" {
                Mock Test-xSharePointUserIsLocalAdmin { return $true } -Verifiable 
                
                Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"

                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplication" -and $Arguments.Name -eq $testParams.Name } -ModuleName "xSharePoint.ServiceApplications"
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPProfileServiceApplication" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPProfileServiceApplicationProxy" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}