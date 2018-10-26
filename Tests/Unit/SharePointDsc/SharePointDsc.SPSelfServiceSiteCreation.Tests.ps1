[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)
Set-StrictMode -Version 2

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPSelfServiceSiteCreation"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts

        $webAppImplementation = {
            $webApp = @{
                Url = $null
                SelfServiceSiteCreationEnabled = $null
                SelfServiceSiteCreationOnlineEnabled = $null
                SelfServiceCreationQuotaTemplate = $null
                ShowStartASiteMenuItem = $null
                SelfServiceCreateIndividualSite = $null
                SelfServiceCreationParentSiteUrl = $null
                SelfServiceSiteCustomFormUrl = $null
                RequireContactForSelfServiceSiteCreation = $null
                Properties = @{}
                UpdateCalled = $false
            }

            $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                $this.UpdateCalled = $true
            }
            return $webApp
        }

        # Test contexts

        Context -Name "Self service site creation settings matches the current state" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sites.sharepoint.com"
                Enabled = $true
                OnlineEnabled = $false
                QuotaTemplate = "SSCQoutaTemplate"
                ShowStartASiteMenuItem = $true
                CreateIndividualSite = $false
                ParentSiteUrl = "/sites/SSC"
                CustomFormUrl = ""
                PolicyOption = "CanHavePolicy"
                RequireSecondaryContact = $true
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                $webApp = $webAppImplementation.InvokeReturnAsIs()
                $webApp.Url = "http://sites.sharepoint.com"
                $webApp.SelfServiceSiteCreationEnabled = $true
                $webApp.SelfServiceSiteCreationOnlineEnabled = $false
                $webApp.SelfServiceCreationQuotaTemplate = "SSCQoutaTemplate"
                $webApp.ShowStartASiteMenuItem = $true
                $webApp.SelfServiceCreateIndividualSite = $false
                $webApp.SelfServiceCreationParentSiteUrl = "/sites/SSC"
                $webApp.SelfServiceSiteCustomFormUrl = ""
                $webApp.RequireContactForSelfServiceSiteCreation = $true
                $webApp.Properties = @{
                    PolicyOption = "CanHavePolicy"
                }

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return the current data from the get method" {
                $result = Get-TargetResource @testParams
                $result.WebAppUrl | Should Be "http://sites.sharepoint.com"
                $result.Enabled | Should Be $true
                $result.OnlineEnabled | Should Be $false
                $result.QuotaTemplate | Should Be "SSCQoutaTemplate"
                $result.ShowStartASiteMenuItem | Should Be $true
                $result.CreateIndividualSite | Should Be $false
                $result.ParentSiteUrl | Should Be "/sites/SSC"
                $result.CustomFormUrl | Should Be ""
                $result.PolicyOption | Should Be "CanHavePolicy"
                $result.RequireSecondaryContact | Should Be $true
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should not call web application update from the set method" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $false
            }
        }

        Context -Name "Self service site creation settings does not matches the current state" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sites.sharepoint.com"
                Enabled = $true
                OnlineEnabled = $false
                QuotaTemplate = "SSCQoutaTemplate"
                ShowStartASiteMenuItem = $true
                CreateIndividualSite = $false
                ParentSiteUrl = "/sites/SSC"
                CustomFormUrl = "http://CustomForm.SharePoint.com"
                PolicyOption = "CanHavePolicy"
                RequireSecondaryContact = $true
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                $webApp = $webAppImplementation.InvokeReturnAsIs()
                $webApp.Url = "http://sites.sharepoint.com"

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call web application update from the set method" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
                $Script:SPDscWebApplication.SelfServiceSiteCreationEnabled | Should Be $true
                $Script:SPDscWebApplication.SelfServiceSiteCreationOnlineEnabled | Should Be $false
                $Script:SPDscWebApplication.SelfServiceCreationQuotaTemplate | Should Be "SSCQoutaTemplate"
                $Script:SPDscWebApplication.ShowStartASiteMenuItem | Should Be $true
                $Script:SPDscWebApplication.SelfServiceCreateIndividualSite | Should Be $false
                $Script:SPDscWebApplication.SelfServiceCreationParentSiteUrl | Should Be "/sites/SSC"
                $Script:SPDscWebApplication.SelfServiceSiteCustomFormUrl | Should Be "http://CustomForm.SharePoint.com"
                $Script:SPDscWebApplication.Properties["PolicyOption"] | Should Be "CanHavePolicy"
                $Script:SPDscWebApplication.RequireContactForSelfServiceSiteCreation | Should Be $true
            }
        }

        Context -Name "Disabling self service site creation does not match the current state" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sites.sharepoint.com"
                Enabled = $false
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                $webApp = $webAppImplementation.InvokeReturnAsIs()
                $webApp.Url = "http://sites.sharepoint.com"
                $webApp.SelfServiceSiteCreationEnabled = $true
                $webApp.SelfServiceSiteCreationOnlineEnabled = $false
                $webApp.SelfServiceCreationQuotaTemplate = "SSCQoutaTemplate"
                $webApp.ShowStartASiteMenuItem = $true
                $webApp.SelfServiceCreateIndividualSite = $false
                $webApp.SelfServiceCreationParentSiteUrl = "/sites/SSC"
                $webApp.SelfServiceSiteCustomFormUrl = ""
                $webApp.RequireContactForSelfServiceSiteCreation = $true
                $webApp.Properties = @{
                    PolicyOption = "CanHavePolicy"
                }

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call web application update from the set method and disable SSC and start a site link" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
                $Script:SPDscWebApplication.SelfServiceSiteCreationEnabled | Should Be $false
                $Script:SPDscWebApplication.ShowStartASiteMenuItem | Should Be $false
            }
        }

        Context -Name "Disabling self service site creation and enabling show start a site menu item" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sites.sharepoint.com"
                Enabled = $false
                ShowStartASiteMenuItem = $true
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                $webApp = $webAppImplementation.InvokeReturnAsIs()
                $webApp.Url = "http://sites.sharepoint.com"
                $webApp.SelfServiceSiteCreationEnabled = $true
                $webApp.SelfServiceSiteCreationOnlineEnabled = $false
                $webApp.SelfServiceCreationQuotaTemplate = "SSCQoutaTemplate"
                $webApp.ShowStartASiteMenuItem = $true
                $webApp.SelfServiceCreateIndividualSite = $false
                $webApp.SelfServiceCreationParentSiteUrl = "/sites/SSC"
                $webApp.SelfServiceSiteCustomFormUrl = ""
                $webApp.RequireContactForSelfServiceSiteCreation = $true
                $webApp.Properties = @{
                    PolicyOption = "CanHavePolicy"
                }

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should throw from the test method" {
                { Test-TargetResource @testParams } | Should Throw "It is not allowed to set the ShowStartASiteMenuItem to true when self service site creation is disabled."
            }

            It "Should throw from the update method" {
                { Set-TargetResource @testParams } | Should Throw "It is not allowed to set the ShowStartASiteMenuItem to true when self service site creation is disabled."
            }
        }

        Context -Name "Web application does not exist" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sites.sharepoint.com"
                Enabled = $true
                }

            Mock -CommandName Get-SPWebApplication -MockWith {
                return($null)
            }

            It "Should return a valid object with null on all properties" {
                $result = Get-TargetResource @testParams
                $result | Should Not BeNullOrEmpty
                $result.WebAppUrl | Should Be $null
                $result.Enabled | Should Be $null
                $result.OnlineEnabled | Should Be $null
                $result.QuotaTemplate | Should Be $null
                $result.ShowStartASiteMenuItem | Should Be $null
                $result.CreateIndividualSite | Should Be $null
                $result.ParentSiteUrl | Should Be $null
                $result.CustomFormUrl | Should Be $null
                $result.PolicyOption | Should Be $null
                $result.RequireSecondaryContact | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
