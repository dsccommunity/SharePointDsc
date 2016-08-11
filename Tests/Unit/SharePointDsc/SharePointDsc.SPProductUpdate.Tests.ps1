[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPProductUpdate"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPProductUpdate - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
            ShutdownServices     = $true
            BinaryInstallDays    = "sat", "sun"
            BinaryInstallTime    = "12:00am to 2:00am"
            Ensure               = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))
        Mock Get-SPDSCAssemblyVersion { return $majorBuildNumber }
                
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }

        try { [Microsoft.SharePoint.Administration.SPProductVersions] }
        catch {
            Add-Type -TypeDefinition "namespace Microsoft.SharePoint.Administration
                {
                    public class SPProductVersions {
                        private static SPProductVersions instance;
                        private SPProductVersions() {}
                        public static SPProductVersions GetProductVersions(SPFarm farm) {
                            get 
                            {
                                if (instance == null)
                                {
                                    instance = new Singleton();
                                }
                                return instance;
                            }
                        }
                        public SPServerProductInfo GetServerProductInfo(System.Guid serverId) {
                            return ??
                        }          
                    }
                }"
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Context "Specified update file not found" {
            Mock Test-Path { return $false }

            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }
        }

        Context "Ensure is set to Absent" {
            Mock Test-Path { return $false }

            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }
        }

        Context "Update CU has lower version, update not required" {
            Mock Test-Path { return $true }
            Mock Get-ItemProperty { return @{
                    VersionInfo = @{
                        FileVersion = $versionBeingTested
                        FileDescription = "Cumulative Update"
                    }
                    Name = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                } 
            }
            Mock Get-SPFarm { return "" }
            Mock Get-SPServer { return @{ id = "12345" } }

            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }
        }


#
# Update CU has higher version, update required
# Update SP has lower version, update not required
# Update SP has higher version, update required
# Update SP LP has lower version, update not required
# Update SP LP has higher version, update required
# Update SP LP does not have language in the name - Exception
# Update SP LP has unknown language in the name - Exception
# Update SP LP specified language is not installed - Exception
# BinaryInstallDays outside range
# BinaryInstallTime outside range
# BinaryInstallTime incorrectly formatted - Exception
# BinaryInstallTime start time larger than end time - Exception
# Upgrade pending - Skipping install
# Stop services
# Successful install
# Successful install with reboot
# Unsuccessful install

<#
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
        }#>
    }    
}
