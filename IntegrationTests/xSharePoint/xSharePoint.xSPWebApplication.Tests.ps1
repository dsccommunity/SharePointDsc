[CmdletBinding()]
param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\xSharePoint.psd1")

Describe -Tags @("WebApp") "xSPWebApplication - Integration Tests" {
    Context "Creates new new web applications" {
        It "Is able to create a new web application" {
            Configuration xSPCreateWebApp {
                Import-DscResource -ModuleName xSharePoint
                node "localhost" {
                    xSPWebApplication MainWebApp {
                        Name = "Test Web App"
                        Url = "http://$($env:COMPUTERNAME)"
                        AllowAnonymous = $false
                        ApplicationPool = "Test Web App Pool"
                        ApplicationPoolAccount = $Global:xSPIntegrationCredPool.WebApp.UserName
                        AuthenticationMethod = "NTLM"
                        DatabaseName = "SP_Content"
                        DatabaseServer = $env:COMPUTERNAME
                        Port = 80
                        PsDscRunAsCredential = $Global:xSPIntegrationCredPool.Setup
                    }
                }
            }
            xSPCreateWebApp -ConfigurationData $global:xSPIntegrationConfigData -OutputPath "TestDrive:\xSPCreateWebApp"
            Start-DscConfiguration -Wait -Force -Path "TestDrive:\xSPCreateWebApp" -ComputerName "localhost"
            (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\xSPCreateWebApp\localhost.mof").InDesiredState | Should be $true    
        }
    }
    
    AfterEach {
        Remove-DscConfigurationDocument -Stage Current, Pending, Previous -Force -Confirm:$false
    }
}