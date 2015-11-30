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

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }

        if ($null -eq (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)) {
            function Get-WindowsFeature() { }
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))

        Mock Get-xSharePointAssemblyVersion { return $majorBuildNumber } 
        Mock Get-ChildItem { return $null }

        Context "Prerequisites are not installed but should be and are to be installed in online mode" {
            $testParams = @{
                InstallerPath = "C:\SPInstall"
                OnlineMode = $true
                Ensure = "Present"
            }

            Mock Get-WindowsFeature { @( @{ Name = "ExampleFeature"; Installed = $false}) }
            Mock Get-CimInstance { return @() }
            Mock Get-ChildItem { return @() }

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
            $testParams = @{
                InstallerPath = "C:\SPInstall"
                OnlineMode = $true
                Ensure = "Present"
            }
            
            Mock Get-WindowsFeature { @( @{ Name = "ExampleFeature"; Installed = $true }) }
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
            Mock Get-ChildItem { return @(
                (New-Object Object | 
                    Add-Member ScriptMethod GetValue { return "Microsoft Identity Extensions" } -PassThru)
            ) }
            
            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Prerequisites are installed but should not be" {
            $testParams = @{
                InstallerPath = "C:\SPInstall"
                OnlineMode = $true
                Ensure = "Absent"
            }

            It "throws an exception from the set method" {
                {Test-TargetResource @testParams} | Should Throw
            }

            It "throws an exception from the set method" {
                {Set-TargetResource @testParams} | Should Throw
            }
        }

        Context "Prerequisites are not installed but should be and are to be installed in offline mode" {
            $testParams = @{
                InstallerPath = "C:\SPInstall"
                OnlineMode = $false
                Ensure = "Present"
            }

            Mock Get-WindowsFeature { @( @{ Name = "ExampleFeature"; Installed = $false}) }
            Mock Get-CimInstance { return @() }
            Mock Get-ChildItem { return @() }

            It "throws an exception in the set method if required parameters are not set" {
                {Set-TargetResource @testParams} | Should Throw
            }

            if ($majorBuildNumber -eq 15) {
                $requiredParams = @("SQLNCli","PowerShell","NETFX","IDFX","Sync","AppFabric","IDFX11","MSIPCClient","WCFDataServices","KB2671763","WCFDataServices56")
            }
            if ($majorBuildNumber -eq 16) {
                $requiredParams = @("SQLNCli","Sync","AppFabric","IDFX11","MSIPCClient","WCFDataServices","KB2671763","WCFDataServices56","KB2898850","MSVCRT12","ODBC","DotNet452")
            }
            $requiredParams | ForEach-Object {
                $testParams.Add($_, "C:\fake\value.exe")
            }

            It "does not throw an exception where the required parameters are included" {
                Mock Start-Process { return @{ ExitCode = 0 } }
                Mock Test-Path { return $true }

                {Set-TargetResource @testParams} | Should Not Throw
            }
        }

        Context "Prerequisites are not installed but should be and are to be installed in offline mode, but invalid paths have been passed" {
            $testParams = @{
                InstallerPath = "C:\SPInstall"
                OnlineMode = $false
                Ensure = "Present"
            }

            Mock Get-WindowsFeature { @( @{ Name = "ExampleFeature"; Installed = $false }) }
            Mock Get-CimInstance { return @() }
            Mock Get-ChildItem { return @() }

            It "throws an exception in the set method if required parameters are not set" {
                {Set-TargetResource @testParams} | Should Throw
            }

            if ($majorBuildNumber -eq 15) {
                $requiredParams = @("SQLNCli","PowerShell","NETFX","IDFX","Sync","AppFabric","IDFX11","MSIPCClient","WCFDataServices","KB2671763","WCFDataServices56")
            }
            if ($majorBuildNumber -eq 16) {
                $requiredParams = @("SQLNCli","Sync","AppFabric","IDFX11","MSIPCClient","WCFDataServices","KB2671763","WCFDataServices56","KB2898850","MSVCRT12")
            }
            $requiredParams | ForEach-Object {
                $testParams.Add($_, "C:\fake\value.exe")
            }

            It "does not throw an exception where the required parameters are included" {
                Mock Start-Process { return @{ ExitCode = 0 } }
                Mock Test-Path { return $false }

                {Set-TargetResource @testParams} | Should Throw
            }
        }
    }    
}