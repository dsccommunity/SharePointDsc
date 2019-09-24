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
    -DscResource "SPSite"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        try
        {
            [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]
        }
        catch
        {
            Add-Type -TypeDefinition @"
namespace Microsoft.SharePoint.Administration {
    public class SPAdministrationWebApplication {
        public SPAdministrationWebApplication()
        {
        }
        public static System.Object Local { get; set;}
    }
}
"@
        }

        # Mocks for all contexts
        $siteImplementation =
        {
            $rootWeb = @{
                AssociatedVisitorGroup              = $null
                AssociatedMemberGroup               = $null
                AssociatedOwnerGroup                = $null
                CreateDefaultAssociatedGroupsCalled = $false
            }
            $rootWeb | Add-Member -MemberType ScriptMethod `
                -Name CreateDefaultAssociatedGroups `
                -Value {
                $this.CreateDefaultAssociatedGroupsCalled = $true
            }
            $rootWeb = $rootWeb | Add-Member -MemberType ScriptMethod `
                -Name EnsureUser `
                -Value { return "user" } -PassThru

            $site = @{
                HostHeaderIsSiteName   = $false
                WebApplication         = @{
                    Url                     = "https://site.contoso.com"
                    UseClaimsAuthentication = $true
                }
                Url                    = "https://site.contoso.com"
                Owner                  = @{ UserLogin = "DEMO\owner" }
                Quota                  = @{ QuotaId = 65000 }
                RootWeb                = $rootWeb
                AdministrationSiteType = "None"
            }
            return $site
        }

        [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]::Local = @{ Url = "https://CentralAdmin.contoso.com" }

        Mock -CommandName Get-SPSite -MockWith {
            return @{
                Id            = 1
                SystemAccount = @{
                    UserToken = "CentralAdminSystemAccountUserToken"
                }
            }
        } -ParameterFilter {
            $Identity -eq "https://CentralAdmin.contoso.com"
        }

        Mock -CommandName New-Object -MockWith {
            $site = $siteImplementation.InvokeReturnAsIs()
            $Script:SPDscSystemAccountSite = $site
            return $site;
        } -ParameterFilter {
            $TypeName -eq "Microsoft.SharePoint.SPSite" -and
            $ArgumentList[1] -eq "CentralAdminSystemAccountUserToken"
        }

        Mock -CommandName New-SPSite -MockWith {
            $rootWeb = @{ }
            $rootWeb = $rootWeb | Add-Member -MemberType ScriptMethod `
                -Name CreateDefaultAssociatedGroups `
                -Value { } -PassThru
            $returnval = @{
                HostHeaderIsSiteName = $true
                WebApplication       = @{
                    Url                     = $testParams.Url
                    UseClaimsAuthentication = $false
                }
                Url                  = $testParams.Url
                Owner                = @{ UserLogin = "DEMO\owner" }
                SecondaryContact     = @{ UserLogin = "DEMO\secondowner" }
                Quota                = @{
                    QuotaId = 1
                }
                RootWeb              = $rootWeb
            }
            return $returnval
        }
        Mock -CommandName Get-SPDscContentService -MockWith {
            $quotaTemplates = @(@{
                    Test = @{
                        QuotaId = 65000
                    }
                })
            $quotaTemplatesCol = { $quotaTemplates }.Invoke()

            $contentService = @{
                QuotaTemplates = $quotaTemplatesCol
            }

            $contentService = $contentService | Add-Member -MemberType ScriptMethod `
                -Name Update `
                -Value {
                $Global:SPDscQuotaTemplatesUpdated = $true
            } -PassThru
            return $contentService
        }

        # Test contexts
        Context -Name "The site doesn't exist yet and should" -Fixture {
            $testParams = @{
                Url        = "http://site.sharepoint.com"
                OwnerAlias = "DEMO\User"
            }

            Mock -CommandName New-Object -MockWith {
                return $null;
            } -ParameterFilter {
                $TypeName -eq "Microsoft.SharePoint.SPSite" -and
                $ArgumentList[0] -eq "http://site.sharepoint.com" -and
                $ArgumentList[1] -eq "CentralAdminSystemAccountUserToken"
            }

            Mock -CommandName Get-SPSite -MockWith { return $null }

            It "Should return OwnerAlias=Null from the get method" {
                (Get-TargetResource @testParams).OwnerAlias | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new site from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSite
            }
        }

        Context -Name "The site exists, but has incorrect owner alias and quota" -Fixture {
            $testParams = @{
                Url                    = "http://site.sharepoint.com"
                OwnerAlias             = "DEMO\User"
                SecondaryOwnerAlias    = "DEMO\SecondUser"
                QuotaTemplate          = "Test"
                AdministrationSiteType = "TenantAdministration"
            }

            $contextSiteImplementation = {
                $site = $siteImplementation.InvokeReturnAsIs()
                $site.WebApplication.Url = $testParams.Url
                $site.WebApplication.UseClaimsAuthentication = $false
                $site.Url = $testParams.Url
                $site.Owner = @{ UserLogin = "DEMO\owner" }
                $site.SecondaryContact = @{ UserLogin = "DEMO\secondowner" }
                $site.Quota = @{
                    QuotaId = 1
                }
                return $site;
            }

            Mock -CommandName New-Object -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSystemAccountSite = $site
                return $site
            } -ParameterFilter {
                $TypeName -eq "Microsoft.SharePoint.SPSite" -and
                $ArgumentList[0] -eq $testParams.Url -and
                $ArgumentList[1] -eq "CentralAdminSystemAccountUserToken"
            }

            Mock -CommandName Get-SPSite -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSite = $site
                return $site
            }

            Mock -CommandName Set-SPSite -MockWith { } -ParameterFilter {
                $QuotaTemplate = "Test"
                $AdministrationSiteType -eq "TenantAdministration"
            }
            Mock -CommandName Get-SPDscContentService -MockWith {
                $quotaTemplates = @(@{
                        QuotaId       = 1
                        Name          = "WrongTemplate"
                        WrongTemplate = @{
                            StorageMaximumLevel  = 512
                            StorageWarningLevel  = 256
                            UserCodeMaximumLevel = 400
                            UserCodeWarningLevel = 200
                        }
                    })
                $quotaTemplatesCol = { $quotaTemplates }.Invoke()

                $contentService = @{
                    QuotaTemplates = $quotaTemplatesCol
                }
                return $contentService
            }

            It "Should return the site data from the get method" {
                $result = Get-TargetResource @testParams
                $result.OwnerAlias | Should Be "DEMO\owner"
                $result.SecondaryOwnerAlias | Should Be "DEMO\SecondOwner"
                $result.QuotaTemplate | Should Be "WrongTemplate"
                $result.AdministrationSiteType | Should Be "None"
            }

            It "Should update owner and quota in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPSite
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "The site exists and is a host named site collection" -Fixture {
            $testParams = @{
                Url        = "http://site.sharepoint.com"
                OwnerAlias = "DEMO\owner"
            }

            $contextSiteImplementation = {
                $site = $siteImplementation.InvokeReturnAsIs()
                $site.RootWeb.AssociatedVisitorGroup = "Test Visitors"
                $site.RootWeb.AssociatedMemberGroup = "Test Members"
                $site.RootWeb.AssociatedOwnerGroup = "Test Owners"

                $site.WebApplication.Url = $testParams.Url
                $site.WebApplication.UseClaimsAuthentication = $false
                $site.HostHeaderIsSiteName = $true
                $site.Url = $testParams.Url
                $site.Owner = @{ UserLogin = "DEMO\owner" }
                return $site;
            }

            Mock -CommandName New-Object -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSystemAccountSite = $site
                return $site
            } -ParameterFilter {
                $TypeName -eq "Microsoft.SharePoint.SPSite" -and
                $ArgumentList[0] -eq $testParams.Url -and
                $ArgumentList[1] -eq "CentralAdminSystemAccountUserToken"
            }

            Mock -CommandName Get-SPSite -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSite = $site
                return $site
            }

            It "Should return the site data from the get method" {
                (Get-TargetResource @testParams).OwnerAlias | Should Be "DEMO\owner"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The site exists, but doesn't have default groups configured" -Fixture {
            $testParams = @{
                Url        = "http://site.sharepoint.com"
                OwnerAlias = "DEMO\User"
            }

            Mock -CommandName Get-SPSite -MockWith {
                $site = $siteImplementation.InvokeReturnAsIs()
                $site.RootWeb.AssociatedVisitorGroup = $null
                $site.RootWeb.AssociatedMemberGroup = $null
                $site.RootWeb.AssociatedOwnerGroup = $null

                $site.WebApplication.Url = $testParams.Url
                $site.Url = $testParams.Url
                return $site
            }

            Mock -CommandName New-SPClaimsPrincipal -MockWith {
                return @{
                    Value = $testParams.OwnerAlias
                }
            }

            It "Should return CreateDefaultGroups=False from the get method" {
                (Get-TargetResource @testParams).CreateDefaultGroups | Should Be $false
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the groups in the set method" {
                Set-TargetResource @testParams
                $Script:SPDscSystemAccountSite.RootWeb.CreateDefaultAssociatedGroupsCalled | Should Be $true
            }
        }

        Context -Name "The site exists and uses claims authentication" -Fixture {
            $testParams = @{
                Url        = "http://site.sharepoint.com"
                OwnerAlias = "DEMO\User"
            }

            $contextSiteImplementation = {
                $site = $siteImplementation.InvokeReturnAsIs()
                $site.RootWeb.AssociatedVisitorGroup = "Test Visitors"
                $site.RootWeb.AssociatedMemberGroup = "Test Members"
                $site.RootWeb.AssociatedOwnerGroup = "Test Owners"

                $site.WebApplication.Url = $testParams.Url
                $site.WebApplication.UseClaimsAuthentication = $true
                $site.HostHeaderIsSiteName = $false
                $site.Url = $testParams.Url
                $site.Owner = @{ UserLogin = "DEMO\owner" }
                $site.Quota = @{ QuotaId = 65000 }
                return $site;
            }

            Mock -CommandName New-Object -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSystemAccountSite = $site
                return $site
            } -ParameterFilter {
                $TypeName -eq "Microsoft.SharePoint.SPSite" -and
                $ArgumentList[0] -eq $testParams.Url -and
                $ArgumentList[1] -eq "CentralAdminSystemAccountUserToken"
            }

            Mock -CommandName Get-SPSite -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSite = $site
                return $site
            }

            Mock -CommandName New-SPClaimsPrincipal -MockWith {
                return @{
                    Value = $testParams.OwnerAlias
                }
            }

            It "Should return the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock -CommandName New-Object -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $site.Owner = $null
                $Script:SPDscSystemAccountSite = $site
                return $site
            } -ParameterFilter {
                $TypeName -eq "Microsoft.SharePoint.SPSite" -and
                $ArgumentList[0] -eq $testParams.Url -and
                $ArgumentList[1] -eq "CentralAdminSystemAccountUserToken"
            }

            It "Should return the site data from the get method where a valid site collection admin does not exist" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            Mock -CommandName New-Object -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $site.Owner = @{ UserLogin = "DEMO\owner" }
                $site.SecondaryContact = @{ UserLogin = "DEMO\secondary" }
                $Script:SPDscSystemAccountSite = $site
                return $site
            } -ParameterFilter {
                $TypeName -eq "Microsoft.SharePoint.SPSite" -and
                $ArgumentList[0] -eq $testParams.Url -and
                $ArgumentList[1] -eq "CentralAdminSystemAccountUserToken"
            }

            It "Should return the site data from the get method where a secondary site contact exists" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
        }

        Context -Name "The site exists and uses classic authentication" -Fixture {
            $testParams = @{
                Url        = "http://site.sharepoint.com"
                OwnerAlias = "DEMO\owner"
            }

            $contextSiteImplementation = {
                $site = $siteImplementation.InvokeReturnAsIs()
                $site.RootWeb.AssociatedVisitorGroup = "Test Visitors"
                $site.RootWeb.AssociatedMemberGroup = "Test Members"
                $site.RootWeb.AssociatedOwnerGroup = "Test Owners"

                $site.WebApplication.Url = $testParams.Url
                $site.WebApplication.UseClaimsAuthentication = $false
                $site.HostHeaderIsSiteName = $false
                $site.Url = $testParams.Url
                $site.Owner = @{ UserLogin = "DEMO\owner" }
                $site.Quota = @{ QuotaId = 65000 }
                return $site;
            }

            Mock -CommandName New-Object -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSystemAccountSite = $site
                return $site
            } -ParameterFilter {
                $TypeName -eq "Microsoft.SharePoint.SPSite" -and
                $ArgumentList[0] -eq $testParams.Url -and
                $ArgumentList[1] -eq "CentralAdminSystemAccountUserToken"
            }

            Mock -CommandName Get-SPSite -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSite = $site
                return $site
            }

            It "Should return the site data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock -CommandName Get-SPSite -MockWith {
                return @{
                    HostHeaderIsSiteName = $false
                    WebApplication       = @{
                        Url                     = $testParams.Url
                        UseClaimsAuthentication = $false
                    }
                    Url                  = $testParams.Url
                    Owner                = @{ UserLogin = "DEMO\owner" }
                    SecondaryContact     = @{ UserLogin = "DEMO\secondary" }
                    Quota                = @{ QuotaId = 65000 }
                }
            }

            It "Should return the site data from the get method where a secondary site contact exists" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }
        }

        Context -Name "CreateDefaultGroups is set to false, don't correct anything" -Fixture {
            $testParams = @{
                Url                 = "http://site.sharepoint.com"
                OwnerAlias          = "DEMO\owner"
                CreateDefaultGroups = $false
            }

            $contextSiteImplementation = {
                $site = $siteImplementation.InvokeReturnAsIs()
                $site.RootWeb.AssociatedVisitorGroup = $null
                $site.RootWeb.AssociatedMemberGroup = $null
                $site.RootWeb.AssociatedOwnerGroup = $null

                $site.WebApplication.Url = $testParams.Url
                $site.WebApplication.UseClaimsAuthentication = $false
                $site.HostHeaderIsSiteName = $false
                $site.Url = $testParams.Url
                $site.Owner = @{ UserLogin = "DEMO\owner" }
                $site.Quota = @{ QuotaId = 65000 }
                return $site;
            }

            Mock -CommandName New-Object -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSystemAccountSite = $site
                return $site
            } -ParameterFilter {
                $TypeName -eq "Microsoft.SharePoint.SPSite" -and
                $ArgumentList[0] -eq $testParams.Url -and
                $ArgumentList[1] -eq "CentralAdminSystemAccountUserToken"
            }

            Mock -CommandName Get-SPSite -MockWith {
                $site = $contextSiteImplementation.InvokeReturnAsIs()
                $Script:SPDscSite = $site
                return $site
            }

            It "Should return CreateDefaultGroups=False from the get method" {
                (Get-TargetResource @testParams).CreateDefaultGroups | Should Be $false
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
