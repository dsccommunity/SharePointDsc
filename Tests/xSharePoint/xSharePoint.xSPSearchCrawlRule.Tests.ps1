[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPSearchCrawlRule"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSearchCrawlRule" {
    InModuleScope $ModuleName {
        $testParams = @{
            Path = "http://www.contoso.com"
            ServiceAppName = "Search Service Application"
            Type = "InclusionRule"
            CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
            AuthenticationType = "DefaultRuleAccess"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock Remove-SPEnterpriseSearchCrawlRule {}   
        Mock New-SPEnterpriseSearchCrawlRule {}   
        Mock Set-SPEnterpriseSearchCrawlRule {}   

        Context "Absent specified: Can only contain Path and ServiceAppName" {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                Ensure = "Absent"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty  
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should be $false
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Invalid parameters specified. Please check verbose messages to check which parameters are invalid."
            }
        }

        Context "AuthenticationType=CertificateName and CertificateRuleAccess parameters not specified correctly" {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "CertificateRuleAccess"
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty  
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should be $false
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Invalid parameters specified. Please check verbose messages to check which parameters are invalid."
            }
        }

        Context "AuthenticationType=NTLMAccountRuleAccess and AuthenticationCredentialsparameters not specified correctly" {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "NTLMAccountRuleAccess"
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty  
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should be $false
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Invalid parameters specified. Please check verbose messages to check which parameters are invalid."
            }
        }

        Context "AuthenticationType=BasicAccountRuleAccess and AuthenticationCredentialsparameters not specified correctly" {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "BasicAccountRuleAccess"
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty  
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should be $false
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Invalid parameters specified. Please check verbose messages to check which parameters are invalid."
            }
        }

        Context "ExclusionRule only with CrawlConfigurationRules=CrawlComplexUrls" {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                Type = "ExclusionRule"
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty  
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should be $false
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Invalid parameters specified. Please check verbose messages to check which parameters are invalid."
            }
        }

        Context "ExclusionRule cannot be used with AuthenticationCredentials, CertificateName or AuthenticationType parameters" {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                Type = "ExclusionRule"
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty  
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should be $false
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Invalid parameters specified. Please check verbose messages to check which parameters are invalid."
            }
        }
  
        Context "When no service applications exist in the current farm" {

            Mock Get-SPServiceApplication { return $null }
            
            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchCrawlRule 
            }
        }

        Context "When service applications exist in the current farm but the specific search app does not" {

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchCrawlRule 
            }
        }

        Context "When a crawl rule exists and is configured correctly" {
            
            Mock Get-SPEnterpriseSearchCrawlRule { return @{
                    Path = "http://www.contoso.com"
                    Type = "InclusionRule"
                    SuppressIndexing = $true
                    FollowComplexUrls = $true
                    CrawlAsHttp = $true
                    AuthenticationType = "DefaultRuleAccess"
                }
            }
            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "When a service application exists and the app pool is not configured correctly" {

            Mock Get-SPEnterpriseSearchCrawlRule { return @{
                    Path = "http://www.contoso.com"
                    Type = "InclusionRule"
                    SuppressIndexing = $false
                    FollowComplexUrls = $true
                    CrawlAsHttp = $true
                    AuthenticationType = "DefaultRuleAccess"
                    Ensure = "Present"
                }
            }
            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPEnterpriseSearchCrawlRule
            }
        }
    }    
}
