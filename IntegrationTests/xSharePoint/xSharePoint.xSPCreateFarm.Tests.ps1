[CmdletBinding()]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\xSharePoint.psd1")

Describe -Tags @("Farm") "xSPCreateFarm - Integration Tests" {
    Context "Creates new farms where no farm exists" {
        It "Is able to create a new farm on the local server" {
            Configuration xSPFarmCreateFarm {
                Import-DscResource -ModuleName xSharePoint
                node "localhost" {
                    xSPCreateFarm CreateLocalFarm {
                        FarmConfigDatabaseName = "SP_Config"
                        AdminContentDatabaseName = "SP_AdminContent"
                        DatabaseServer = $env:COMPUTERNAME
                        FarmAccount = $Global:xSPIntegrationCredPool.Farm
                        Passphrase = $Global:xSPFarmPassphrase
                        PsDscRunAsCredential = $Global:xSPIntegrationCredPool.Setup
                    }
                }
            }
            xSPFarmCreateFarm -ConfigurationData $global:xSPIntegrationConfigData -OutputPath "TestDrive:\xSPFarmCreateFarm"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\xSPFarmCreateFarm" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\xSPFarmCreateFarm\localhost.mof").InDesiredState | Should be $true    
        }
    }
    
    AfterEach {
        Remove-DscConfigurationDocument -Stage Current, Pending, Previous -Force -Confirm:$false
    }
}