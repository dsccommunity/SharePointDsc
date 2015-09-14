[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPManagedPath"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPManagedPath" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://sites.sharepoint.com"
            RelativeUrl = "teams"
            Explicit = $false
            HostHeader = $false
        }

        Context "Validate get method" {
            It "Calls the data from SharePoint" {
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPManagedPath" }
                Get-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when path is not found" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the path is found and is the correct type" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        RelativeUrl = $testParams.RelativeUrl
                        Explicit = $testParams.Explicit
                        HostHeader = $testParams.HostHeader
                        WebAppUrl = $testParams.WebAppUrl
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the path is found and is not the correct type" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        RelativeUrl = $testParams.RelativeUrl
                        Explicit = (-not $testParams.Explicit)
                        HostHeader = $testParams.HostHeader
                        WebAppUrl = $testParams.WebAppUrl
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Creates a new web application managed path" {
                Mock Get-TargetResource { return $null } -Verifiable
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPManagedPath" -and $Arguments.WebApplication -eq $testParams.WebAppUrl }
                Set-TargetResource @testParams
                Assert-VerifiableMocks
            }
            
            $testParams.HostHeader = $true

            It "Creates a new host header managed path" {
                Mock Get-TargetResource { return $null } -Verifiable
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPManagedPath" -and $Arguments.HostHeader -eq $true }
                Set-TargetResource @testParams
                Assert-VerifiableMocks
            }
        }
    }    
}