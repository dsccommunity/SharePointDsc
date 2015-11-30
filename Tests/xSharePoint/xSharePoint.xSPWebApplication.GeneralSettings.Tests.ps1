[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebApplication"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWebApplication (General Settings)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "SharePoint Sites"
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
            GeneralSettings = (New-CimInstance -ClassName MSFT_xSPWebApplicationSettings -Property @{
                TimeZone = 3081
                Alerts = $true
                AlertsLimit = 10
                RSS = $true
                BlogAPI = $true
                BlogAPIAuthenticated = $true
                BrowserFileHandling = "Permissive"
                SecurityValidation = $true
                RecycleBinEnabled = $true
                RecycleBinCleanupEnabled = $true
                RecycleBinRetentionPeriod = 30
                SecondStageRecycleBinQuota = 30
                MaximumUploadSize = 100
                CustomerExperienceProgram = $true
                PresenceEnabled = $true
            } -ClientOnly)
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock New-SPAuthenticationProvider { }
        Mock New-SPWebApplication { }
        Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $true; AllowAnonymous = $false } }

        Context "The web appliation exists and has the correct general settings" {
            Mock Get-SPWebApplication { 
                $webApp = @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    DefaultTimeZone = $testParams.GeneralSettings.TimeZone
                    AlertsEnabled = $testParams.GeneralSettings.Alerts
                    AlertsMaximum = $testParams.GeneralSettings.AlertsLimit
                    SyndicationEnabled = $testParams.GeneralSettings.RSS
                    MetaWeblogEnabled = $testParams.GeneralSettings.BlogAPI
                    MetaWeblogAuthenticationEnabled = $testParams.GeneralSettings.BlogAPIAuthenticated
                    BrowserFileHandling = $testParams.GeneralSettings.BrowserFileHandling
                    FormDigestSettings = @{
                        Enabled = $testParams.GeneralSettings.SecurityValidation
                    }
                    RecycleBinEnabled = $testParams.GeneralSettings.RecycleBinEnabled
                    RecycleBinCleanupEnabled = $testParams.GeneralSettings.RecycleBinCleanupEnabled
                    RecycleBinRetentionPeriod = $testParams.GeneralSettings.RecycleBinRetentionPeriod
                    SecondStageRecycleBinQuota = $testParams.GeneralSettings.SecondStageRecycleBinQuota
                    MaximumFileSize = $testParams.GeneralSettings.MaximumUploadSize
                    BrowserCEIPEnabled = $testParams.GeneralSettings.CustomerExperienceProgram
                    PresenceEnabled = $testParams.GeneralSettings.PresenceEnabled
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The web appliation exists and uses incorrect general settings" {    
            Mock Get-SPWebApplication { 
                $webApp = @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    DefaultTimeZone = 1
                    AlertsEnabled = $false
                    AlertsMaximum = 1
                    SyndicationEnabled = $false
                    MetaWeblogEnabled = $false
                    MetaWeblogAuthenticationEnabled = $false
                    BrowserFileHandling = "Strict"
                    FormDigestSettings = @{
                        Enabled = $false
                    }
                    RecycleBinEnabled = $false
                    RecycleBinCleanupEnabled = $false
                    RecycleBinRetentionPeriod = 1
                    SecondStageRecycleBinQuota = 1
                    MaximumFileSize = 1
                    BrowserCEIPEnabled = $false
                    PresenceEnabled = $false
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "updates the workflow settings" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }
    }    
}