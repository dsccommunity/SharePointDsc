[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingComputerNameHardcoded", "")]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\SharePointDsc.psd1")

Describe -Tags @("Farm") "SPCreateFarm - Integration Tests" {
    Context -Name "Creates new farms where no farm exists" {
        It "Is able to create a new farm on the local server" {
            $configName = "SPCreateFarm_CreateNewFarm"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPCreateFarm CreateLocalFarm {
                        FarmConfigDatabaseName = "SP_Config"
                        AdminContentDatabaseName = "SP_AdminContent"
                        DatabaseServer = $env:COMPUTERNAME
                        FarmAccount = $Global:SPDscIntegrationCredPool.Farm
                        Passphrase = $Global:SPDscFarmPassphrase
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
