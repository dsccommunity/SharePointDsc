[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingComputerNameHardcoded", "")]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\SharePointDsc.psd1")

Describe -Tags @("WebApp") "SPWebApplication - Integration Tests" {
    Context -Name "Creates new new web applications" {
        It "Is able to create a new web application" {
            $configName = "SPWebApplication_CreateWebApp"
            Configuration $configName {
                Import-DscResource -ModuleName SharePointDsc
                node "localhost" {
                    SPWebApplication MainWebApp {
                        Name = "Test Web App"
                        Url = "http://$($env:COMPUTERNAME)"
                        AllowAnonymous = $false
                        ApplicationPool = "Test Web App Pool"
                        ApplicationPoolAccount = $Global:SPDscIntegrationCredPool.WebApp.UserName
                        AuthenticationMethod = "NTLM"
                        DatabaseName = "SP_Content"
                        DatabaseServer = $env:COMPUTERNAME
                        Port = 80
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
