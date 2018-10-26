[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingComputerNameHardcoded", "")]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\SharePointDsc.psd1")

Describe -Tags @("Site") "SPSite - Integration Tests" {
    Context -Name "Creates new new site collections" {
        It "Is able to create a new path based site collection" {
            $configName = "SPSite_CreateNewPathBasedSite"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPSite PathSite {
                        Name = "Path based site"
                        Url = "http://$($env:COMPUTERNAME)"
                        OwnerAlias = $Global:SPDscIntegrationCredPool.Setup.UserName
                        PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                    }
                }
            }
            . $configName -ConfigurationData $global:SPDscIntegrationConfigData -OutputPath "TestDrive:\$configName"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\$configName" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\$configName\localhost.mof").InDesiredState | Should be $true   
        }
        
        It "Is able to create a new host name site collection" {
            $configName = "SPSite_CreateNewHostNameSite"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPSite PathSite {
                        Name = "Path based site"
                        Url = "http://sharepointdsc.test.lab"
                        HostHeaderWebApplication = "http://$($env:COMPUTERNAME)"
                        OwnerAlias = $Global:SPDscIntegrationCredPool.Setup.UserName
                        PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                    }
                }
            }
            . $configName -ConfigurationData $global:SPDscIntegrationConfigData -OutputPath "TestDrive:\$configName"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\$configName" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\$configName\localhost.mof").InDesiredState | Should be $true      
        }
    }
    
    AfterEach {
        Remove-DscConfigurationDocument -Stage Current, Pending, Previous -Force -Confirm:$false
    }
}
