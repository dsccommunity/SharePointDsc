[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPJoinFarm"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPJoinFarm" {
    InModuleScope $ModuleName {
        $testParams = @{
            FarmConfigDatabaseName = "SP_Config"
            DatabaseServer = "DatabaseServer\Instance"
            Passphrase = "passphrase"
        }

        Context "Validate get method" {
            It "Calls SP Farm to find the local environment settings" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter {$CmdletName -eq "Get-SPFarm"}
                $results = Get-TargetResource @testParams
                $results.Count | Should Be 0
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Fails when local server is not in a farm" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when local server is in a farm" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{ 
                        FarmName = "SP_Config"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Validate set method" {
            It "Joins a new SharePoint 2016 farm" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Connect-SPConfigurationDatabase" -and $Arguments.ContainsKey("LocalServerRole") }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPHelpCollection" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Initialize-SPResourceSecurity" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPService" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPFeature" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPApplicationContent" }

                Mock Invoke-Command { return $null }

                Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 16 } }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            It "Joins a new SharePoint 2013 farm" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Connect-SPConfigurationDatabase" -and (-not $Arguments.ContainsKey("LocalServerRole")) }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPHelpCollection" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Initialize-SPResourceSecurity" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPService" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPFeature" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPApplicationContent" }

                Mock Invoke-Command { return $null }

                Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 15 } }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            It "Throws an exception for unsupported SharePoint versions" {
                Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 1 } }

                { Set-TargetResource @testParams } | Should throw
            }
        }
    }    
}