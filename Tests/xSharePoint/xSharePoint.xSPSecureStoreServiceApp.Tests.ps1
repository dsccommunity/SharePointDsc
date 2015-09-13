[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPSecureStoreServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSecureStoreServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Secure Store Service Application"
            ApplicationPool = "SharePoint Search Services"
            AuditingEnabled = $false
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
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPSecureStoreServiceApplication" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPSecureStoreServiceApplicationProxy" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            It "Updates an existing service app" {
                Mock Get-TargetResource { return @{ ApplicationPool = "Invalid"} } -Verifiable
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplication" -and $Arguments.Name -eq $testParams.Name } -ModuleName "xSharePoint.ServiceApplications"
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Set-SPSecureStoreServiceApplication" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplicationPool" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}