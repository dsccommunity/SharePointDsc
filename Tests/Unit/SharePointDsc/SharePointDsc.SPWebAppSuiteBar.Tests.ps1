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
                                              -DscResource "SPWebAppSuiteBar"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   

        # Test contexts
        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15) 
        {
            Context -Name "Only all SP2016 parameters passed for a SP2013 environment" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "LogoTitle"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                    Ensure = "Present"              
                }

                Mock -CommandName Get-SPWebApplication -MockWith { 
                    DisplayName = "Test Web App"                
                    Url = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                }

                It "return error that invalid sp2013 parameters were passed" {
                    { Set-TargetResource @testParams } | Should Throw "Cannot specify SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl or SuiteNavBrandingText whith SharePoint 2013. Instead, only specify the SuiteBarBrandingElementHtml parameter"
                }
            }

            Context -Name "Only some SP2016 parameters passed for a SP2013 environment" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingText = "Suite Bar Text"
                    Ensure = "Present"              
                }

                Mock -CommandName Get-SPWebApplication -MockWith { 
                    DisplayName = "Test Web App"                
                    Url = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                }

                It "return error that invalid sp2013 parameters were passed" {
                    { Set-TargetResource @testParams } | Should Throw "Cannot specify SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl or SuiteNavBrandingText whith SharePoint 2013. Instead, only specify the SuiteBarBrandingElementHtml parameter"
                }
            }

            Context -Name "Only the SP2013 parameter passed for a SP2013 environment" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                    Ensure = "Present"              
                }

                Mock -CommandName Get-SPWebApplication -MockWith { 
                    DisplayName = "Test Web App"                
                    Url = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                }

                It "successfully returns the suite bar branding html" {
                    $result = Get-TargetResource @testParams
                    $result.WebAppUrl | should be "http://sites.sharepoint.com"
                    $result.SuiteBarBrandingElementHtml | Should be "<div>Test</div>"
                    $result.SuiteNavBrandingLogoNavigationUrl | Should be $null
                    $result.SuiteNavBrandingLogoTitle | Should be $null
                    $result.SuiteNavBrandingLogoUrl | Should be $null
                    $result.SuiteNavBrandingText | Should be $null
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "None of the optional parameters passed" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    Ensure = "Present"              
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
                    Ensure = "Present"              
                }

                Mock -CommandName Get-SPWebApplication -MockWith { 
                    DisplayName = "Test Web App"                
                    Url = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "LogoTitle"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                }

                It "successfully returns the suite bar properties" {
                    $results = Get-TargetResource @testParams
                    $results.WebAppUrl | Should be "http://sites.sharepoint.com"
                    $results.SuiteNavBrandingLogoNavigationUrl | Should be "http://sites.sharepoint.com"
                    $results.SuiteNavBrandingLogoTitle | Should be "LogoTitle"
                    $results.SuiteNavBrandingLogoUrl | Should be "http://sites.sharepoint.com/images/logo.gif"
                    $results.SuiteNavBrandingText | Should be "Suite Bar Text"
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
                    Ensure = "Present"              
                }

                Mock -CommandName Get-SPWebApplication -MockWith { 
                    DisplayName = "Test Web App"                
                    Url = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "LogoTitle"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                }

                It "successfully returns the suite bar properties" {
                    $results = Get-TargetResource @testParams
                    $results.WebAppUrl | Should be "http://sites.sharepoint.com"
                    $results.SuiteNavBrandingLogoNavigationUrl | Should be "http://sites.sharepoint.com"
                    $results.SuiteNavBrandingLogoTitle | Should be "LogoTitle"
                    $results.SuiteNavBrandingLogoUrl | Should be "http://sites.sharepoint.com/images/logo.gif"
                    $results.SuiteNavBrandingText | Should be "Suite Bar Text"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "Only some SP2016 parameters passed along the SP2013 one for an SP2016 environment" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                    Ensure = "Present"              
                }

                Mock -CommandName Get-SPWebApplication -MockWith { 
                    DisplayName = "Test Web App"                
                    Url = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "LogoTitle"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                }

                It "return error that sp2013 parameter was passed for a sp2016 environment" {
                    { Set-TargetResource @testParams } | Should Throw "Cannot specify SuiteBarBrandingElementHtml whith SharePoint 2016. Instead, use the SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl and SuiteNavBrandingText parameters"
                }
            }

            Context -Name "None of the optional parameters passed" -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sites.sharepoint.com"
                    Ensure = "Present"              
                }

                Mock -CommandName Get-SPWebApplication -MockWith { 
                    DisplayName = "Test Web App"                
                    Url = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                    SuiteNavBrandingLogoTitle = "LogoTitle"
                    SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                    SuiteNavBrandingText = "Suite Bar Text"
                }

                It "return error that sp2016 parameters are required" {
                    { Set-TargetResource @testParams } | Should Throw "You need to specify a value for either SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl and SuiteNavBrandingText whith SharePoint 2016"
                }
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
