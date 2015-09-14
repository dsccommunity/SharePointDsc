[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPCreateFarm"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint")
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPCreateFarm" {
    InModuleScope $ModuleName {
        $testParams = @{
            FarmConfigDatabaseName = "SP_Config"
            DatabaseServer = "DatabaseServer\Instance"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Passphrase = "passphrase"
            AdminContentDatabaseName = "Admin_Content"
        }

        Context "Validate get method" {
            It "Calls SP Farm to find the local environment settings" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter {$CmdletName -eq "Get-SPFarm"}
                $results = Get-TargetResource @testParams
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
                        FarmConfigDatabaseName = "SP_Config"
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Validate set method" {
            It "Creates a new SharePoint 2016 farm" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPConfigurationDatabase" -and $Arguments.ContainsKey("LocalServerRole") }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPHelpCollection" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Initialize-SPResourceSecurity" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPService" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPFeature" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPCentralAdministration" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPApplicationContent" }

                Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 16 } }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            It "Creates a new SharePoint 2013 farm" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPConfigurationDatabase" -and (-not $Arguments.ContainsKey("LocalServerRole")) }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPHelpCollection" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Initialize-SPResourceSecurity" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPService" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPFeature" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPCentralAdministration" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPApplicationContent" }

                Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 15 } }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            It "Throws an exception for unsupported SharePoint versions" {
                Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 1 } }

                { Set-TargetResource @testParams } | Should throw
            }

            It "Uses a default port for central admin when none is provided" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPConfigurationDatabase" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPHelpCollection" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Initialize-SPResourceSecurity" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPService" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPFeature" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPCentralAdministration" -and $Arguments.Port -eq 9999 }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPApplicationContent" }

                Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 15 } }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            $testParams.Add("CentralAdministrationPort", 1234)
            It "Uses a the specified port for central admin when it is provided" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPConfigurationDatabase" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPHelpCollection" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Initialize-SPResourceSecurity" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPService" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPFeature" }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPCentralAdministration" -and $Arguments.Port -eq 1234 }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Install-SPApplicationContent" }

                Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 15 } }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}