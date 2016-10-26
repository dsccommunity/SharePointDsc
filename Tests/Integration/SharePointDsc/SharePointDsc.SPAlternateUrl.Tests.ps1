[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingComputerNameHardcoded", "")]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\SharePointDsc.psd1")

Describe -Tags @("PostWebApp") "SPAlternateUrl - Integration Tests" {
    Context -Name "Creates a new alternate URL" {
        It "Is able to create a service app" {
            $configName = "SPAlternateUrl_CreateNewUrl"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPAlternateUrl CreateAlternateUrl {
                        WebAppUrl            = "http://$($env:COMPUTERNAME)"
                        Url                  = "http://testurl.contoso.com"
                        Zone                 = "Internet"
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

    Context -Name "Updates existing alternate URLs" {
        It "Is able to update an existing alternate URL" {
            $configName = "SPAlternateUrl_UpdateUrl"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPAlternateUrl UpdateAlternateUrl {
                        WebAppUrl            = "http://$($env:COMPUTERNAME)"
                        Url                  = "http://anotherurl.contoso.com"
                        Zone                 = "Internet"
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

    Context -Name "Delete existing alternate URLs" {
        It "Is able to delete an existing alternate URL" {
            $configName = "SPAlternateUrl_DeleteUrl"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPAlternateUrl RemoveAlternateUrl {
                        WebAppUrl            = "http://$($env:COMPUTERNAME)"
                        Url                  = "http://anotherurl.contoso.com"
                        Zone                 = "Internet"
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

    AfterEach {
        Remove-DscConfigurationDocument -Stage Current, Pending, Previous -Force -Confirm:$false
    }
}
