[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
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
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        Mock Start-Sleep {}
        Mock New-SPEnterpriseSearchCrawlContentSource {}
        Mock Set-SPEnterpriseSearchCrawlContentSource {}
        Mock Remove-SPEnterpriseSearchCrawlContentSource {}
        
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
                CrawlStatus = "Idle"
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
            
            It "should return absent from the get method" {
                
            }
            
            It "should return false from the test method" {
                
            }
            
            It "should create the content source in the set method" {
                
            }
        }
        
        Context "A website content source does exist and should" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A website content source does exist and shouldn't" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return false from the test method" {
                
            }
            
            It "should remove the content source in the set method" {
                
            }
        }
        
        Context "A website content source doesn't exist and shouldn't" {
            
            It "should return absent from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A website content source has incorrect crawl depth settings applied" {
            
            It "should return false from the test method" {
                
            }
            
            It "should update the settings in the set method" {
                
            }
        }
        
        Context "A file share content source doesn't exist but should" {
            
            It "should return absent from the get method" {
                
            }
            
            It "should return false from the test method" {
                
            }
            
            It "should create the content source in the set method" {
                
            }
        }
        
        Context "A file share content source does exist and should" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A file share content source does exist and shouldn't" {
            
            It "should return present from the get method" {
                
            }
            
            It "should return false from the test method" {
                
            }
            
            It "should remove the content source in the set method" {
                
            }
        }
        
        Context "A file share content source doesn't exist and shouldn't" {
            
            It "should return absent from the get method" {
                
            }
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A file share content source has incorrect crawl depth settings applied" {
            
            It "should return false from the test method" {
                
            }
            
            It "should update the settings in the set method" {
                
            }
        }
        
        Context "A content source has a full schedule that does not match the desired schedule" {
            
            It "should return false from the test method" {
                
            }
            
            It "should update the schedule in the set method" {
                
            }
        }
        
        Context "A content source has a full schedule that does match the desired schedule" {
            
            It "should return true from the test method" {
                
            }
        }
        
        Context "A content source has a incremental schedule that does not match the desired schedule" {
            
            It "should return false from the test method" {
                
            }
            
            It "should update the schedule in the set method" {
                
            }
        }
        
        Context "A content source has a incremental schedule that does match the desired schedule" {
            
            It "should return true from the test method" {
                
            }
        }
    }
}