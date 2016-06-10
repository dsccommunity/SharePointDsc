[CmdletBinding()]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\xSharePoint.psd1")

Describe -Tags @("Site") "xSPSite - Integration Tests" {
    Context "Creates new new site collections" {
        It "Is able to create a new path based site collection" {
            Configuration xSPCreateSite {
                Import-DscResource -ModuleName xSharePoint
                node "localhost" {
                    xSPSite PathSite {
                        Name = "Path based site"
                        Url = "http://$($env:COMPUTERNAME)"
                        OwnerAlias = $Global:xSPIntegrationCredPool.Setup.UserName
                        PsDscRunAsCredential = $Global:xSPIntegrationCredPool.Setup
                    }
                }
            }
            xSPCreateSite -ConfigurationData $global:xSPIntegrationConfigData -OutputPath "TestDrive:\xSPCreateSite"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\xSPCreateSite" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\xSPCreateSite\localhost.mof").InDesiredState | Should be $true    
        }
        
        It "Is able to create a new host name site collection" {
            Configuration xSPCreateSite {
                Import-DscResource -ModuleName xSharePoint
                node "localhost" {
                    xSPSite PathSite {
                        Name = "Path based site"
                        Url = "http://xsharepoint.test.lab"
                        HostHeaderWebApplication = "http://$($env:COMPUTERNAME)"
                        OwnerAlias = $Global:xSPIntegrationCredPool.Setup.UserName
                        PsDscRunAsCredential = $Global:xSPIntegrationCredPool.Setup
                    }
                }
            }
            xSPCreateSite -ConfigurationData $global:xSPIntegrationConfigData -OutputPath "TestDrive:\xSPCreateSite"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\xSPCreateSite" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\xSPCreateSite\localhost.mof").InDesiredState | Should be $true    
        }
    }
    
    AfterEach {
        Remove-DscConfigurationDocument -Stage Current, Pending, Previous -Force -Confirm:$false
    }
}