[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPWebAppGeneralSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName New-SPAuthenticationProvider -MockWith { }
        Mock -CommandName New-SPWebApplication -MockWith { }
        Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
            return @{ 
                DisableKerberos = $true
                AllowAnonymous = $false 
            } 
        }

        # Test contexts
        Context -Name "The web appliation exists and has the correct general settings" -Fixture {
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

            Mock -CommandName Get-SPWebapplication -MockWith { 
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
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "Should return the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The web appliation exists and uses incorrect general settings" -Fixture {    
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

            Mock -CommandName Get-SPWebapplication -MockWith { 
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
                $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "Should return the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscWebApplicationUpdateCalled = $false
            It "Should update the general settings" {
                Set-TargetResource @testParams
                $Global:SPDscWebApplicationUpdateCalled | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
