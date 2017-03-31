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
                                              -DscResource "SPAppPrincipal"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        #Uses Managed Code, have to Add Types here.
try 
{
        Add-Type -TypeDefinition @"
namespace Microsoft.SharePoint {
    
    public class SPAppPrincipalIdentityProvider {
      
        public static SPAppPrincipalIdentityProvider External { get { return new SPAppPrincipalIdentityProvider(); } }
    
    }

    public class SPAppPrincipalName {
    
        public SPAppPrincipalName(string identifier) {

        }
        
        public static SPAppPrincipalName CreateFromAppPrincipalIdentifier(string identifier) {
            return new SPAppPrincipalName(identifier);
        }
    }

    public class SPAppPrincipal {
        public SPAppPrincipal(SPAppPrincipalIdentityProvider provider, SPAppPrincipalName name) {

        }
    }

    public class SPAppPrincipalManager { 
    
        public SPAppPrincipalManager(object site) {

        }

        public static SPAppPrincipalManager GetManager(object site) 
        {
            return new SPAppPrincipalManager(site);
        }

        public void DeleteAppPrincipal(SPAppPrincipal principal) { }

        public SPAppPrincipal LookupAppPrincipal(SPAppPrincipalIdentityProvider provider, SPAppPrincipalName name) {
            return new SPAppPrincipal(provider, name);
        }
    }
}
"@ 
}
catch
{
    $_
}
        # Mocks for all contexts
        Mock -CommandName Register-SPAppPrincipal -MockWith { }
        # Test contexts 
        
        Context -Name "The specified site does not exist" -Fixture {
            $testParams = @{
                DisplayName = "Contoso App Principal"
                AppId       = "40c0ab1a-6cbc-4bfa-a84e-940356d76c28"
                Site        = "http://site.sharepoint.com"
                Right       = "Full Control"
                Scope       = "Site"
                Ensure      = "Present"
            }

            Mock -CommandName Get-SPSite -MockWith { 
                return $null
            }

            Mock -CommandName Get-SPAuthenticationRealm {
                return "226c3c17-e683-48e9-a66e-f90d1836affd"
            }

            It "Should throw exception from the get method" {
                { Get-TargetResource @testParams }| Should Throw "The specified site: $($testParams.Site) was not found"
            }

            It "Should throw exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw "The specified site: $($testParams.Site) was not found"
            }

            It "Should throw exception the set method " {
                { Set-TargetResource @testParams } | Should Throw "The specified site: $($testParams.Site) was not found"
            }

        }

        Context -Name "The App Principal exists and should exist." -Fixture {
           $testParams = @{
                DisplayName = "Contoso App Principal"
                AppId       = "40c0ab1a-6cbc-4bfa-a84e-940356d76c28"
                Site        = "http://site.sharepoint.com"
                Right       = "Full Control"
                Scope       = "Site"
                Ensure      = "Present"
            }

            Mock -CommandName Get-SPSite -MockWith { 
                $spSite = [PSCustomObject]@{ 
                                    DisplayName = "SharePoint Site"
                                   
                } 
                $spSite | Add-Member -MemberType ScriptMethod `
                                           -Name OpenWeb `
                                           -Value {  
                                                return @{ 
                                                    Title = "SharePoint Web" 
                                                }  
                                            } -PassThru -Force 
                return @($spSite) 
            }

            Mock -CommandName Get-SPAuthenticationRealm -MockWith  {
                return "226c3c17-e683-48e9-a66e-f90d1836affd"
            }  

            Mock -CommandName Get-SPAppPrincipal -MockWith {
                return @{
                    DisplayName = $testParams.DisplayName
                    ApplicationId = $testParams.AppId
                    Site = $testParams.Site
                    Right = $testParams.Right
                    Scope = $testParams.Scope
                    Ensure = $testParams.Ensure
                }
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The App Principal exists and shouldn't exist." -Fixture {
           $testParams = @{
                DisplayName = "Contoso App Principal"
                AppId       = "40c0ab1a-6cbc-4bfa-a84e-940356d76c28"
                Site        = "http://site.sharepoint.com"
                Right       = "Full Control"
                Scope       = "Site"
                Ensure      = "Absent"
            }

             Mock -CommandName Get-SPSite -MockWith { 
                $spSite = [PSCustomObject]@{ 
                                    DisplayName = "SharePoint Site"
                                   
                } 
                $spSite | Add-Member -MemberType ScriptMethod `
                                           -Name OpenWeb `
                                           -Value {  
                                                return @{ 
                                                    Title = "SharePoint Web" 
                                                }  
                                            } -PassThru -Force 
                return @($spSite) 
            }

            Mock -CommandName Get-SPAuthenticationRealm -MockWith  {
                return "226c3c17-e683-48e9-a66e-f90d1836affd"
            }  

            Mock -CommandName Get-SPAppPrincipal -MockWith {
                return @{
                    DisplayName = $testParams.DisplayName
                    ApplicationId = "$($testParams.AppId)@226c3c17-e683-48e9-a66e-f90d1836affd"
                    Site = "http://site.sharepoint.com"
                    Ensure = "Present"
                }
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should do somethign from the set method" {
                Set-TargetResource @testParams
            }
        }

          Context -Name "The App Principal doesn't exists and should exist but site is null" -Fixture {
           $testParams = @{
                DisplayName = "Contoso App Principal"
                AppId       = "40c0ab1a-6cbc-4bfa-a84e-940356d76c28"
                Site        = "http://site.sharepoint.com"
                Right       = "Full Control"
                Scope       = "Site"
                Ensure      = "Present"
            }

            Mock -CommandName Get-SPSite -MockWith { 
                return $null
            }

            Mock -CommandName Get-SPAuthenticationRealm -MockWith  {
                return "226c3c17-e683-48e9-a66e-f90d1836affd"
            }  

            Mock -CommandName Get-SPAppPrincipal -MockWith {
                return $null
            }

            It "Should throw exception from the get method" {
                { Get-TargetResource @testParams }| Should Throw "The specified site: $($testParams.Site) was not found"
            }

            It "Should throw exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw "The specified site: $($testParams.Site) was not found"
            }

            It "Should throw exception the set method " {
                { Set-TargetResource @testParams } | Should Throw "The specified site: $($testParams.Site) was not found"
            }
        }


        Context -Name "The App Principal doesn't exists and should exist." -Fixture {
           $testParams = @{
                DisplayName = "Contoso App Principal"
                AppId       = "40c0ab1a-6cbc-4bfa-a84e-940356d76c28"
                Site        = "http://site.sharepoint.com"
                Right       = "Full Control"
                Scope       = "Site"
                Ensure      = "Present"
            }

             Mock -CommandName Get-SPSite -MockWith { 
                $spSite = [PSCustomObject]@{ 
                                    DisplayName = "SharePoint Site"
                                   
                } 
                $spSite | Add-Member -MemberType ScriptMethod `
                                           -Name OpenWeb `
                                           -Value {  
                                                return @{ 
                                                    Title = "SharePoint Web" 
                                                }  
                                            } -PassThru -Force 
                return @($spSite) 
            }

            Mock -CommandName Get-SPAuthenticationRealm -MockWith  {
                return "226c3c17-e683-48e9-a66e-f90d1836affd"
            }  

            Mock -CommandName Get-SPAppPrincipal -MockWith {
                return $null
            }

            It "Should return Ensure is Absent value from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create the App principal in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName Get-SPAppPrincipal -Times 1
                Assert-MockCalled -CommandName Register-SPAppPrincipal -Times 1
            }
        }

        Context -Name "The App Principal doesn't exists and shouldn't exist." -Fixture {
           $testParams = @{
                DisplayName = "Contoso App Principal"
                AppId       = "40c0ab1a-6cbc-4bfa-a84e-940356d76c28"
                Site        = "http://site.sharepoint.com"
                Right       = "Full Control"
                Scope       = "Site"
                Ensure      = "Absent"
            }

             Mock -CommandName Get-SPSite -MockWith { 
                $spSite = [PSCustomObject]@{ 
                                    DisplayName = "SharePoint Site"
                                   
                } 
                $spSite | Add-Member -MemberType ScriptMethod `
                                           -Name OpenWeb `
                                           -Value {  
                                                return @{ 
                                                    Title = "SharePoint Web" 
                                                }  
                                            } -PassThru -Force 
                return @($spSite) 
            }

            Mock -CommandName Get-SPAuthenticationRealm -MockWith  {
                return "226c3c17-e683-48e9-a66e-f90d1836affd"
            }  

            Mock -CommandName Get-SPAppPrincipal -MockWith {
                return $null
            }

            It "Should return Ensure is Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }


        }
      
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
