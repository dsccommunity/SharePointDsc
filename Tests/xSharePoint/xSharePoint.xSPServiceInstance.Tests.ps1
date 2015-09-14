[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPServiceInstance"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPServiceInstance" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Service pool"
            Ensure = "Present"
        }

        Context "Validate get method" {
            It "Calls the right functions to retrieve SharePoint data" {
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceInstance" }
                Get-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when service instance is not found at all" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the service instance is running and it should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Ensure = "Present"
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the service instance isn't running and it should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Ensure = "Absent"
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }

            $testParams.Ensure = "Absent"

            It "Fails when the service instance is running and it should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Ensure = "Present"
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the service instance isn't running and it should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Ensure = "Absent"
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Validate set method" {

            $testParams.Ensure = "Present"

            It "Starts a service that should be running" {
                Mock Invoke-xSharePointSPCmdlet { return @( @{ TypeName = $testParams.Name } ) } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceInstance" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Start-SPServiceInstance" }

                Set-TargetResource @testParams
                Assert-VerifiableMocks
            }

            $testParams.Ensure = "Absent"

            It "Stops a service that should be stopped" {
                Mock Invoke-xSharePointSPCmdlet { return @( @{ TypeName = $testParams.Name } ) } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceInstance" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Stop-SPServiceInstance" }

                Set-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }
    }    
}