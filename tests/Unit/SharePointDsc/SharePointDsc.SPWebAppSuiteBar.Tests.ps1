[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPWebAppSuiteBar'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Initialize tests

                # Mocks for all contexts
            }

            # Test contexts
            Context -Name "Web application does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                   = "http://sites.sharepoint.com"
                        SuiteBarBrandingElementHtml = "<div>Test</div>"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return $null
                    }
                }

                It "Get target resource returns null value" {
                    $returnValue = Get-TargetResource @testParams
                    $returnValue | Should -Not -Be $null
                    $returnValue.WebAppUrl | Should -Be $null
                    $returnValue.SuiteNavBrandingLogoNavigationUrl | Should -Be $null
                    $returnValue.SuiteNavBrandingLogoTitle | Should -Be $null
                    $returnValue.SuiteNavBrandingLogoUrl | Should -Be $null
                    $returnValue.SuiteNavBrandingText | Should -Be $null
                    $returnValue.SuiteBarBrandingElementHtml | Should -Be $null
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
            {
                Context -Name "Only all SP2016 parameters passed for a SP2013 environment" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            WebAppUrl                         = "http://sites.sharepoint.com"
                            SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                            SuiteNavBrandingLogoTitle         = "LogoTitle"
                            SuiteNavBrandingLogoUrl           = "http://sites.sharepoint.com/images/logo.gif"
                            SuiteNavBrandingText              = "Suite Bar Text"
                        }

                        Mock -CommandName Get-SPWebApplication -MockWith {
                            return @(@{
                                    DisplayName                 = "Test Web App"
                                    Url                         = "http://sites.sharepoint.com"
                                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                                })
                        }
                    }

                    It "return error that invalid sp2013 parameters were passed" {
                        { Set-TargetResource @testParams } | Should -Throw "Cannot specify SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl or SuiteNavBrandingText with SharePoint 2013. Instead, only specify the SuiteBarBrandingElementHtml parameter"
                    }
                }

                Context -Name "Only some SP2016 parameters passed for a SP2013 environment" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            WebAppUrl                         = "http://sites.sharepoint.com"
                            SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                            SuiteNavBrandingText              = "Suite Bar Text"
                        }

                        Mock -CommandName Get-SPWebApplication -MockWith {
                            return @(@{
                                    DisplayName                 = "Test Web App"
                                    Url                         = "http://sites.sharepoint.com"
                                    SuiteBarBrandingElementHtml = "<div>Test</div>"
                                })
                        }
                    }

                    It "return error that invalid sp2013 parameters were passed" {
                        { Set-TargetResource @testParams } | Should -Throw "Cannot specify SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl or SuiteNavBrandingText with SharePoint 2013. Instead, only specify the SuiteBarBrandingElementHtml parameter"
                    }
                }

                Context -Name "Only the SP2013 parameter passed for a SP2013 environment" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            WebAppUrl                   = "http://sites.sharepoint.com"
                            SuiteBarBrandingElementHtml = "<div>Test</div>"
                        }

                        Mock -CommandName Get-SPWebApplication -MockWith {
                            $webApp = @{
                                DisplayName                       = "Test Web App"
                                Url                               = "http://sites.sharepoint.com"
                                SuiteBarBrandingElementHtml       = "<div>Test</div>"
                                SuiteNavBrandingLogoNavigationUrl = $null
                                SuiteNavBrandingLogoTitle         = $null
                                SuiteNavBrandingLogoUrl           = $null
                                SuiteNavBrandingText              = $null
                            }
                            $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                                $Global:SPDscWebApplicationUpdateCalled = $true
                            } -PassThru
                            return @($webApp)
                        }
                    }

                    It "successfully returns the suite bar branding html" {
                        $result = Get-TargetResource @testParams
                        $result.WebAppUrl | Should -Be "http://sites.sharepoint.com"
                        $result.SuiteBarBrandingElementHtml | Should -Be "<div>Test</div>"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should -Be $true
                    }

                    It "Should properly configure the suite bar for the Web Application" {
                        Set-TargetResource @testParams
                    }
                }

                Context -Name "None of the optional parameters passed" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            WebAppUrl = "http://sites.sharepoint.com"
                        }

                        Mock -CommandName Get-SPWebApplication -MockWith {
                            DisplayName = "Test Web App"
                            Url = "http://sites.sharepoint.com"
                            SuiteBarBrandingElementHtml = "<div>Test</div>"
                        }
                    }

                    It "return error that sp2013 parameters are required" {
                        { Set-TargetResource @testParams } | Should -Throw "You need to specify a value for the SuiteBarBrandingElementHtml parameter with SharePoint 2013"
                    }
                }

                Context -Name "Configured values does not match" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            WebAppUrl                   = "http://sites.sharepoint.com"
                            SuiteBarBrandingElementHtml = "<div>Test</div>"
                        }

                        Mock -CommandName Get-SPWebApplication -MockWith {
                            return @(@{
                                    DisplayName                 = "Test Web App"
                                    Url                         = "http://sites.sharepoint.com"
                                    SuiteBarBrandingElementHtml = "<div>Another Test</div>"
                                })
                        }
                    }

                    It "Should return false from the test method" {
                        Test-TargetResource @testParams | Should -Be $false
                    }
                }
            }
            elseif ($Global:SPDscHelper.CurrentStubBuildNumber.Major -ge 16)
            {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Build -lt 10000)
                {
                    Context -Name "Only all SP2016 parameters passed for a SP2016 environment" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                WebAppUrl                         = "http://sites.sharepoint.com"
                                SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                                SuiteNavBrandingLogoTitle         = "LogoTitle"
                                SuiteNavBrandingLogoUrl           = "http://sites.sharepoint.com/images/logo.gif"
                                SuiteNavBrandingText              = "Suite Bar Text"
                                SuiteBarBrandingElementHtml       = "<div>Test</div>"
                            }

                            Mock -CommandName Get-SPWebApplication -MockWith {
                                $webApp = @{
                                    DisplayName = "Test Web App"
                                    Url = "http://sites.sharepoint.com"
                                    It "Should properly configure the suite bar for the Web Application"
                                    {
                                        Set-TargetResource @testParams
                                    }
                                    $results.WebAppUrl | Should -Be "http://sites.sharepoint.com"
                                    $results.SuiteNavBrandingLogoNavigationUrl | Should -Be "http://sites.sharepoint.com"
                                    $results.SuiteNavBrandingLogoTitle | Should -Be "LogoTitle"
                                    $results.SuiteNavBrandingLogoUrl | Should -Be "http://sites.sharepoint.com/images/logo.gif"
                                    $results.SuiteNavBrandingText | Should -Be "Suite Bar Text"
                                    $results.SuiteBarBrandingElementHtml | Should -Be "<div>Test</div>"
                                    Context -Name "Only some SP2016 parameters passed for a SP2016 environment" -Fixture
                                    {
                                        $testParams = @{
                                            WebAppUrl = "http://sites.sharepoint.com"
                                            SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                                            SuiteNavBrandingText = "Suite Bar Text"
                                            Context -Name "Only some SP2016 parameters passed for a SP2016 environment" -Fixture
                                            {
                                                BeforeAll
                                                {
                                                    $testParams = @{
                                                        WebAppUrl = "http://sites.sharepoint.com"
                                                        SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                                                        SuiteNavBrandingText = "Suite Bar Text"
                                                    }

                                                    Mock -CommandName Get-SPWebApplication -MockWith
                                                    {
                                                        $webApp = @{
                                                            DisplayName = "Test Web App"
                                                            Url = "http://sites.sharepoint.com"
                                                            SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                                                            SuiteNavBrandingLogoTitle = "LogoTitle"
                                                            SuiteNavBrandingLogoUrl = "http://sites.sharepoint.com/images/logo.gif"
                                                            SuiteNavBrandingText = "Suite Bar Text"
                                                            SuiteBarBrandingElementHtml = "<div>Test</div>"
                                                        }
                                                        It "successfully returns the suite bar properties"
                                                        {
                                                            $results = Get-TargetResource @testParams
                                                            $results.WebAppUrl | Should be "http://sites.sharepoint.com"
                                                            $results.SuiteNavBrandingLogoNavigationUrl | Should be "http://sites.sharepoint.com"
                                                            $results.SuiteNavBrandingLogoTitle | Should be "LogoTitle"
                                                            $results.SuiteNavBrandingLogoUrl | Should be "http://sites.sharepoint.com/images/logo.gif"
                                                            $results.SuiteNavBrandingText | Should be "Suite Bar Text"
                                                        }

                                                        It "Should properly configure the suite bar for the Web Application"
                                                        {
                                                            Set-TargetResource @testParams
                                                        }

                                                        Context -Name "Configured values does not match" -Fixture
                                                        {
                                                            BeforeAll
                                                            {
                                                                $testParams = @{
                                                                    WebAppUrl = "http://sites.sharepoint.com"
                                                                    SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                                                                    Context -Name "None of the optional parameters passed" -Fixture
                                                                    {
                                                                        $testParams = @{
                                                                            WebAppUrl = "http://sites.sharepoint.com"
                                                                            Test-TargetResource @testParams | Should -Be $false
                                                                        }
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    Context -Name "Using resource with SharePoint 2019" -Fixture
                                                                    {
                                                                        BeforeAll
                                                                        {
                                                                            $testParams = @{
                                                                                WebAppUrl = "http://sites.sharepoint.com"
                                                                            }
                                                                            It "return error that sp2016 parameters are required"
                                                                            {
                                                                                { Set-TargetResource @testParams 
                                                                                } | Should -Throw "You need to specify a value for either SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl, SuiteNavBrandingText or SuiteBarBrandingElementHtml with SharePoint 2016"
                                                                            }
                                                                        }
                                                                        finally
                                                                        {
                                                                            Invoke-TestCleanup
                                                                        }
                        SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
                        SuiteNavBrandingLogoTitle         = "LogoTitle"
                        SuiteNavBrandingLogoUrl           = "http://sites.sharepoint.com/images/logo.gif"
                        SuiteNavBrandingText              = "Suite Bar Text"
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                                DisplayName                       = "Test Web App"
                                Url                               = "http://sites.sharepoint.com"
                                SuiteNavBrandingLogoNavigationUrl = "http://anothersite.sharepoint.com"
                                SuiteNavBrandingLogoTitle         = "AnotherLogoTitle"
                                SuiteNavBrandingLogoUrl           = "http://anothersite.sharepoint.com/images/logo.gif"
                                SuiteNavBrandingText              = "Another Suite Bar Text"
                            }) }

                    It "Should return false from the test method" {
                        Test-TargetResource @testParams | Should -Be $false
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
