[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPSearchContentSource"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSearchContentSource" {
    InModuleScope $ModuleName {
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        Mock Start-Sleep {}
        Mock Set-SPEnterpriseSearchCrawlContentSource {}
        Mock Remove-SPEnterpriseSearchCrawlContentSource {}
     
        Add-Type -TypeDefinition @"
namespace Microsoft.Office.Server.Search.Administration {
    [System.Flags]
    public enum DaysOfWeek {
        Monday = 1,
        Tuesday = 2,
        Wednesday = 4,
        Thursday = 8,
        Friday = 16,
        Saturday = 32,
        Sunday = 64,
        Weekdays = 128,
        Weekends = 256,
        AllDays = 512
    }    

    public class DailySchedule { 
        public int RepeatDuration {get; set;} 
        public int RepeatInterval {get; set;} 
        public int StartHour {get; set;}
        public int StartMinute {get; set;}
        public int DaysInterval {get; set;}
    }

    public class WeeklySchedule { 
        public int RepeatDuration {get; set;} 
        public int RepeatInterval {get; set;} 
        public int StartHour {get; set;}
        public int StartMinute {get; set;}
        public int WeeksInterval {get; set;}
        public Microsoft.Office.Server.Search.Administration.DaysOfWeek DaysOfWeek {get; set;}
    }
}
"@


        
        Context "A SharePoint content source doesn't exist but should" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return $null
            }
            Mock New-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "SharePoint"
                    SharePointCrawlBehavior = "CrawlVirtualServers"
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    EnableContinuousCrawls = $false
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should create the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName New-SPEnterpriseSearchCrawlContentSource
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context "A SharePoint content source does exist and should" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "SharePoint"
                    SharePointCrawlBehavior = "CrawlVirtualServers"
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    EnableContinuousCrawls = $false
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "A SharePoint content source does exist and shouldn't" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "SharePoint"
                    SharePointCrawlBehavior = "CrawlVirtualServers"
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    EnableContinuousCrawls = $false
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should remove the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context "A SharePoint content source doesn't exist and shouldn't" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return $null
            }
            
            It "should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "A SharePoint source that uses continuous crawl has incorrect settings applied" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                ContinuousCrawl = $true
                Ensure = "Present"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "SharePoint"
                    SharePointCrawlBehavior = "CrawlVirtualServers"
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://wrong.site"
                        }
                    )
                    EnableContinuousCrawls = $true
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should disable continuous crawl and then re-enable it when updating the content source" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource -ParameterFilter { $EnableContinuousCrawls -eq $false }
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource -ParameterFilter { $EnableContinuousCrawls -eq $true }
            }
        }
        
        Context "A website content source doesn't exist but should" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Website"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return $null
            }
            Mock New-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "Web"
                    MaxPageEnumerationDepth = [System.Int32]::MaxValue
                    MaxSiteEnumerationDepth = 0
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should create the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName New-SPEnterpriseSearchCrawlContentSource
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context "A website content source does exist and should" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Website"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "Web"
                    MaxPageEnumerationDepth = [System.Int32]::MaxValue
                    MaxSiteEnumerationDepth = 0
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "A website content source does exist and shouldn't" {
            
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Website"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "Web"
                    MaxPageEnumerationDepth = [System.Int32]::MaxValue
                    MaxSiteEnumerationDepth = 0
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should remove the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context "A website content source doesn't exist and shouldn't" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Website"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return $null
            }
            
            It "should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "A website content source has incorrect crawl depth settings applied" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Website"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "Web"
                    MaxPageEnumerationDepth = 0
                    MaxSiteEnumerationDepth = 0
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should update the settings in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context "A file share content source doesn't exist but should" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Fileshare"
                Addresses = @("\\server\share")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return $null
            }
            Mock New-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "File"
                    FollowDirectories = $true
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "file:///server/share"
                        }
                    )
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should create the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName New-SPEnterpriseSearchCrawlContentSource
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context "A file share content source does exist and should" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Fileshare"
                Addresses = @("\\server\share")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "File"
                    FollowDirectories = $true
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "file:///server/share"
                        }
                    )
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "A file share content source does exist and shouldn't" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Fileshare"
                Addresses = @("\\server\share")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "File"
                    FollowDirectories = $true
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "file:///server/share"
                        }
                    )
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should remove the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context "A file share content source doesn't exist and shouldn't" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Fileshare"
                Addresses = @("\\server\share")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return $null
            }
            
            It "should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "A file share content source has incorrect crawl depth settings applied" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Fileshare"
                Addresses = @("\\server\share")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                return @{
                    Type = "File"
                    FollowDirectories = $false
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "file:///server/share"
                        }
                    )
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should update the settings in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context "A content source has a full schedule that does not match the desired schedule" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
                FullSchedule = (New-CimInstance -ClassName MSFT_xSPSearchCrawlSchedule -Property @{
                    ScheduleType = "Daily"
                    StartHour = "0"
                    StartMinute = "0"
                    CrawlScheduleRepeatDuration = "1440"
                    CrawlScheduleRepeatInterval = "5"
                } -ClientOnly)
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                $schedule = New-Object -TypeName Microsoft.Office.Server.Search.Administration.DailySchedule
                $schedule.RepeatDuration = 1439 
                $schedule.RepeatInterval = 5
                $schedule.StartHour = 0
                $schedule.StartMinute = 0
                $schedule.DaysInterval = 1
                return @{
                    Type = "SharePoint"
                    SharePointCrawlBehavior = "CrawlVirtualServers"
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    EnableContinuousCrawls = $false
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $schedule
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should update the schedule in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource -ParameterFilter { $ScheduleType -eq "Full" }
            }
        }
        
        Context "A content source has a full schedule that does match the desired schedule" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
                FullSchedule = (New-CimInstance -ClassName MSFT_xSPSearchCrawlSchedule -Property @{
                    ScheduleType = "Daily"
                    StartHour = "0"
                    StartMinute = "0"
                    CrawlScheduleRepeatDuration = "1440"
                    CrawlScheduleRepeatInterval = "5"
                } -ClientOnly)
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                $schedule = New-Object -TypeName Microsoft.Office.Server.Search.Administration.DailySchedule
                $schedule.RepeatDuration = 1440 
                $schedule.RepeatInterval = 5
                $schedule.StartHour = 0
                $schedule.StartMinute = 0
                $schedule.DaysInterval = 1
                return @{
                    Type = "SharePoint"
                    SharePointCrawlBehavior = "CrawlVirtualServers"
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    EnableContinuousCrawls = $false
                    IncrementalCrawlSchedule = $null
                    FullCrawlSchedule = $schedule
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "A content source has a incremental schedule that does not match the desired schedule" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
                IncrementalSchedule = (New-CimInstance -ClassName MSFT_xSPSearchCrawlSchedule -Property @{
                    ScheduleType = "Weekly"
                    StartHour = "0"
                    StartMinute = "0"
                    CrawlScheduleDaysOfWeek = @("Monday", "Wednesday")
                } -ClientOnly)
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                $schedule = New-Object -TypeName Microsoft.Office.Server.Search.Administration.WeeklySchedule
                $schedule.StartHour = 0
                $schedule.StartMinute = 0
                $schedule.DaysOfWeek = [enum]::Parse([Microsoft.Office.Server.Search.Administration.DaysOfWeek], "Monday, Wednesday, Friday")
                return @{
                    Type = "SharePoint"
                    SharePointCrawlBehavior = "CrawlVirtualServers"
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    EnableContinuousCrawls = $false
                    IncrementalCrawlSchedule = $schedule
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should update the schedule in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource -ParameterFilter { $ScheduleType -eq "Incremental" }
            }
        }
        
        Context "A content source has a incremental schedule that does match the desired schedule" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
                IncrementalSchedule = (New-CimInstance -ClassName MSFT_xSPSearchCrawlSchedule -Property @{
                    ScheduleType = "Weekly"
                    StartHour = "0"
                    StartMinute = "0"
                    CrawlScheduleDaysOfWeek = @("Monday", "Wednesday", "Friday")
                } -ClientOnly)
            }
            Mock Get-SPEnterpriseSearchCrawlContentSource {
                $schedule = New-Object -TypeName Microsoft.Office.Server.Search.Administration.WeeklySchedule
                $schedule.StartHour = 0
                $schedule.StartMinute = 0
                $schedule.DaysOfWeek = [enum]::Parse([Microsoft.Office.Server.Search.Administration.DaysOfWeek], "Monday, Wednesday, Friday")
                return @{
                    Type = "SharePoint"
                    SharePointCrawlBehavior = "CrawlVirtualServers"
                    StartAddresses = @(
                        @{
                            AbsoluteUri = "http://site.contoso.com"
                        }
                    )
                    EnableContinuousCrawls = $false
                    IncrementalCrawlSchedule = $schedule
                    FullCrawlSchedule = $null
                    CrawlPriority = "Normal"
                    CrawlStatus = "Idle"
                }
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}