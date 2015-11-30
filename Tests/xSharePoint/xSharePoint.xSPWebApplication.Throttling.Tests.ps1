[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path "C:\users\brian\Documents\GitHubVisualStudio\xSharePoint\Tests\xSharePoint" "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebApplication"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\Modules\xSharePoint.Util\xSharePoint.Util.psm1")

Describe "xSPWebApplication (Throttling)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "SharePoint Sites"
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
            ThrottlingSettings = @{
                ListViewThreshold = 1000
                AllowObjectModelOverride = $true
                AdminThreshold = 2000
                ListViewLookupThreshold = 12
                HappyHourEnabled = $true
                HappyHour = @{
                    Hour = 2
                    Minute = 0
                    Duration = 1
                }
                UniquePermissionThreshold = 100
                RequestThrottling = $true
                ChangeLogEnabled = $true
                ChangeLogExpiryDays = 30
                EventHandlersEnabled = $true
            }
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock New-SPAuthenticationProvider { }
        Mock New-SPWebApplication { }
        Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $true; AllowAnonymous = $false } }

        Context "The web appliation exists and has the correct throttling settings" {
            Mock Get-SPWebApplication { return @(@{
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
                MaxItemsPerThrottledOperation = $testParams.ThrottlingSettings.ListViewThreshold
                AllowOMCodeOverrideThrottleSettings = $testParams.ThrottlingSettings.AllowObjectModelOverride
                MaxItemsPerThrottledOperationOverride = $testParams.ThrottlingSettings.AdminThreshold
                MaxQueryLookupFields = $testParams.ThrottlingSettings.ListViewLookupThreshold
                UnthrottledPrivilegedOperationWindowEnabled = $testParams.ThrottlingSettings.HappyHourEnabled
                DailyStartUnthrottledPrivilegedOperationsHour = $testParams.ThrottlingSettings.HappyHour.Hour
                DailyStartUnthrottledPrivilegedOperationsMinute = $testParams.ThrottlingSettings.HappyHour.Minute
                DailyUnthrottledPrivilegedOperationsDuration = $testParams.ThrottlingSettings.HappyHour.Duration
                MaxUniquePermScopesPerList = $testParams.ThrottlingSettings.UniquePermissionThreshold
                HttpThrottleSettings = @{
                    PerformThrottle = $testParams.ThrottlingSettings.RequestThrottling
                }
                ChangeLogExpirationEnabled = $testParams.ThrottlingSettings.ChangeLogEnabled
                ChangeLogRetentionPeriod = @{
                    Days = $testParams.ThrottlingSettings.ChangeLogExpiryDays
                }
                EventHandlersEnabled = $testParams.ThrottlingSettings.EventHandlersEnabled
            })}

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The web appliation exists and uses incorrect throttling settings" {    
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
                    MaxItemsPerThrottledOperation = 1
                    AllowOMCodeOverrideThrottleSettings = $testParams.ThrottlingSettings.AllowObjectModelOverride
                    MaxItemsPerThrottledOperationOverride = $testParams.ThrottlingSettings.AdminThreshold
                    MaxQueryLookupFields = $testParams.ThrottlingSettings.ListViewLookupThreshold
                    UnthrottledPrivilegedOperationWindowEnabled = $testParams.ThrottlingSettings.HappyHourEnabled
                    DailyStartUnthrottledPrivilegedOperationsHour = $testParams.ThrottlingSettings.HappyHour.Hour
                    DailyStartUnthrottledPrivilegedOperationsMinute = $testParams.ThrottlingSettings.HappyHour.Minute
                    DailyUnthrottledPrivilegedOperationsDuration = $testParams.ThrottlingSettings.HappyHour.Duration
                    MaxUniquePermScopesPerList = $testParams.ThrottlingSettings.UniquePermissionThreshold
                    HttpThrottleSettings = @{
                        PerformThrottle = $testParams.ThrottlingSettings.RequestThrottling
                    }
                    ChangeLogExpirationEnabled = $testParams.ThrottlingSettings.ChangeLogEnabled
                    ChangeLogRetentionPeriod = @{
                        Days = $testParams.ThrottlingSettings.ChangeLogExpiryDays
                    }
                    EventHandlersEnabled = $testParams.ThrottlingSettings.EventHandlersEnabled
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru | Add-Member ScriptMethod SetDailyUnthrottledPrivilegedOperationWindow {
                    $Global:xSPWebApplicationUpdateHappyHourCalled = $true
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
            $Global:xSPWebApplicationUpdateHappyHourCalled = $false
            It "updates the throttling settings" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }

            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "NTLM"
                ThrottlingSettings = @{
                    ListViewThreshold = 1000
                    AllowObjectModelOverride = $true
                    AdminThreshold = 2000
                    ListViewLookupThreshold = 12
                    HappyHourEnabled = $true
                    HappyHour = @{
                        Hour = 5
                        Minute = 0
                        Duration = 1
                    }
                    UniquePermissionThreshold = 100
                    RequestThrottling = $true
                    ChangeLogEnabled = $true
                    ChangeLogExpiryDays = 30
                    EventHandlersEnabled = $true
                }
            }
            $Global:xSPWebApplicationUpdateCalled = $false
            $Global:xSPWebApplicationUpdateHappyHourCalled = $false
            It "updates the incorrect happy hour settings" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
                $Global:xSPWebApplicationUpdateHappyHourCalled | Should Be $true
            }

            it "throws exceptions where invalid happy hour settings are provided" {
                $testParams = @{
                    Name = "SharePoint Sites"
                    ApplicationPool = "SharePoint Web Apps"
                    ApplicationPoolAccount = "DEMO\ServiceAccount"
                    Url = "http://sites.sharepoint.com"
                    AuthenticationMethod = "NTLM"
                    ThrottlingSettings = @{
                        HappyHourEnabled = $true
                        HappyHour = @{
                            Hour = 100
                            Minute = 0
                            Duration = 1
                        }
                    }
                }
                { Set-TargetResource @testParams } | Should throw

                $testParams = @{
                    Name = "SharePoint Sites"
                    ApplicationPool = "SharePoint Web Apps"
                    ApplicationPoolAccount = "DEMO\ServiceAccount"
                    Url = "http://sites.sharepoint.com"
                    AuthenticationMethod = "NTLM"
                    ThrottlingSettings = @{
                        HappyHourEnabled = $true
                        HappyHour = @{
                            Hour = 5
                            Minute = 100
                            Duration = 1
                        }
                    }
                }
                { Set-TargetResource @testParams } | Should throw

                $testParams = @{
                    Name = "SharePoint Sites"
                    ApplicationPool = "SharePoint Web Apps"
                    ApplicationPoolAccount = "DEMO\ServiceAccount"
                    Url = "http://sites.sharepoint.com"
                    AuthenticationMethod = "NTLM"
                    ThrottlingSettings = @{
                        HappyHourEnabled = $true
                        HappyHour = @{
                            Hour = 5
                            Minute = 0
                            Duration = 100
                        }
                    }
                }
                { Set-TargetResource @testParams } | Should throw
            }
        }
    }    
}