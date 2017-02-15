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
                                              -DscResource "SPSearchCrawlRule"

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
        Context -Name "AuthenticationType=CertificateRuleAccess specified, but CertificateName missing" -Fixture {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "CertificateRuleAccess"
                Ensure = "Present"
            }
            
            It "Should return null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When AuthenticationType=CertificateRuleAccess, the parameter CertificateName is required"  
            }

            It "Should return false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When AuthenticationType=CertificateRuleAccess, the parameter CertificateName is required"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When AuthenticationType=CertificateRuleAccess, the parameter CertificateName is required"
            }
        }

        Context -Name "CertificateName specified, but AuthenticationType is not CertificateRuleAccess" -Fixture {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                CertificateName = "Test Certificate"
                Ensure = "Present"
            }
            
            It "Should return null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When specifying CertificateName, the AuthenticationType parameter is required"  
            }

            It "Should return false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When specifying CertificateName, the AuthenticationType parameter is required"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When specifying CertificateName, the AuthenticationType parameter is required"
            }
        }

        Context -Name " AuthenticationType=NTLMAccountRuleAccess and AuthenticationCredentialsparameters not specified" -Fixture {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "NTLMAccountRuleAccess"
                Ensure = "Present"
            }
            
            It "Should return null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When AuthenticationType is NTLMAccountRuleAccess or BasicAccountRuleAccess, the parameter AuthenticationCredentials is required"
            }

            It "Should return false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When AuthenticationType is NTLMAccountRuleAccess or BasicAccountRuleAccess, the parameter AuthenticationCredentials is required"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When AuthenticationType is NTLMAccountRuleAccess or BasicAccountRuleAccess, the parameter AuthenticationCredentials is required"
            }
        }

        Context -Name "AuthenticationCredentials parameters, but AuthenticationType is not NTLMAccountRuleAccess or BasicAccountRuleAccess" -Fixture {
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

            It "Should return null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When specifying AuthenticationCredentials, the AuthenticationType parameter is required"
            }

            It "Should return false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When specifying AuthenticationCredentials, the AuthenticationType parameter is required"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When specifying AuthenticationCredentials, the AuthenticationType parameter is required"
            }
        }

        Context -Name "ExclusionRule only with CrawlConfigurationRules=CrawlComplexUrls" -Fixture {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                RuleType = "ExclusionRule"
                Ensure = "Present"
            }

            It "Should return null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When RuleType=ExclusionRule, CrawlConfigurationRules cannot contain the values FollowLinksNoPageCrawl or CrawlAsHTTP"
            }

            It "Should return false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When RuleType=ExclusionRule, CrawlConfigurationRules cannot contain the values FollowLinksNoPageCrawl or CrawlAsHTTP"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When RuleType=ExclusionRule, CrawlConfigurationRules cannot contain the values FollowLinksNoPageCrawl or CrawlAsHTTP"
            }
        }

        Context -Name "ExclusionRule cannot be used with AuthenticationCredentials, CertificateName or AuthenticationType parameters" -Fixture {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                CrawlConfigurationRules = "CrawlComplexUrls"
                AuthenticationType = "DefaultRuleAccess"
                RuleType = "ExclusionRule"
                Ensure = "Present"
            }
            
            It "Should return null from the Get method" {
                { Get-TargetResource @testParams } | Should throw "When Type=ExclusionRule, parameters AuthenticationCredentials, CertificateName or AuthenticationType are not allowed"
            }

            It "Should return false when the Test method is called" {
                { Test-TargetResource @testParams } | Should throw "When Type=ExclusionRule, parameters AuthenticationCredentials, CertificateName or AuthenticationType are not allowed"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "When Type=ExclusionRule, parameters AuthenticationCredentials, CertificateName or AuthenticationType are not allowed"
            }
        }

        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                RuleType = "InclusionRule"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchCrawlRule 
            }
        }

        Context -Name "When service applications exist in the current farm but the specific search app does not" -Fixture {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                RuleType = "InclusionRule"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Some other service app type"
                }) 
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchCrawlRule 
            }
        }

        Context -Name "When a crawl rule exists and is configured correctly" -Fixture {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                RuleType = "InclusionRule"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPEnterpriseSearchCrawlRule -MockWith { return @{
                    Path = "http://www.contoso.com"
                    Type = "InclusionRule"
                    SuppressIndexing = $true
                    FollowComplexUrls = $true
                    CrawlAsHttp = $true
                    AuthenticationType = "DefaultRuleAccess"
                }
            }
            
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a crawl rule exists, but isn't configured correctly" -Fixture {
            $testParams = @{
                Path = "http://www.contoso.com"
                ServiceAppName = "Search Service Application"
                RuleType = "InclusionRule"
                CrawlConfigurationRules = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType = "DefaultRuleAccess"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPEnterpriseSearchCrawlRule -MockWith { return @{
                    Path = "http://www.contoso.com"
                    Type = "InclusionRule"
                    SuppressIndexing = $false
                    FollowComplexUrls = $true
                    CrawlAsHttp = $true
                    AuthenticationType = "DefaultRuleAccess"
                }
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPEnterpriseSearchCrawlRule
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
