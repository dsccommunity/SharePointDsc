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
                Url = "http://sites.sharepoint.com"
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
                $result.Url | Should Be "http://sites.sharepoint.com"
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
                Url = "http://sites.sharepoint.com"
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
                Url = "http://sites.sharepoint.com"
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
                Url = "http://sites.sharepoint.com"
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
                Url = "http://sites.sharepoint.com"
                Enabled = $true
                }

            Mock -CommandName Get-SPWebApplication -MockWith {
                return($null)
            }

            It "Should return a valid object with null on all properties" {
                $result = Get-TargetResource @testParams
                $result | Should Not BeNullOrEmpty
                $result.Url | Should Be $null
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

#        Context -Name "Client callable settings does not match the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                MaxResourcesPerRequest = 8
#                MaxObjectPaths = 128
#                ExecutionTimeout = 45
#                RequestXmlMaxDepth = 16
#                EnableXsdValidation = $false
#                EnableStackTrace = $true
#                RequestUsageExecutionTimeThreshold = 400
#                EnableRequestUsage = $false
#                LogActionsIfHasRequestException = $false
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.MaxResourcesPerRequest = 16;
#                $webApp.ClientCallableSettings.MaxObjectPaths = 256;
#                $webApp.ClientCallableSettings.ExecutionTimeout = [System.TimeSpan]::FromMinutes(90);
#                $webApp.ClientCallableSettings.RequestXmlMaxDepth = 32;
#                $webApp.ClientCallableSettings.EnableXsdValidation = $true;
#                $webApp.ClientCallableSettings.EnableStackTrace = $false;
#                $webApp.ClientCallableSettings.RequestUsageExecutionTimeThreshold = 800;
#                $webApp.ClientCallableSettings.EnableRequestUsage = $true;
#                $webApp.ClientCallableSettings.LogActionsIfHasRequestException = $true;
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return the current data from the get method" {
#                $result = Get-TargetResource @testParams
#                $result.Url | Should Be "http://sites.sharepoint.com"
#                $result.MaxResourcesPerRequest | Should Be 16
#                $result.MaxObjectPaths | Should Be 256
#                $result.ExecutionTimeout | Should Be 90
#                $result.RequestXmlMaxDepth | Should Be 32
#                $result.EnableXsdValidation | Should Be $true
#                $result.EnableStackTrace | Should Be $false
#                $result.RequestUsageExecutionTimeThreshold | Should Be 800
#                $result.EnableRequestUsage | Should Be $true
#                $result.LogActionsIfHasRequestException | Should Be $true
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#
#            It "Should call web application update from the set method, and set expected values" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 0
#                $Script:SPDscWebApplication.ClientCallableSettings.MaxResourcesPerRequest | Should Be 8
#                $Script:SPDscWebApplication.ClientCallableSettings.MaxObjectPaths | Should Be 128
#                $Script:SPDscWebApplication.ClientCallableSettings.ExecutionTimeout.TotalMinutes | Should Be 45
#                $Script:SPDscWebApplication.ClientCallableSettings.RequestXmlMaxDepth | Should Be 16
#                $Script:SPDscWebApplication.ClientCallableSettings.EnableXsdValidation | Should Be $false
#                $Script:SPDscWebApplication.ClientCallableSettings.EnableStackTrace | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.RequestUsageExecutionTimeThreshold | Should Be 400
#                $Script:SPDscWebApplication.ClientCallableSettings.EnableRequestUsage | Should Be $false
#                $Script:SPDscWebApplication.ClientCallableSettings.LogActionsIfHasRequestException | Should Be $false
#            }
#        }
#
#        Context -Name "A proxy library does not match the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibraries = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary.AssemblyName = "Assembly"
#                $testProxyLibrary.SupportAppAuthentication = $false
#
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#
#            It "Should call web application update from the set method, and set expected values" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
#            }
#        }
#
#        Context -Name "A proxy library to include does not match the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibrariesToInclude = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary.AssemblyName = "Assembly"
#                $testProxyLibrary.SupportAppAuthentication = $false
#
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#
#            It "Should call web application update from the set method, and set expected values" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
#            }
#        }
#
#        Context -Name "Proxy libraries does not match the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibraries = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "NewAssembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary.AssemblyName = "Assembly"
#                $testProxyLibrary.SupportAppAuthentication = $false
#
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#
#            It "Should call web application update from the set method, and set expected values" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "NewAssembly"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
#            }
#        }
#
#        Context -Name "Multiple proxy libraries matches the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibraries = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly1"
#                        SupportAppAuthentication = $true
#                               }),
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly2"
#                        SupportAppAuthentication = $true
#                               })
#                )
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $testProxyLibrary1 = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary1.AssemblyName = "Assembly1"
#                $testProxyLibrary1.SupportAppAuthentication = $true
#                $testProxyLibrary2 = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary2.AssemblyName = "Assembly2"
#                $testProxyLibrary2.SupportAppAuthentication = $true
#
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary2)
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary1)
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $true
#            }
#
#            It "Should not call web application update from the set method" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $false
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 2
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly2"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[1].AssemblyName | Should Be "Assembly1"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[1].SupportAppAuthentication | Should Be $true
#            }
#        }
#
#        Context -Name "Proxy libraries to include does not match the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibrariesToInclude = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "NewAssembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary.AssemblyName = "Assembly"
#                $testProxyLibrary.SupportAppAuthentication = $true
#
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#
#            It "Should call web application update from the set method, and set expected values" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 2
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[1].AssemblyName | Should Be "NewAssembly"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[1].SupportAppAuthentication | Should Be $true
#            }
#        }
#
#        Context -Name "Proxy library to include matches the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibrariesToInclude = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary.AssemblyName = "Assembly"
#                $testProxyLibrary.SupportAppAuthentication = $true
#
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return true from the test method" {
#                Test-TargetResource @testParams | Should Be $true
#            }
#
#            It "Should not call web application update from the set method, proxy libraries should not change" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $false
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
#            }
#        }
#
#        Context -Name "A proxy library to exclude does not match the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibrariesToExclude = @("Assembly")
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary.AssemblyName = "Assembly"
#                $testProxyLibrary.SupportAppAuthentication = $false
#
#                $testProxyLibrary2 = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary2.AssemblyName = "AnotherAssembly"
#                $testProxyLibrary2.SupportAppAuthentication = $false
#
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary2)
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#
#            It "Should call web application update from the set method, and set expected values" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "AnotherAssembly"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $false
#            }
#        }
#
#        Context -Name "Proxy library to exclude matches the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibrariesToExclude = @("Assembly")
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary.AssemblyName = "AnotherAssembly"
#                $testProxyLibrary.SupportAppAuthentication = $true
#
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return true from the test method" {
#                Test-TargetResource @testParams | Should Be $true
#            }
#
#            It "Should not call web application update from the set method, proxy libraries should not change" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $false
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "AnotherAssembly"
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
#            }
#        }
#
#        Context -Name "Proxy libraries does not match the current state of empty proxy libraries" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibraries = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                return $webApp
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#        }
#
#        Context -Name "Empty proxy libraries matches the current state of empty proxy libraries" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibraries = @()
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                return $webApp
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $true
#            }
#        }
#
#        Context -Name "Empty proxy libraries does not match the current state" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibraries = @()
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
#                $testProxyLibrary.AssemblyName = "Assembly"
#                $testProxyLibrary.SupportAppAuthentication = $true
#
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)
#
#                $Script:SPDscWebApplication = $webApp
#                return($webApp)
#            }
#
#            It "Should return true from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#
#            It "Should call web application update from the set method and update proxy libraries" {
#                Set-TargetResource @testParams
#                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
#                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 0
#            }
#        }
#
#        Context -Name "Proxy libraries to include does not match the current state of empty proxy libraries" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibrariesToInclude = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                return $webApp
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#        }
#
#        Context -Name "Proxy libraries to exclude matches the current state of empty proxy libraries" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibrariesToExclude = @("Assembly")
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                $webApp = $webAppImplementation.Invoke()
#                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
#                return $webApp
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $true
#            }
#        }
#
#        Context -Name "ProxyLibraries and ProxyLibrariesToInclude properties are provided" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibraries = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#                ProxyLibrariesToInclude = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                return $webAppImplementation.Invoke()
#            }
#
#            It "Should throw an exception from the get method" {
#                { Get-TargetResource @testParams } | Should Throw
#            }
#
#            It "Should throw an exception from the test method" {
#                { Test-TargetResource @testParams } | Should Throw
#            }
#
#            It "Should throw an exception from the set method" {
#                { Set-TargetResource @testParams } | Should Throw
#            }
#        }
#
#        Context -Name "ProxyLibraries and ProxyLibrariesToExclude properties are provided" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibraries = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#                ProxyLibrariesToExclude = @("Assembly")
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                return $webAppImplementation.Invoke()
#            }
#
#            It "Should throw an exception from the get method" {
#                { Get-TargetResource @testParams } | Should Throw
#            }
#
#            It "Should throw an exception from the test method" {
#                { Test-TargetResource @testParams } | Should Throw
#            }
#
#            It "Should throw an exception from the set method" {
#                { Set-TargetResource @testParams } | Should Throw
#            }
#        }
#
#        Context -Name "All of the proxy libraries properties are provided" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#                ProxyLibraries = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#                ProxyLibrariesToInclude = @(
#                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
#                    -ClientOnly `
#                    -Property @{
#                        AssemblyName = "Assembly"
#                        SupportAppAuthentication = $true
#                               })
#                )
#                ProxyLibrariesToExclude = @("Assembly")
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                return $webAppImplementation.Invoke()
#            }
#
#            It "Should throw an exception from the get method" {
#                { Get-TargetResource @testParams } | Should Throw
#            }
#
#            It "Should throw an exception from the test method" {
#                { Test-TargetResource @testParams } | Should Throw
#            }
#
#            It "Should throw an exception from the set method" {
#                { Set-TargetResource @testParams } | Should Throw
#            }
#        }
#
#        Context -Name "The web appliation does not exist" -Fixture {
#            $testParams = @{
#                Url = "http://sites.sharepoint.com"
#            }
#
#            Mock -CommandName Get-SPWebapplication -MockWith {
#                return $null
#            }
#
#            It "Should return a valid object with null on all properties" {
#                $result = Get-TargetResource @testParams
#                $result | Should Not BeNullOrEmpty
#                $result.Url | Should Be $null
#                $result.ProxyLibraries | Should Be $null
#                $result.ProxyLibrariesToInclude | Should Be $null
#                $result.ProxyLibrariesToExclude | Should Be $null
#                $result.MaxResourcesPerRequest | Should Be $null
#                $result.MaxObjectPaths | Should Be $null
#                $result.ExecutionTimeout | Should Be $null
#                $result.RequestXmlMaxDepth | Should Be $null
#                $result.EnableXsdValidation | Should Be $null
#                $result.EnableStackTrace | Should Be $null
#                $result.RequestUsageExecutionTimeThreshold | Should Be $null
#                $result.EnableRequestUsage | Should Be $null
#                $result.LogActionsIfHasRequestException | Should Be $null
#            }
#
#            It "Should return false from the test method" {
#                Test-TargetResource @testParams | Should Be $false
#            }
#
#            It "Should throw an exception from the set method" {
#                { Set-TargetResource @testParams } | Should Throw
#            }
#        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope