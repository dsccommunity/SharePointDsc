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
                                              -DscResource "SPWebAppSuiteBar"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts

        # Test contexts

        Context -Name "Web application does not exist" -Fixture {
            $testParams = @{
                WebAppUrl = "http://sites.sharepoint.com"
                SuiteBarBrandingElementHtml = "<div>Test</div>"
            }

            Mock -CommandName Get-SPWebApplication -MockWith {
                return $null
            }

            It "Get target resource returns null value" {
                $returnValue = Get-TargetResource @testParams
                $returnValue | Should Not Be $null
                $returnValue.WebAppUrl | Should Be $null
                $returnValue.SuiteNavBrandingLogoNavigationUrl | Should Be $null
                $returnValue.SuiteNavBrandingLogoTitle | Should Be $null
                $returnValue.SuiteNavBrandingLogoUrl | Should Be $null
                $returnValue.SuiteNavBrandingText | Should Be $null
                $returnValue.SuiteBarBrandingElementHtml | Should Be $null
            }
        }

        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
        {
            Context -Name "Only all SP2016 parameters passed for a SP2013 environment" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "LogoTitle"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                }

                Mock -CommandName Get-SPWebApplication -MockWith {return @(@{
                    DisplayName = "Test Web App"
                    Url = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                })}

                It "return error that invalid sp2013 parameters were passed" {
                    { Set-TargetResource @testParams } | Should Throw "Cannot specify SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl or SuiteNavBrandingText with SharePoint 2013. Instead, only specify the SuiteBarBrandingElementHtml parameter"
                }
            }

            Context -Name "Only some SP2016 parameters passed for a SP2013 environment" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingText = "Suite Bar Text"
                }

                Mock -CommandName Get-SPWebApplication -MockWith {return @(@{
                    DisplayName = "Test Web App"
                    Url = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                })}

                It "return error that invalid sp2013 parameters were passed" {
                    { Set-TargetResource @testParams } | Should Throw "Cannot specify SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl or SuiteNavBrandingText with SharePoint 2013. Instead, only specify the SuiteBarBrandingElementHtml parameter"
                }
            }

            Context -Name "Only the SP2013 parameter passed for a SP2013 environment" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    $webApp = @{
                        DisplayName = "Test Web App"
                        Url = "http://sites.sharepoint.com"
                        SuiteBarBrandingElementHtml = "<div>Test</div>"
                        SuiteNavBrandingLogoNavigationUrl = $null
                        SuiteNavBrandingLogoTitle = $null
                        SuiteNavBrandingLogoUrl = $null
                        SuiteNavBrandingText = $null
                    }
                    $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscWebApplicationUpdateCalled = $true
                    } -PassThru
                    return @($webApp)
                }

                It "successfully returns the suite bar branding html" {
                    $result = Get-TargetResource @testParams
                    $result.WebAppUrl | should be "http://sites.sharepoint.com"
                    $result.SuiteBarBrandingElementHtml | Should be "<div>Test</div>"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }

                It "Should properly configure the suite bar for the Web Application" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "None of the optional parameters passed" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    DisplayName = "Test Web App"
                    Url = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                }

                It "return error that sp2013 parameters are required" {
                    { Set-TargetResource @testParams } | Should Throw "You need to specify a value for the SuiteBarBrandingElementHtml parameter with SharePoint 2013"
                }
            }
            Context -Name "Configured values does not match" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                }

                Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                    DisplayName = "Test Web App"
                    Url = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Another Test</div>"
                })}

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
            }
        }
        elseif ($Global:SPDscHelper.CurrentStubBuildNumber.Major -ge 16)
        {
            Context -Name "Only all SP2016 parameters passed for a SP2016 environment" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "LogoTitle"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    $webApp = @{
                        DisplayName = "Test Web App"
                        Url = "http://sites.sharepoint.com"
                        SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                        SuiteNavBrandingLogoTitle = "LogoTitle"
                        SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                        SuiteNavBrandingText = "Suite Bar Text"
                        SuiteBarBrandingElementHtml = "<div>Test</div>"
                    }
                    $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscWebApplicationUpdateCalled = $true
                    } -PassThru
                    return @($webApp)
                }

                It "successfully returns the suite bar properties" {
                    $results = Get-TargetResource @testParams
                    $results.WebAppUrl | Should be "http://sites.sharepoint.com"
                    $results.SuiteNavBrandingLogoNavigationUrl | Should be "http://sites.sharepoint.com"
                    $results.SuiteNavBrandingLogoTitle | Should be "LogoTitle"
                    $results.SuiteNavBrandingLogoUrl | Should be "http://sites.sharepoint.com/images/logo.gif"
                    $results.SuiteNavBrandingText | Should be "Suite Bar Text"
                    $results.SuiteBarBrandingElementHtml | Should be "<div>Test</div>"
                }

                It "Should properly configure the suite bar for the Web Application" {
                    Set-TargetResource @testParams
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "Only some SP2016 parameters passed for a SP2016 environment" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingText = "Suite Bar Text"
                }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    $webApp = @{
                        DisplayName = "Test Web App"
                        Url = "http://sites.sharepoint.com"
                        SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                        SuiteNavBrandingLogoTitle = "LogoTitle"
                        SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                        SuiteNavBrandingText = "Suite Bar Text"
                        SuiteBarBrandingElementHtml = "<div>Test</div>"
                    }
                    $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscWebApplicationUpdateCalled = $true
                    } -PassThru
                    return @($webApp)
                }

                It "successfully returns the suite bar properties" {
                    $results = Get-TargetResource @testParams
                    $results.WebAppUrl | Should be "http://sites.sharepoint.com"
                    $results.SuiteNavBrandingLogoNavigationUrl | Should be "http://sites.sharepoint.com"
                    $results.SuiteNavBrandingLogoTitle | Should be "LogoTitle"
                    $results.SuiteNavBrandingLogoUrl | Should be "http://sites.sharepoint.com/images/logo.gif"
                    $results.SuiteNavBrandingText | Should be "Suite Bar Text"
                }

                It "Should properly configure the suite bar for the Web Application" {
                    Set-TargetResource @testParams
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "None of the optional parameters passed" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                }

                Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                    DisplayName = "Test Web App"
                    Url = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "LogoTitle"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                })}

                It "return error that sp2016/sp2019 parameters are required" {
                    { Set-TargetResource @testParams } | Should Throw "You need to specify a value for either SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl, SuiteNavBrandingText, and SuiteBarBrandingElementHtml with SharePoint 2016 or SharePoint 2019"
                }
            }

            Context -Name "Configured values does not match" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "LogoTitle"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                }

                Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                    DisplayName = "Test Web App"
                    Url = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://anothersite.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "AnotherLogoTitle"
                    SuiteNavBrandingLogoUrl = "http://anothersite.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Another Suite Bar Text"
                })}

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
