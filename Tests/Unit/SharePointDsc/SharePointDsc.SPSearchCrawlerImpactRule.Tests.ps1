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
                                              -DscResource "SPSearchCrawlerImpactRule" 

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"

        # Mocks for all contexts   
        Mock -CommandName Remove-SPEnterpriseSearchCrawlRule -MockWith {}   
        Mock -CommandName New-SPEnterpriseSearchCrawlRule -MockWith {}   
        Mock -CommandName Set-SPEnterpriseSearchCrawlRule -MockWith {}   

        Mock -CommandName Get-SPServiceApplication -MockWith { 
            return @(
                New-Object -TypeName "Object" |  
                    Add-Member -MemberType ScriptMethod `
                               -Name GetType `
                               -Value {
                        New-Object -TypeName "Object" |
                            Add-Member -MemberType NoteProperty `
                                       -Name FullName `
                                       -Value $getTypeFullName `
                                       -PassThru
                                        } `
                            -PassThru -Force)
        }

        # Test contexts
        Context -Name "When crawler impact rule should exist and doesn't exist" -Fixture {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Name = "http://site.sharepoint.com"
                RequestLimit = 8
                Ensure = "Present"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName Get-SPEnterpriseSearchSiteHitRule -MockWith { 
                return $null 
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new search site hit rule in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchSiteHitRule 
            }
        }
        
        Context -Name "When crawler impact rule should exist and does exist" -Fixture {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Name = "http://site.sharepoint.com"
                RequestLimit = 8
                Ensure = "Present"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName Get-SPEnterpriseSearchSiteHitRule -MockWith { 
                return @{
                    Name = $testParams.Name
                    HitRate = $testParams.RequestLimit
                }
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should update a new search Site hit rule in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchSiteHitRule 
                Assert-MockCalled New-SPEnterpriseSearchSiteHitRule
            }
        }


        Context -Name "When crawler impact rule shouldn't exist and doesn't exist" -Fixture {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Name = "http://site.sharepoint.com"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName Get-SPEnterpriseSearchSiteHitRule -MockWith { 
                return @{
                    Name = $testParams.Name
                    HitRate = $testParams.RequestLimit
                }
            }
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should remove the search Site hit rule in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchSiteHitRule 
               
            }
        }

        Context -Name "When crawler impact rule shouldn't exist and does exist" -Fixture {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Name = "http://site.sharepoint.com"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName Get-SPEnterpriseSearchSiteHitRule -MockWith { 
                return $null
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should remove the search Site hit rule in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchSiteHitRule 
               
            }
        }

        Context -Name "When the Search Service does not exist" -Fixture {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Name = "http://site.sharepoint.com"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return $null
            }


            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw a search service not found exception" {
            { Set-TargetResource @testParams } | Should Throw "The Search Service Application does not exist."
             
               
            }

        }

         Context -Name "When the both RequestLimit and WaitTime are specified" -Fixture {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Name = "http://site.sharepoint.com"
                RequestLimit = 8
                WaitTime = 60
                Ensure = "Present"
            }

            It "Should throw an exception when called with both RequestLimit and WaitTime" {
                { Get-TargetResource @testParams } | Should Throw "Only one Crawler Impact Rule HitRate argument (RequestLimit, WaitTime) can be specified"
                { Test-TargetResource @testParams } | Should Throw "Only one Crawler Impact Rule HitRate argument (RequestLimit, WaitTime) can be specified"  
                { Set-TargetResource @testParams } | Should Throw "Only one Crawler Impact Rule HitRate argument (RequestLimit, WaitTime) can be specified"
                    
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
