[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPSearchServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSearchServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Search Service Application"
            ApplicationPool = "SharePoint Search Services"
        }

        Context "Validate get method" {
            It "Retrieves the data from SharePoint" {
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplication" -and $Arguments.Name -eq $testParams.Name } -ModuleName "xSharePoint.ServiceApplications"
                Get-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when service app is not found" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the path is found and is the correct type" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ApplicationPool = $testParams.ApplicationPool
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the service app is found but uses the wrong app pool" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ApplicationPool = "Wrong App Pool"
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Creates a new service app where none exists" {
                Mock Get-TargetResource { return @{} } -Verifiable
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPEnterpriseSearchServiceInstance" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Start-SPEnterpriseSearchServiceInstance" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPEnterpriseSearchServiceApplication" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPEnterpriseSearchServiceApplicationProxy" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            It "Updates an existing service app" {
                Mock Get-TargetResource { return @{ ApplicationPool = "Invalid"} } -Verifiable
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplication" -and $Arguments.Name -eq $testParams.Name } -ModuleName "xSharePoint.ServiceApplications"
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Set-SPEnterpriseSearchServiceApplication" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplicationPool" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}