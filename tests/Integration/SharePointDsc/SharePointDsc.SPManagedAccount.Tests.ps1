[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingComputerNameHardcoded", "")]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\SharePointDsc.psd1")

Describe -Tags @("PostFarm") "SPManagedAccount - Integration Tests" {
    Context -Name "Creates new new managed accounts" {
        It "Is able to create a new managed account" {
            $configName = "SPManagedAccounts_CreateNewManagedAccounts"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPManagedAccount WebAppPoolAccount {
                        AccountName = $Global:SPDscIntegrationCredPool.WebApp.UserName
                        Account = $Global:SPDscIntegrationCredPool.WebApp
                        PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                    }
                    SPManagedAccount ServiceAppPoolAccount {
                        AccountName = $Global:SPDscIntegrationCredPool.ServiceApp.UserName
                        Account = $Global:SPDscIntegrationCredPool.ServiceApp
                        PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                    }
                }
            }
            . $configName -ConfigurationData $global:SPDscIntegrationConfigData -OutputPath "TestDrive:\$configName"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\$configName" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\$configName\localhost.mof").InDesiredState | Should be $true        
        }
    }
    
    Context -Name "Updates managed accounts" {
        It "is able to set a schedule" {
            $configName = "SPManagedAccounts_SetSchedules"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPManagedAccount WebAppPoolAccount {
                        AccountName = $Global:SPDscIntegrationCredPool.WebApp.UserName
                        Account = $Global:SPDscIntegrationCredPool.WebApp
                        Schedule = "monthly between 7 02:00:00 and 7 03:00:00"
                        EmailNotification = 7
                        PreExpireDays = 2
                        PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                    }
                }
            }
            . $configName -ConfigurationData $global:SPDscIntegrationConfigData -OutputPath "TestDrive:\$configName"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\$configName" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\$configName\localhost.mof").InDesiredState | Should be $true     
        }
        
        It "is able to remove a schedule" {
            $configName = "SPManagedAccounts_RemoveSchedules"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPManagedAccount WebAppPoolAccount {
                        AccountName = $Global:SPDscIntegrationCredPool.WebApp.UserName
                        Account = $Global:SPDscIntegrationCredPool.WebApp
                        Schedule = $null
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
