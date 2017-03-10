[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPSearchAuthoratativePage"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts   
        
        Mock -CommandName Get-SPEnterpriseSearchQueryAuthority -MockWith { }
        Mock -CommandName New-SPEnterpriseSearchQueryAuthority -MockWith { }
        Mock -CommandName Set-SPEnterpriseSearchQueryAuthority -MockWith { }
        Mock -CommandName Remove-SPEnterpriseSearchQueryAuthority -MockWith { }
        
        Mock -CommandName Get-SPEnterpriseSearchQueryDemoted -MockWith { }
        Mock -CommandName New-SPEnterpriseSearchQueryDemoted -MockWith { }
        Mock -CommandName Remove-SPEnterpriseSearchQueryDemoted -MockWith { }
        
        # Test contexts
        Context -Name "A SharePoint Search Service doesn't exists" {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Path = "http://site.sharepoint.com/pages/authoratative.aspx"
                Action = "Authoratative"
                Level = 0.0
                Ensure = "Present"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return $null
            }

            
            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should throw an exception in the set method" {
                {Set-TargetResource @testParams} | Should Throw "Search Service App was not available."

            }
        }
        
        Context -Name "A search query authoratative page does exist and should" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
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
            
            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "A search query authoratative page does exist and shouldn't" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
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
            
            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context -Name "A search query authoratative page doesn't exist and shouldn't" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                return $null
            }
            
            It "Should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "A search query authoratative page doesn't exist but should" -Fixture {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Website"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                return $null
            }
            Mock -CommandName New-SPEnterpriseSearchCrawlContentSource -MockWith {
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
            
            It "Should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should create the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName New-SPEnterpriseSearchCrawlContentSource
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context -Name "A search query demoted page does exist and should" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
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
            
            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "A search query demoted page does exist and shouldn't" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
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
            
            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Remove-SPEnterpriseSearchCrawlContentSource
            }
        }
        
        Context -Name "A search query demoted page doesn't exist and shouldn't" {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "SharePoint"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Absent"
            }
            Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                return $null
            }
            
            It "Should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "A search query demoted page doesn't exist but should" -Fixture {
            $testParams = @{
                Name = "Example content source"
                ServiceAppName = "Search Service Application"
                ContentSourceType = "Website"
                Addresses = @("http://site.contoso.com")
                CrawlSetting = "CrawlEverything"
                Ensure = "Present"
            }
            Mock -CommandName Get-SPEnterpriseSearchCrawlContentSource -MockWith {
                return $null
            }
            Mock -CommandName New-SPEnterpriseSearchCrawlContentSource -MockWith {
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
            
            It "Should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should create the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName New-SPEnterpriseSearchCrawlContentSource
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchCrawlContentSource
            }
        }
       
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
