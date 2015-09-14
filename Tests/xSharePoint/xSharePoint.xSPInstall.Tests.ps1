[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPInstall"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPInstall" {
    InModuleScope $ModuleName {
        $testParams = @{
            BinaryDir = "C:\SPInstall"
            ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
        }

        Context "Validate get method" {

            It "Returns false when SharePoint is not detected" {
                Mock Get-CimInstance { return $null } -Verifiable
                $result = Get-TargetResource @testParams
                $result.SharePointInstalled | Should Be $false
                Assert-VerifiableMocks
            }

            It "Returns true when SharePoint is detected" {
                Mock Get-CimInstance { return @{} } -Verifiable
                $result = Get-TargetResource @testParams
                $result.SharePointInstalled | Should Be $true
                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Passes when SharePoint is installed" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        SharePointInstalled = $true
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when SharePoint is not installed" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        SharePointInstalled = $false
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Reboots the server after a successful install" {
                Mock Start-Process { @{ ExitCode = 0 }} -Verifiable

                Set-TargetResource @testParams

                $global:DSCMachineStatus | Should Be 1

                Assert-VerifiableMocks
            }
            It "Throws an error on unknown exit code" {
                Mock Start-Process { @{ ExitCode = -1 }} -Verifiable

                { Set-TargetResource @testParams } | Should Throw

                Assert-VerifiableMocks
            }
        }
    }    
}