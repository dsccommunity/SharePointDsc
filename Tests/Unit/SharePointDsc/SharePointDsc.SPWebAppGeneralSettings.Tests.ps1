[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPWebAppGeneralSettings"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPWebAppGeneralSettings - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Url = "http://sites.sharepoint.com"
            TimeZone = 3081
            Alerts = $true
            AlertsLimit = 10
            RSS = $true
            BlogAPI = $true
            BlogAPIAuthenticated = $true
            BrowserFileHandling = "Permissive"
            SecurityValidation = $true
            SecurityValidationExpires = $true
            SecurityValidationTimeoutMinutes = 10
            RecycleBinEnabled = $true
            RecycleBinCleanupEnabled = $true
            RecycleBinRetentionPeriod = 30
            SecondStageRecycleBinQuota = 30
            MaximumUploadSize = 100
            CustomerExperienceProgram = $true
            PresenceEnabled = $true
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
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
                    DefaultTimeZone = $testParams.TimeZone
                    AlertsEnabled = $testParams.Alerts
                    AlertsMaximum = $testParams.AlertsLimit
                    SyndicationEnabled = $testParams.RSS
                    MetaWeblogEnabled = $testParams.BlogAPI
                    MetaWeblogAuthenticationEnabled = $testParams.BlogAPIAuthenticated
                    BrowserFileHandling = $testParams.BrowserFileHandling
                    FormDigestSettings = @{
                        Enabled = $testParams.SecurityValidation
                        Expires = $testParams.SecurityValidationExpires
                        Timeout = (new-timespan -minutes $testParams.SecurityValidationTimeoutMinutes)
                    }
                    RecycleBinEnabled = $testParams.RecycleBinEnabled
                    RecycleBinCleanupEnabled = $testParams.RecycleBinCleanupEnabled
                    RecycleBinRetentionPeriod = $testParams.RecycleBinRetentionPeriod
                    SecondStageRecycleBinQuota = $testParams.SecondStageRecycleBinQuota
                    MaximumFileSize = $testParams.MaximumUploadSize
                    BrowserCEIPEnabled = $testParams.CustomerExperienceProgram
                    PresenceEnabled = $testParams.PresenceEnabled
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:SPWebApplicationUpdateCalled = $true
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
                    $Global:SPWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPWebApplicationUpdateCalled = $false
            It "updates the general settings" {
                Set-TargetResource @testParams
                $Global:SPWebApplicationUpdateCalled | Should Be $true
            }
        }
    }    
}
