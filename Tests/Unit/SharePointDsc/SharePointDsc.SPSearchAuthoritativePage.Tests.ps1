[CmdletBinding()]
param(
    [Parameter()]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPSearchAuthoritativePage"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope
try 
{
        Add-Type -TypeDefinition @"
namespace Microsoft.Office.Server.Search.Administration { 
    public enum SearchObjectLevel
    {
        SPWeb,
        SPSite,
        SPSiteSubscription,
        Ssa
    }
    
   
    public class SearchObjectOwner {
        public SearchObjectOwner(Microsoft.Office.Server.Search.Administration.SearchObjectLevel level) { }
    }
}
"@ -ErrorAction SilentlyContinue
}
catch
{

}
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
                ServiceAppName = "Search Service Application"
                Path = "http://site.sharepoint.com/pages/authoratative.aspx"
                Action = "Authoratative"
                Level = 0.0
                Ensure = "Present"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{ 
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName  Get-SPEnterpriseSearchQueryAuthority -MockWith {
                return @{ 
                    Identity = $testParams.Path
                    Level = $testParams.Level
                }
            }

            Mock -CommandName Set-SPEnterpriseSearchQueryAuthority -MockWith {
                return @{
                    Identity = $testParams.Path
                    Level = $testParams.Level
                }
            }
            
            
            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should call Set functions from the Set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPEnterpriseSearchServiceApplication -Times 1
                Assert-MockCalled Set-SPEnterpriseSearchQueryAuthority -Times 1
            }

        }
        
        Context -Name "A search query authoratative page does exist and shouldn't" {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Path = "http://site.sharepoint.com/pages/authoratative.aspx"
                Action = "Authoratative"
                Level = 0.0
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{ 
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName  Get-SPEnterpriseSearchQueryAuthority -MockWith {
                return @{ 
                    Identity = $testParams.Path
                    Level = $testParams.Level
                }
            }

            Mock -CommandName Remove-SPEnterpriseSearchQueryAuthority -MockWith {
                return $null 
            }

            
            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
             It "Should call Set functions from the Set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPEnterpriseSearchServiceApplication -Times 1
                Assert-MockCalled Remove-SPEnterpriseSearchQueryAuthority -Times 1
            }
        }
        
        Context -Name "A search query authoratative page doesn't exist and shouldn't" {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Path = "http://site.sharepoint.com/pages/authoratative.aspx"
                Action = "Authoratative"
                Level = 0.0
                Ensure = "Absent"
            } 
           
            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{ 
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName  Get-SPEnterpriseSearchQueryAuthority -MockWith {
                return $null
            }

            Mock -CommandName Remove-SPEnterpriseSearchQueryAuthority -MockWith {
                return $null
            }


            It "Should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should call Set functions from the Set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPEnterpriseSearchServiceApplication -Times 1
                Assert-MockCalled Remove-SPEnterpriseSearchQueryAuthority -Times 1
            }
        }
        
        Context -Name "A search query authoratative page doesn't exist but should" -Fixture {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Path = "http://site.sharepoint.com/pages/authoratative.aspx"
                Action = "Authoratative"
                Level = 0.0
                Ensure = "Present"
            }

             Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{ 
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName  Get-SPEnterpriseSearchQueryAuthority -MockWith {
                return $null
            }

            Mock -CommandName New-SPEnterpriseSearchQueryAuthority -MockWith {
                return @{
                    Identity = $testParams.Path
                    Level = $testParams.Level
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
                
                Assert-MockCalled -CommandName Get-SPEnterpriseSearchServiceApplication -Times 1    
               
            }
        }
        
        Context -Name "A search query demoted page does exist and should" {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Path = "http://site.sharepoint.com/pages/authoratative.aspx"
                Action = "Demoted"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{ 
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName  Get-SPEnterpriseSearchQueryDemoted -MockWith {
                return @{ 
                    Identity = $testParams.Path
                }
            }

            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

             It "Should create the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Get-SPEnterpriseSearchServiceApplication -Times 1    
            }
        }
        
        Context -Name "A search query demoted page does exist and shouldn't" {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Path = "http://site.sharepoint.com/pages/authoratative.aspx"
                Action = "Demoted"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{ 
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName  Get-SPEnterpriseSearchQueryDemoted -MockWith {
                return @{ 
                    Identity = $testParams.Path
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
                
                Assert-MockCalled -CommandName Get-SPEnterpriseSearchServiceApplication -Times 1    
                Assert-MockCalled -CommandName Remove-SPEnterpriseSearchQueryDemoted -Times 1    
            }
        }
        
        Context -Name "A search query demoted page doesn't exist and shouldn't" {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Path = "http://site.sharepoint.com/pages/authoratative.aspx"
                Action = "Demoted"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{ 
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName  Get-SPEnterpriseSearchQueryDemoted -MockWith {
                return $null
            }
            
            It "Should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
            It "Should remove the content source in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Get-SPEnterpriseSearchServiceApplication -Times 1    
                Assert-MockCalled -CommandName Remove-SPEnterpriseSearchQueryDemoted -Times 1    
            }
        }
        
        Context -Name "A search query demoted page doesn't exist but should" -Fixture {
            $testParams = @{
                ServiceAppName = "Search Service Application"
                Path = "http://site.sharepoint.com/pages/authoratative.aspx"
                Action = "Demoted"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                return @{ 
                    DisplayName = $testParams.ServiceAppName
                }
            }

            Mock -CommandName  Get-SPEnterpriseSearchQueryDemoted -MockWith {
                return $null
            }

            Mock -CommandName  New-SPEnterpriseSearchQueryDemoted -MockWith {
                return @{
                    Url = $params.Path
                }
            }
            
            It "Should return absent from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should create a new query demoted element in the set method" {
                Set-TargetResource @testParams
                
                Assert-MockCalled -CommandName Get-SPEnterpriseSearchServiceApplication -Times 1    
                Assert-MockCalled -CommandName New-SPEnterpriseSearchQueryDemoted -Times 1    
            }
        }
       
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
