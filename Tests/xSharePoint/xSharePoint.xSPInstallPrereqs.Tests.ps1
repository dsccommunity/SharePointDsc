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
        }

        Context "Validate test method" {
            It "Passes when all Prereqs are installed" {
                Mock -ModuleName $ModuleName Get-TargetResource {
                    $returnValue = @{}
                    foreach($feature in "Net-Framework-Features,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Application-Server,AS-Web-Support,AS-TCP-Port-Sharing,AS-WAS-Support, AS-HTTP-Activation,AS-TCP-Activation,AS-Named-Pipes,AS-Net-Framework,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Server-Media-Foundation,Xps-Viewer".Split(",")) {
                        $returnValue.Add($feature, $true)
                    }
                    $returnValue.Add("Microsoft SQL Server 2008 R2 Native Client", $true)
                    $returnValue.Add("Microsoft Sync Framework Runtime v1.0 SP1 (x64)", $true)
                    $returnValue.Add("AppFabric 1.1 for Windows Server", $true)
                    $returnValue.Add("Microsoft Identity Extensions", $true)
                    $returnValue.Add("Active Directory Rights Management Services Client 2.0", $true)
                    $returnValue.Add("WCF Data Services 5.0 (for OData v3) Primary Components", $true)
                    $returnValue.Add("WCF Data Services 5.6.0 Runtime", $true)
                    $returnValue.Add("Microsoft CCR and DSS Runtime 2008 R3", $true)
                    return $returnValue
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when there are Windows Features missing" {
                Mock -ModuleName $ModuleName Get-TargetResource {
                    $returnValue = @{}
                    foreach($feature in "Net-Framework-Features,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Application-Server,AS-Web-Support,AS-TCP-Port-Sharing,AS-WAS-Support, AS-HTTP-Activation,AS-TCP-Activation,AS-Named-Pipes,AS-Net-Framework,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Server-Media-Foundation,Xps-Viewer".Split(",")) {
                        $returnValue.Add($feature, $false)
                    }
                    $returnValue.Add("Microsoft SQL Server 2008 R2 Native Client", $true)
                    $returnValue.Add("Microsoft Sync Framework Runtime v1.0 SP1 (x64)", $true)
                    $returnValue.Add("AppFabric 1.1 for Windows Server", $true)
                    $returnValue.Add("Microsoft Identity Extensions", $true)
                    $returnValue.Add("Active Directory Rights Management Services Client 2.0", $true)
                    $returnValue.Add("WCF Data Services 5.0 (for OData v3) Primary Components", $true)
                    $returnValue.Add("WCF Data Services 5.6.0 Runtime", $true)
                    $returnValue.Add("Microsoft CCR and DSS Runtime 2008 R3", $true)
                    return $returnValue
                } 
                Test-TargetResource @testParams | Should Be $false
            }
            It "Fails when there are software prereqs missing" {
                Mock -ModuleName $ModuleName Get-TargetResource {
                    $returnValue = @{}
                    foreach($feature in "Net-Framework-Features,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Application-Server,AS-Web-Support,AS-TCP-Port-Sharing,AS-WAS-Support, AS-HTTP-Activation,AS-TCP-Activation,AS-Named-Pipes,AS-Net-Framework,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Server-Media-Foundation,Xps-Viewer".Split(",")) {
                        $returnValue.Add($feature, $false)
                    }
                    $returnValue.Add("Microsoft SQL Server 2008 R2 Native Client", $false)
                    $returnValue.Add("Microsoft Sync Framework Runtime v1.0 SP1 (x64)", $false)
                    $returnValue.Add("AppFabric 1.1 for Windows Server", $false)
                    $returnValue.Add("Microsoft Identity Extensions", $false)
                    $returnValue.Add("Active Directory Rights Management Services Client 2.0", $false)
                    $returnValue.Add("WCF Data Services 5.0 (for OData v3) Primary Components", $false)
                    $returnValue.Add("WCF Data Services 5.6.0 Runtime", $false)
                    $returnValue.Add("Microsoft CCR and DSS Runtime 2008 R3", $false)
                    return $returnValue
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }    
}