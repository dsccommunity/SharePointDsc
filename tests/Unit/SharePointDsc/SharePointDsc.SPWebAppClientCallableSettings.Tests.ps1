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
    -DscResource "SPWebAppClientCallableSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        try
        {
            [Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary]
        }
        catch
        {
            Add-Type -TypeDefinition @"
namespace Microsoft.SharePoint.Administration {
    public class SPClientCallableProxyLibrary {
        public SPClientCallableProxyLibrary()
        {
        }
        public string AssemblyName { get; set; }
        public bool SupportAppAuthentication { get; set; }
    }
}
"@
        }

        # Mocks for all contexts

        $webAppImplementation = {
            $clientCallableSettings = [PSCustomObject] @{
                ProxyLibraries                     = [System.Collections.ObjectModel.Collection[Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary]]@()
                MaxResourcesPerRequest             = 16
                MaxObjectPaths                     = 256
                ExecutionTimeout                   = [System.TimeSpan]::FromMinutes(90);
                RequestXmlMaxDepth                 = 32
                EnableXsdValidation                = $true
                EnableStackTrace                   = $false
                RequestUsageExecutionTimeThreshold = 800
                EnableRequestUsage                 = $true
                LogActionsIfHasRequestException    = $true
            }

            $webApp = @{
                ClientCallableSettings = $clientCallableSettings
                UpdateCalled           = $false
            }

            $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                $this.UpdateCalled = $true
            }
            return $webApp
        }

        # Test contexts
        Context -Name "Client callable settings and a specific proxy library list matches current state" -Fixture {
            $testParams = @{
                WebAppUrl                          = "http://sites.sharepoint.com"
                ProxyLibraries                     = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
                MaxResourcesPerRequest             = 16
                MaxObjectPaths                     = 256
                ExecutionTimeout                   = 90
                RequestXmlMaxDepth                 = 32
                EnableXsdValidation                = $true
                EnableStackTrace                   = $false
                RequestUsageExecutionTimeThreshold = 800
                EnableRequestUsage                 = $true
                LogActionsIfHasRequestException    = $true
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary.AssemblyName = "Assembly"
                $testProxyLibrary.SupportAppAuthentication = $true

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary);
                $webApp.ClientCallableSettings.MaxResourcesPerRequest = 16;
                $webApp.ClientCallableSettings.MaxObjectPaths = 256;
                $webApp.ClientCallableSettings.ExecutionTimeout = [System.TimeSpan]::FromMinutes(90);
                $webApp.ClientCallableSettings.RequestXmlMaxDepth = 32;
                $webApp.ClientCallableSettings.EnableXsdValidation = $true;
                $webApp.ClientCallableSettings.EnableStackTrace = $false;
                $webApp.ClientCallableSettings.RequestUsageExecutionTimeThreshold = 800;
                $webApp.ClientCallableSettings.EnableRequestUsage = $true;
                $webApp.ClientCallableSettings.LogActionsIfHasRequestException = $true;

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return the current data from the get method" {
                $result = Get-TargetResource @testParams
                $result.WebAppUrl | Should Be "http://sites.sharepoint.com"
                $result.MaxResourcesPerRequest | Should Be 16
                $result.MaxObjectPaths | Should Be 256
                $result.ExecutionTimeout | Should Be 90
                $result.RequestXmlMaxDepth | Should Be 32
                $result.EnableXsdValidation | Should Be $true
                $result.EnableStackTrace | Should Be $false
                $result.RequestUsageExecutionTimeThreshold | Should Be 800
                $result.EnableRequestUsage | Should Be $true
                $result.LogActionsIfHasRequestException | Should Be $true
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should not call web application update from the set method" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $false
            }
        }

        Context -Name "Client callable settings does not match the current state" -Fixture {
            $testParams = @{
                WebAppUrl                          = "http://sites.sharepoint.com"
                MaxResourcesPerRequest             = 8
                MaxObjectPaths                     = 128
                ExecutionTimeout                   = 45
                RequestXmlMaxDepth                 = 16
                EnableXsdValidation                = $false
                EnableStackTrace                   = $true
                RequestUsageExecutionTimeThreshold = 400
                EnableRequestUsage                 = $false
                LogActionsIfHasRequestException    = $false
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.MaxResourcesPerRequest = 16;
                $webApp.ClientCallableSettings.MaxObjectPaths = 256;
                $webApp.ClientCallableSettings.ExecutionTimeout = [System.TimeSpan]::FromMinutes(90);
                $webApp.ClientCallableSettings.RequestXmlMaxDepth = 32;
                $webApp.ClientCallableSettings.EnableXsdValidation = $true;
                $webApp.ClientCallableSettings.EnableStackTrace = $false;
                $webApp.ClientCallableSettings.RequestUsageExecutionTimeThreshold = 800;
                $webApp.ClientCallableSettings.EnableRequestUsage = $true;
                $webApp.ClientCallableSettings.LogActionsIfHasRequestException = $true;

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return the current data from the get method" {
                $result = Get-TargetResource @testParams
                $result.WebAppUrl | Should Be "http://sites.sharepoint.com"
                $result.MaxResourcesPerRequest | Should Be 16
                $result.MaxObjectPaths | Should Be 256
                $result.ExecutionTimeout | Should Be 90
                $result.RequestXmlMaxDepth | Should Be 32
                $result.EnableXsdValidation | Should Be $true
                $result.EnableStackTrace | Should Be $false
                $result.RequestUsageExecutionTimeThreshold | Should Be 800
                $result.EnableRequestUsage | Should Be $true
                $result.LogActionsIfHasRequestException | Should Be $true
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call web application update from the set method, and set expected values" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 0
                $Script:SPDscWebApplication.ClientCallableSettings.MaxResourcesPerRequest | Should Be 8
                $Script:SPDscWebApplication.ClientCallableSettings.MaxObjectPaths | Should Be 128
                $Script:SPDscWebApplication.ClientCallableSettings.ExecutionTimeout.TotalMinutes | Should Be 45
                $Script:SPDscWebApplication.ClientCallableSettings.RequestXmlMaxDepth | Should Be 16
                $Script:SPDscWebApplication.ClientCallableSettings.EnableXsdValidation | Should Be $false
                $Script:SPDscWebApplication.ClientCallableSettings.EnableStackTrace | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.RequestUsageExecutionTimeThreshold | Should Be 400
                $Script:SPDscWebApplication.ClientCallableSettings.EnableRequestUsage | Should Be $false
                $Script:SPDscWebApplication.ClientCallableSettings.LogActionsIfHasRequestException | Should Be $false
            }
        }

        Context -Name "A proxy library does not match the current state" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sites.sharepoint.com"
                ProxyLibraries = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary.AssemblyName = "Assembly"
                $testProxyLibrary.SupportAppAuthentication = $false

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call web application update from the set method, and set expected values" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
            }
        }

        Context -Name "A proxy library to include does not match the current state" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibrariesToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary.AssemblyName = "Assembly"
                $testProxyLibrary.SupportAppAuthentication = $false

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call web application update from the set method, and set expected values" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
            }
        }

        Context -Name "Proxy libraries does not match the current state" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sites.sharepoint.com"
                ProxyLibraries = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "NewAssembly"
                            SupportAppAuthentication = $true
                        })
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary.AssemblyName = "Assembly"
                $testProxyLibrary.SupportAppAuthentication = $false

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call web application update from the set method, and set expected values" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "NewAssembly"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
            }
        }

        Context -Name "Multiple proxy libraries matches the current state" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sites.sharepoint.com"
                ProxyLibraries = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly1"
                            SupportAppAuthentication = $true
                        }),
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly2"
                            SupportAppAuthentication = $true
                        })
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary1 = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary1.AssemblyName = "Assembly1"
                $testProxyLibrary1.SupportAppAuthentication = $true
                $testProxyLibrary2 = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary2.AssemblyName = "Assembly2"
                $testProxyLibrary2.SupportAppAuthentication = $true

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary2)
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary1)

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should not call web application update from the set method" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $false
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 2
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly2"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[1].AssemblyName | Should Be "Assembly1"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[1].SupportAppAuthentication | Should Be $true
            }
        }

        Context -Name "Proxy libraries to include does not match the current state" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibrariesToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "NewAssembly"
                            SupportAppAuthentication = $true
                        })
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary.AssemblyName = "Assembly"
                $testProxyLibrary.SupportAppAuthentication = $true

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call web application update from the set method, and set expected values" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 2
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[1].AssemblyName | Should Be "NewAssembly"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[1].SupportAppAuthentication | Should Be $true
            }
        }

        Context -Name "Proxy library to include matches the current state" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibrariesToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary.AssemblyName = "Assembly"
                $testProxyLibrary.SupportAppAuthentication = $true

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should not call web application update from the set method, proxy libraries should not change" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $false
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "Assembly"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
            }
        }

        Context -Name "A proxy library to exclude does not match the current state" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibrariesToExclude = @("Assembly")
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary.AssemblyName = "Assembly"
                $testProxyLibrary.SupportAppAuthentication = $false

                $testProxyLibrary2 = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary2.AssemblyName = "AnotherAssembly"
                $testProxyLibrary2.SupportAppAuthentication = $false

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary2)

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call web application update from the set method, and set expected values" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "AnotherAssembly"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $false
            }
        }

        Context -Name "Proxy library to exclude matches the current state" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibrariesToExclude = @("Assembly")
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary.AssemblyName = "AnotherAssembly"
                $testProxyLibrary.SupportAppAuthentication = $true

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should not call web application update from the set method, proxy libraries should not change" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $false
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 1
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].AssemblyName | Should Be "AnotherAssembly"
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries[0].SupportAppAuthentication | Should Be $true
            }
        }

        Context -Name "Proxy libraries does not match the current state of empty proxy libraries" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sites.sharepoint.com"
                ProxyLibraries = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                return $webApp
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Empty proxy libraries matches the current state of empty proxy libraries" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sites.sharepoint.com"
                ProxyLibraries = @()
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                return $webApp
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Empty proxy libraries does not match the current state" -Fixture {
            $testParams = @{
                WebAppUrl      = "http://sites.sharepoint.com"
                ProxyLibraries = @()
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $testProxyLibrary = New-Object Microsoft.SharePoint.Administration.SPClientCallableProxyLibrary
                $testProxyLibrary.AssemblyName = "Assembly"
                $testProxyLibrary.SupportAppAuthentication = $true

                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                $webApp.ClientCallableSettings.ProxyLibraries.Add($testProxyLibrary)

                $Script:SPDscWebApplication = $webApp
                return($webApp)
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call web application update from the set method and update proxy libraries" {
                Set-TargetResource @testParams
                $Script:SPDscWebApplication.UpdateCalled | Should Be $true
                $Script:SPDscWebApplication.ClientCallableSettings.ProxyLibraries.Count | Should Be 0
            }
        }

        Context -Name "Proxy libraries to include does not match the current state of empty proxy libraries" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibrariesToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                return $webApp
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Proxy libraries to exclude matches the current state of empty proxy libraries" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibrariesToExclude = @("Assembly")
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $webApp = $webAppImplementation.Invoke()
                $webApp.ClientCallableSettings.ProxyLibraries.Clear();
                return $webApp
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "ProxyLibraries and ProxyLibrariesToInclude properties are provided" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibraries          = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
                ProxyLibrariesToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                return $webAppImplementation.Invoke()
            }

            It "Should throw an exception from the get method" {
                { Get-TargetResource @testParams } | Should Throw
            }

            It "Should throw an exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw
            }

            It "Should throw an exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context -Name "ProxyLibraries and ProxyLibrariesToExclude properties are provided" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibraries          = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
                ProxyLibrariesToExclude = @("Assembly")
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                return $webAppImplementation.Invoke()
            }

            It "Should throw an exception from the get method" {
                { Get-TargetResource @testParams } | Should Throw
            }

            It "Should throw an exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw
            }

            It "Should throw an exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context -Name "All of the proxy libraries properties are provided" -Fixture {
            $testParams = @{
                WebAppUrl               = "http://sites.sharepoint.com"
                ProxyLibraries          = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
                ProxyLibrariesToInclude = @(
                    (New-CimInstance -ClassName "MSFT_SPProxyLibraryEntry" `
                            -ClientOnly `
                            -Property @{
                            AssemblyName             = "Assembly"
                            SupportAppAuthentication = $true
                        })
                )
                ProxyLibrariesToExclude = @("Assembly")
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                return $webAppImplementation.Invoke()
            }

            It "Should throw an exception from the get method" {
                { Get-TargetResource @testParams } | Should Throw
            }

            It "Should throw an exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw
            }

            It "Should throw an exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context -Name "The web appliation does not exist" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sites.sharepoint.com"
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                return $null
            }

            It "Should return a valid object with null on all properties" {
                $result = Get-TargetResource @testParams
                $result | Should Not BeNullOrEmpty
                $result.WebAppUrl | Should Be $null
                $result.ProxyLibraries | Should Be $null
                $result.ProxyLibrariesToInclude | Should Be $null
                $result.ProxyLibrariesToExclude | Should Be $null
                $result.MaxResourcesPerRequest | Should Be $null
                $result.MaxObjectPaths | Should Be $null
                $result.ExecutionTimeout | Should Be $null
                $result.RequestXmlMaxDepth | Should Be $null
                $result.EnableXsdValidation | Should Be $null
                $result.EnableStackTrace | Should Be $null
                $result.RequestUsageExecutionTimeThreshold | Should Be $null
                $result.EnableRequestUsage | Should Be $null
                $result.LogActionsIfHasRequestException | Should Be $null
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
