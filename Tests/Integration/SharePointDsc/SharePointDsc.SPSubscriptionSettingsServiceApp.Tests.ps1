[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingComputerNameHardcoded", "")]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\SharePointDsc.psd1")

Describe -Tags @("PreServiceApp") "SPSubscriptionSettingsServiceApp - Integration Tests" {
    Context -Name "Creates a new app management service application" {
        It "Is able to create a service app" {
            $configName = "SPSubscriptionSettingsServiceApp_CreateNewApp"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPSubscriptionSettingsServiceApp CreateApp {
                        Name                 = "Subscription Settings Service Application"
                        DatabaseServer       = $env:COMPUTERNAME
                        ApplicationPool      = "SharePoint Service Applications"
                        Ensure               = "Present"
                        PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                    }
                }
            }
            . $configName -ConfigurationData $global:SPDscIntegrationConfigData -OutputPath "TestDrive:\$configName"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\$configName" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\$configName\localhost.mof").InDesiredState | Should be $true    
        }
    }

    Context -Name "Removes an existing App management service application" {
        It "Is able to remove a service app" {
            $configName = "SPSubscriptionSettingsServiceApp_RemoveApp"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPSubscriptionSettingsServiceApp RemoveApp {
                        Name                 = "Subscription Settings Service Application"
                        DatabaseServer       = $env:COMPUTERNAME
                        ApplicationPool      = "SharePoint Service Applications"
                        Ensure               = "Absent"
                        PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                    }
                }
            }
            . $configName -ConfigurationData $global:SPDscIntegrationConfigData -OutputPath "TestDrive:\$configName"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\$configName" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\$configName\localhost.mof").InDesiredState | Should be $true    
        }
    }

    Context -Name "Creates a new app management service application" {
        It "Is able to create a service app to persist for other service apps" {
            $configName = "SPSubscriptionSettingsServiceApp_CreateNewApp2"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPSubscriptionSettingsServiceApp CreateApp {
                        Name                 = "Subscription Settings Service Application"
                        DatabaseServer       = $env:COMPUTERNAME
                        ApplicationPool      = "SharePoint Service Applications"
                        Ensure               = "Present"
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
