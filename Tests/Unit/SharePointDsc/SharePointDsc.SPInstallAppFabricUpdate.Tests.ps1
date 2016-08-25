[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPInstallAppFabricUpdate"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPInstallAppFabricUpdate - AppFabric Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Build = '1.0.4657.2'
            BinaryDir = "C:\SPAppFabricUpdate"
            CuExeName = 'AppFabric-KB3092423-x64-ENU.exe'
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Context "AppFabric Cumulative Update are not installed but should be" {
            Mock Test-Path { return $false }
            Mock Get-ItemProperty { return @{
                VersionInfo = [pscustomobject]@{
                    ProductVersion = '1.0.4639.0'
                    }
                }
            } 

            It "returns false from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "AppFabric Cumulative Update are installed and should be" {
            Mock Test-Path { return $true }
            Mock Get-ItemProperty { return @{
                VersionInfo = [pscustomobject]@{
                    ProductVersion = $testParams.Build
                    }
                }
            } 
            
            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "AppFabric Cumulative Update installation executes as expected" {
            Mock Test-Path { return $true }
            Mock Get-ItemProperty { return @{
                VersionInfo = [pscustomobject]@{
                    ProductVersion = '1.0.4639.0'
                    }
                }
            } 
            Mock Start-Process { @{ ExitCode = 0 }}
            Mock Get-ItemProperty { return @{
                VersionInfo = [pscustomobject]@{
                    ProductVersion = $testParams.Build
                    }
                }
            }
            Set-TargetResource @testParams
            $getResults = Get-TargetResource @testParams

            It "AppFabric Cumulative Update installation Successfully" {
                $getResults.Build | Should Be $testParams.Build
            }
        }

        Context "AppFabric Cumulative Update installation fails" {
            Mock Test-Path { return $true }
            Mock Get-ItemProperty { return @{
                VersionInfo = [pscustomobject]@{
                    ProductVersion = '1.0.4639.0'
                    }
                }
            }
            Mock Start-Process { @{ ExitCode = -1 }}

            It "throws an exception on an unknown exit code" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
    }    
}
