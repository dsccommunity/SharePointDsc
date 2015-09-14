[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPBCSServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPBCSServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test App"
            ApplicationPool = "Test App Pool"
            DatabaseName = "Test_DB"
            DatabaseServer = "TestServer\Instance"
        }

        Context "Validate get method" {
            It "Calls the service application picker with the appropriate type name" {
                Mock Get-xSharePointServiceApplication { return @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                } } -Verifiable -ParameterFilter {$Name -eq $testParams.Name -and $TypeName -eq "BCS"}
                
                $results = Get-TargetResource @testParams
                $results | Should Not BeNullOrEmpty

                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when no service app exists" {
                Mock Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the service app exists" {
                Mock Get-TargetResource { 
                    return @{ 
                        Name = $testParams.Name 
                        ApplicationPool = $testParams.ApplicationPool
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the service app exists but has the wrong app pool" {
                Mock Get-TargetResource { 
                    return @{ 
                        Name = $testParams.Name 
                        ApplicationPool = "Wrong app pool"
                    } 
                }
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Creates a new service application" {
                Mock Get-TargetResource { return @{} }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPBusinessDataCatalogServiceApplication" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            It "Updates an existing service application" {
                Mock Get-TargetResource { return @{ Name = $testParams.Name; ApplicationPool = "Wrong app pool" } }
                Mock Get-xSharePointServiceApplication { return @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                } } -Verifiable -ParameterFilter {$Name -eq $testParams.Name -and $TypeName -eq "BCS"}
                Mock Invoke-xSharePointSPCmdlet { return @{ Name = $testParams.ApplicationPool } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplicationPool" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Set-SPBusinessDataCatalogServiceApplication" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }
}
