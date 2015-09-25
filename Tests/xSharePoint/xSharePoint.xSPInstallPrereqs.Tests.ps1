[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPInstallPrereqs"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")
    
Describe "xSPInstallPrereqs" {
    InModuleScope $ModuleName {
        $testParams = @{
            InstallerPath = "C:\SPInstall"
            OnlineMode = $true
            Ensure = "Present"
        }

        Mock Initialize-xSharePointPSSnapin { } -ModuleName "xSharePoint.Util"
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))

        Mock Get-xSharePointAssemblyVersion { return $majorBuildNumber } 
        Mock Check-xSharePointInstalledProductRegistryKey { return $null }

        Context "Prerequisites are not installed but should be" {
            Mock Invoke-Command { @( @{ Name = "ExampleFeature"; Installed = $false}) } -ParameterFilter { $ScriptBlock.ToString().Contains("Get-WindowsFeature") -eq $true }
            Mock Get-CimInstance { return @() }
            Mock Get-ChildItem { return $null }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Calls the prerequisite installer from the set method and records the need for a reboot" {
                Mock Start-Process { return @{ ExitCode = 3010 } }

                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Calls the prerequisite installer from the set method and a pending reboot is preventing it from running" {
                Mock Start-Process { return @{ ExitCode = 1001 } }

                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Calls the prerequisite installer from the set method and passes a successful installation" {
                Mock Start-Process { return @{ ExitCode = 0 } }

                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Calls the prerequisite installer from the set method when the prerequisite installer is already running" {
                Mock Start-Process { return @{ ExitCode = 1 } }

                { Set-TargetResource @testParams } | Should Throw "already running"
            }

            It "Calls the prerequisite installer from the set method and invalid arguments are passed to the installer" {
                Mock Start-Process { return @{ ExitCode = 2 } }

                { Set-TargetResource @testParams } | Should Throw "Invalid command line parameters"
            }

            It "Calls the prerequisite installer from the set method and throws for unknown error codes" {
                Mock Start-Process { return @{ ExitCode = -1 } }

                { Set-TargetResource @testParams } | Should Throw "unknown exit code"
            }
        }

        Context "Prerequisites are installed and should be" {
            Mock Invoke-Command { return @( @{ Name = "ExampleFeature"; Installed = $true }) } -ParameterFilter { $ScriptBlock.ToString().Contains("Get-WindowsFeature") -eq $true }
            if ($majorBuildNumber -eq 15) {
                Mock Get-CimInstance { return @(
                    @{ Name = "Microsoft CCR and DSS Runtime 2008 R3"}
                    @{ Name = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"}
                    @{ Name = "AppFabric 1.1 for Windows Server"}
                    @{ Name = "WCF Data Services 5.6.0 Runtime"}
                    @{ Name = "WCF Data Services 5.0 (for OData v3) Primary Components"}
                    @{ Name = "Microsoft SQL Server 2008 R2 Native Client"}
                    @{ Name = "Active Directory Rights Management Services Client 2.0"}
                )}
            }
            if ($majorBuildNumber -eq 16) {
                Mock Get-CimInstance { return @(
                    @{ Name = "Microsoft CCR and DSS Runtime 2008 R3"}
                    @{ Name = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"}
                    @{ Name = "AppFabric 1.1 for Windows Server"}
                    @{ Name = "WCF Data Services 5.6.0 Runtime"}
                    @{ Name = "Microsoft ODBC Driver 11 for SQL Server"}
                    @{ Name = "Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.21005"}
                    @{ Name = "Microsoft Visual C++ 2013 x64 Additional Runtime - 12.0.21005"}
                    @{ Name = "Microsoft SQL Server 2012 Native Client"}
                    @{ Name = "Active Directory Rights Management Services Client 2.1"}
                )}
            }
            Mock Get-ChildItem { return $null }
            Mock Check-xSharePointInstalledProductRegistryKey { return @( @{Example = $true } ) }
            
            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Prerequisites are installed but should not be" {
            $testParams.Ensure = "Absent"

            It "throws an exception from the set method" {
                {Set-TargetResource @testParams} | Should Throw
            }
        }
    }    
}