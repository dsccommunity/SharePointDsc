[CmdletBinding()]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\xSharePoint.psd1")

Describe -Tags @("PostFarm") "xSPManagedAccount - Integration Tests" {
    Context "Creates new new managed accounts" {
        It "Is able to create a new managed account" {
            Configuration xSPCreateManagedAccounts {
                Import-DscResource -ModuleName xSharePoint
                node "localhost" {
                    xSPManagedAccount WebAppPoolAccount {
                        AccountName = $Global:xSPIntegrationCredPool.WebApp.UserName
                        Account = $Global:xSPIntegrationCredPool.WebApp
                        PsDscRunAsCredential = $Global:xSPIntegrationCredPool.Setup
                    }
                    xSPManagedAccount ServiceAppPoolAccount {
                        AccountName = $Global:xSPIntegrationCredPool.ServiceApp.UserName
                        Account = $Global:xSPIntegrationCredPool.ServiceApp
                        PsDscRunAsCredential = $Global:xSPIntegrationCredPool.Setup
                    }
                }
            }
            xSPCreateManagedAccounts -ConfigurationData $global:xSPIntegrationConfigData -OutputPath "TestDrive:\xSPCreateManagedAccounts"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\xSPCreateManagedAccounts" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\xSPCreateManagedAccounts\localhost.mof").InDesiredState | Should be $true    
        }
    }
    
    Context "Updates managed accounts" {
        It "is able to set a schedule" {
            Configuration xSPCreateManagedAccounts {
                Import-DscResource -ModuleName xSharePoint
                node "localhost" {
                    xSPManagedAccount WebAppPoolAccount {
                        AccountName = $Global:xSPIntegrationCredPool.WebApp.UserName
                        Account = $Global:xSPIntegrationCredPool.WebApp
                        Schedule = "monthly between 7 02:00:00 and 7 03:00:00"
                        EmailNotification = 7
                        PreExpireDays = 2
                        PsDscRunAsCredential = $Global:xSPIntegrationCredPool.Setup
                    }
                }
            }
            xSPCreateManagedAccounts -ConfigurationData $global:xSPIntegrationConfigData -OutputPath "TestDrive:\xSPCreateManagedAccounts"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\xSPCreateManagedAccounts" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\xSPCreateManagedAccounts\localhost.mof").InDesiredState | Should be $true    
        }
        
        It "is able to remove a schedule" {
            Configuration xSPCreateManagedAccounts {
                Import-DscResource -ModuleName xSharePoint
                node "localhost" {
                    xSPManagedAccount WebAppPoolAccount {
                        AccountName = $Global:xSPIntegrationCredPool.WebApp.UserName
                        Account = $Global:xSPIntegrationCredPool.WebApp
                        Schedule = $null
                        PsDscRunAsCredential = $Global:xSPIntegrationCredPool.Setup
                    }
                }
            }
            xSPCreateManagedAccounts -ConfigurationData $global:xSPIntegrationConfigData -OutputPath "TestDrive:\xSPCreateManagedAccounts"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\xSPCreateManagedAccounts" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\xSPCreateManagedAccounts\localhost.mof").InDesiredState | Should be $true    
        }
    }
    
    AfterEach {
        Remove-DscConfigurationDocument -Stage Current, Pending, Previous -Force -Confirm:$false
    }
}
