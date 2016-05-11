[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPSearchCrawlRule"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "SPSearchCrawlRule" {
    InModuleScope $ModuleName {
        $testParams = @{
            Path = "http://www.contoso.com"
            ServiceAppName = "Search Service Application"
            RuleType = "InclusionRule"
            CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
            AuthenticationType = "DefaultRuleAccess"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock Remove-SPEnterpriseSearchCrawlRule {}   
        Mock New-SPEnterpriseSearchCrawlRule {}   
        Mock Set-SPEnterpriseSearchCrawlRule {}   

        Context "AuthenticationType=CertificateRuleAccess specified, but CertificateName missing" {
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
                { Get-TargetResource @testParams } | Should throw "When AuthenticationType=CertificateRuleAccess, the parameter CertificateName is required"  
            }

            It "returns false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When AuthenticationType=CertificateRuleAccess, the parameter CertificateName is required"
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When AuthenticationType=CertificateRuleAccess, the parameter CertificateName is required"
            }
        }

        Context "CertificateName specified, but AuthenticationType is not CertificateRuleAccess" {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                CertificateName = "Test Certificate"
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When specifying CertificateName, the AuthenticationType parameter is required"  
            }

            It "returns false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When specifying CertificateName, the AuthenticationType parameter is required"
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When specifying CertificateName, the AuthenticationType parameter is required"
            }
        }

        Context " AuthenticationType=NTLMAccountRuleAccess and AuthenticationCredentialsparameters not specified" {
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
                { Get-TargetResource @testParams } | Should throw "When AuthenticationType is NTLMAccountRuleAccess or BasicAccountRuleAccess, the parameter AuthenticationCredentials is required"
            }

            It "returns false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When AuthenticationType is NTLMAccountRuleAccess or BasicAccountRuleAccess, the parameter AuthenticationCredentials is required"
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When AuthenticationType is NTLMAccountRuleAccess or BasicAccountRuleAccess, the parameter AuthenticationCredentials is required"
            }
        }

        Context "AuthenticationCredentials parameters, but AuthenticationType is not NTLMAccountRuleAccess or BasicAccountRuleAccess" {
            $User = "Domain01\User01"
            $PWord = ConvertTo-SecureString -String "P@sSwOrd" -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
            
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                AuthenticationCredentials = $Credential
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When specifying AuthenticationCredentials, the AuthenticationType parameter is required"
            }

            It "returns false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When specifying AuthenticationCredentials, the AuthenticationType parameter is required"
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When specifying AuthenticationCredentials, the AuthenticationType parameter is required"
            }
        }

        Context "ExclusionRule only with CrawlConfigurationRules=CrawlComplexUrls" {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                RuleType = "ExclusionRule"
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When RuleType=ExclusionRule, CrawlConfigurationRules cannot contain the values FollowLinksNoPageCrawl or CrawlAsHTTP"
            }

            It "returns false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When RuleType=ExclusionRule, CrawlConfigurationRules cannot contain the values FollowLinksNoPageCrawl or CrawlAsHTTP"
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When RuleType=ExclusionRule, CrawlConfigurationRules cannot contain the values FollowLinksNoPageCrawl or CrawlAsHTTP"
            }
        }

        Context "ExclusionRule cannot be used with AuthenticationCredentials, CertificateName or AuthenticationType parameters" {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "CrawlComplexUrls"
                AuthenticationType = "DefaultRuleAccess"
                RuleType = "ExclusionRule"
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Search Service Application"
            }) }
            
            It "returns null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When Type=ExclusionRule, parameters AuthenticationCredentials, CertificateName or AuthenticationType are not allowed"
            }

            It "returns false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When Type=ExclusionRule, parameters AuthenticationCredentials, CertificateName or AuthenticationType are not allowed"
            }

            It "throws exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When Type=ExclusionRule, parameters AuthenticationCredentials, CertificateName or AuthenticationType are not allowed"
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

        Context "When a crawl rule exists, but isn't configured correctly" {

            Mock Get-SPEnterpriseSearchCrawlRule { return @{
                    Path = "http://www.contoso.com"
                    Type = "InclusionRule"
                    SuppressIndexing = $false
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
