[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingComputerNameHardcoded", "")]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\SharePointDsc.psd1")

Describe -Tags @("PostSite") "SPAppCatalog - Integration Tests" {
    Context -Name "Sets the app catalog location" {
        It "Is able to create a app catalog site and set it as the app catalog for the web app" {
            $configName = "SPAppCatalog_CreateAndSetAppCatalog"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPSite AppCatalogSite {
                        Name                 = "App catalog"
                        Url                  = "http://$($env:COMPUTERNAME)/sites/appcatalog"
                        Template             = "APPCATALOG#0"
                        OwnerAlias           = $Global:SPDscIntegrationCredPool.Setup.UserName
                        PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                    }

                    SPAppCatalog AppCatalog {
                        SiteUrl              = "http://$($env:COMPUTERNAME)/sites/appcatalog"
                        PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                        DependsOn            = "[SPSite]AppCatalogSite"
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
