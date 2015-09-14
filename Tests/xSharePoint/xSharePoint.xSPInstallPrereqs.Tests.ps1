[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPInstallPrereqs"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")
    
Describe "xSPInstallPrereqs" {
    InModuleScope $ModuleName {
        $testParams = @{
            InstallerPath = "C:\SPInstall"
            OnlineMode = $true
            Ensure = "Present"
        }

        Context "Validate get method" {
            It "Checks windows features as well as installed products" {
                Mock Get-xSharePointAssemblyVersion { return 16 } -Verifiable
                Mock Invoke-Command { return $null } -Verifiable -ParameterFilter { $ScriptBlock.ToString().Contains("Get-WindowsFeature") -eq $true }
                Mock Get-CimInstance { return @{} } -Verifiable

                Get-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Passes when all Prereqs are installed" {
                Mock -ModuleName $ModuleName Get-TargetResource {
                    return @{ 
                        InstallerPath = "C:\SPInstall"
                        OnlineMode = $true
                        Ensure = "Present" 
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when there are Prereqs missing" {
                Mock -ModuleName $ModuleName Get-TargetResource {
                    return @{ 
                        InstallerPath = "C:\SPInstall"
                        OnlineMode = $true
                        Ensure = "Absent" 
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
            $testParams.Ensure = "Absent"
            It "Throws an error if SharePoint prereqs should be absent" {
                { Test-TargetResource @testParams } | Should Throw
            }
            $testParams.Ensure = "Present"
        }

        Context "Validate set method" {
            It "Runs the installer and exists after success" {
                Mock Get-xSharePointAssemblyVersion { return 15 }
                Mock Start-Process { return @{ ExitCode = 0 } } -Verifiable
                Set-TargetResource @testParams
                Assert-VerifiableMocks
            }

            It "Detects errors in the installer" {
                Mock Get-xSharePointAssemblyVersion { return 15 }
                Mock Start-Process { return @{ ExitCode = 1 } }
                { Set-TargetResource @testParams } | Should throw "already running"
                
                Mock Start-Process { return @{ ExitCode = 2 } }
                { Set-TargetResource @testParams } | Should throw "Invalid command line parameters"

                Mock Start-Process { return @{ ExitCode = -1 } }
                { Set-TargetResource @testParams } | Should throw "unknown exit code"
            }

            It "Detects reboot conditions in the installer" {
                Mock Get-xSharePointAssemblyVersion { return 15 }

                $global:DSCMachineStatus = 0
                Mock Start-Process { return @{ ExitCode = 1001 } }
                Set-TargetResource @testParams
                $global:DSCMachineStatus | Should Be 1
                
                $global:DSCMachineStatus = 0
                Mock Start-Process { return @{ ExitCode = 3010 } }
                Set-TargetResource @testParams
                $global:DSCMachineStatus | Should Be 1
            }

            $testParams.OnlineMode = $false
            It "Throws an error if offline mode is run without prerequisite location parameters" {
                Mock Get-xSharePointAssemblyVersion { return 15 }

                { Set-TargetResource @testParams } | Should throw "offline mode"
            }

            $testParams.Ensure = "Absent"
            It "Throws an error if SharePoint prereqs should be absent" {
                { Set-TargetResource @testParams } | Should Throw
            }
            $testParams.Ensure = "Present"
        }
    }    
}