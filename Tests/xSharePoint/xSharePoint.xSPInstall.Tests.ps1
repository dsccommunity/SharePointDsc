[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPInstall"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPInstall" {
    InModuleScope $ModuleName {
        $testParams = @{
            BinaryDir = "C:\SPInstall"
            ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))
        Mock Get-xSharePointAssemblyVersion { return $majorBuildNumber }
        
        Mock Get-ChildItem {
            return @(
                @{
                    Version = "4.5.0.0"
                    Release = "0"
                    PSChildName = "Full"
                },
                @{
                    Version = "4.5.0.0"
                    Release = "0"
                    PSChildName = "Client"
                }
            )
        }
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Context "SharePoint binaries are not installed but should be" {
            Mock Get-CimInstance { return $null }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "SharePoint binaries are installed and should be" {
            Mock Get-CimInstance { return @{} } 

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "SharePoint installation executes as expected" {
            Mock Start-Process { @{ ExitCode = 0 }}

            It "reboots the server after a successful installation" {
                Set-TargetResource @testParams
                $global:DSCMachineStatus | Should Be 1
            }
        }

        Context "SharePoint installation fails" {
            Mock Start-Process { @{ ExitCode = -1 }}

            It "throws an exception on an unknown exit code" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        $testParams.Ensure = "Absent"

        Context "SharePoint binaries are installed and should not be" {
            Mock Get-CimInstance { return @{} } 

            It "throws in the test method because uninstall is unsupported" {
                { Test-TargetResource @testParams } | Should Throw
            }

            It "throws in the set method because uninstall is unsupported" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
        
        Context "SharePoint 2013 is installing on a server with .NET 4.6" {
            Mock Get-ChildItem {
                return @(
                    @{
                        Version = "4.6.0.0"
                        Release = "0"
                        PSChildName = "Full"
                    },
                    @{
                        Version = "4.6.0.0"
                        Release = "0"
                        PSChildName = "Client"
                    }
                )
            }
            
            It "throws an error in the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
        
        
        $testParams = @{
            BinaryDir = "C:\SPInstall"
            ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
            Ensure = "Present"
            InstallPath = "C:\somewhere"
            DataPath = "C:\somewhere\else"
        }
        Context "SharePoint is not installed and should be, using custom install directories" {
            Mock Get-CimInstance { return $null }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
            
            Mock Start-Process { @{ ExitCode = 0 }}

            It "reboots the server after a successful installation" {
                Set-TargetResource @testParams
                $global:DSCMachineStatus | Should Be 1
            }
        }
    }    
}
