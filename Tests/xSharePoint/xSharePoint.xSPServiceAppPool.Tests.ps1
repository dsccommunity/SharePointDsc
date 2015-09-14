[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPServiceAppPool"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPServiceAppPool" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Service pool"
            ServiceAccount = "DEMO\svcSPServiceApps"
        }

        Context "Validate get method" {
            It "Calls the right functions to retrieve SharePoint data" {
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplicationPool" -and $Arguments.Identity -eq $testParams.Name }
                Get-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when service app pool is not found" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the pool exists and has the correct service account" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ServiceAccount = $testParams.ServiceAccount
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the service app pool is found but uses the wrong service account" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ServiceAccount = "Wrong account name"
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Creates a new service app pool when none exists" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplicationPool" -and $Arguments.Identity -eq $testParams.Name }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPServiceApplicationPool" -and $Arguments.Name -eq $testParams.Name }

                Set-TargetResource @testParams
                Assert-VerifiableMocks
            }

            It "Updates the service account of the pool when it is wrong" {
                Mock Invoke-xSharePointSPCmdlet { return @{ ProcessAccountName = "wrong name" } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplicationPool" -and $Arguments.Identity -eq $testParams.Name }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Set-SPServiceApplicationPool" }

                Set-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }
    }    
}