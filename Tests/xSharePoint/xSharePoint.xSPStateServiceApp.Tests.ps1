[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPStateServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPStateServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "State Service App"
        }

        Context "Validate get method" {
            It "Calls the right functions to retrieve SharePoint data" {
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPStateServiceApplication" }
                Get-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when state service app doesn't exist" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the state service app exists" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Validate set method" {
            It "Creates a new service app where none exists" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPStateServiceApplication" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPStateServiceDatabase" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPStateServiceApplication" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPStateServiceApplicationProxy" }

                Set-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }
    }    
}