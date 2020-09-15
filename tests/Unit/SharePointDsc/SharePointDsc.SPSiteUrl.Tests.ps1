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
$script:DSCResourceName = 'SPSiteUrl'
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
    Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
        InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
            Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

            # Mocks for all contexts
            Mock -CommandName Remove-SPSiteUrl -MockWith { }
            Mock -CommandName Set-SPSiteUrl -MockWith { }
            Mock -CommandName Get-SPSiteUrl -MockWith {
                if ($global:SpDscSPSiteUrlRanOnce -eq $false)
                {
                    $global:SpDscSPSiteUrlRanOnce = $true
                    return @(
                        @{
                            Url  = "http://sharepoint.contoso.intra"
                            Zone = "Default"
                        },
                        @{
                            Url  = "http://sharepoint.contoso.com"
                            Zone = "Intranet"
                        },
                        @{
                            Url  = "https://sharepoint.contoso.com"
                            Zone = "Internet"
                        }
                    )
                }
                else
                {
                    return $null
                }
            }
            $global:SpDscSPSiteUrlRanOnce = $false

            # Test contexts
            Context -Name "No zones specified" -Fixture {
                $testParams = @{
                    Url = "http://sharepoint.contoso.intra"
                }

                Mock -CommandName Get-SPSite -MockWith { return $null }

                It "Should return null for Intranet zone from the get method" {
                    (Get-TargetResource @testParams).Intranet | Should -BeNullOrEmpty
                }

                It "Should create a new site from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "No zone specified. Please specify a zone"
                }
            }

            Context -Name "The site collection does not exist" -Fixture {
                $testParams = @{
                    Url      = "http://site.sharepoint.com"
                    Intranet = "http://sharepoint.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return $null
                }

                It "Should return null for Intranet zone from the get method" {
                    (Get-TargetResource @testParams).Intranet | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return true from the test method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified site $($testParams.Url) does not exist"
                }
            }

            Context -Name "The site is not a host named site collection" -Fixture {
                $testParams = @{
                    Url      = "http://sharepoint.contoso.intra"
                    Intranet = "http://sharepoint.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        HostHeaderIsSiteName = $false
                    }
                }

                It "Should return null for Intranet zone from the get method" {
                    (Get-TargetResource @testParams).Intranet | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified site $($testParams.Url) is not a Host Named Site Collection"
                }
            }

            Context -Name "The site exists, but the specified Intranet is already in use" -Fixture {
                $testParams = @{
                    Url      = "http://sharepoint.contoso.intra"
                    Intranet = "http://sharepoint.contoso.com"
                    Internet = "http://custom.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        HostHeaderIsSiteName = $true
                    }
                }

                Mock -CommandName Get-SPSiteUrl -MockWith {
                    return @(
                        @{
                            Url  = "http://sharepoint.contoso.intra"
                            Zone = "Default"
                        }
                    )
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified URL $($testParams.Intranet) (Zone: Intranet) is already assigned to a site collection"
                }
            }

            Context -Name "The site exists, but the specified Internet is already in use" -Fixture {
                $testParams = @{
                    Url      = "http://sharepoint.contoso.intra"
                    Internet = "http://custom.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        HostHeaderIsSiteName = $true
                    }
                }

                Mock -CommandName Get-SPSiteUrl -MockWith {
                    return @(
                        @{
                            Url  = "http://sharepoint.contoso.intra"
                            Zone = "Default"
                        }
                    )
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified URL $($testParams.Internet) (Zone: Internet) is already assigned to a site collection"
                }
            }

            Context -Name "The site exists, but the specified Extranet is already in use" -Fixture {
                $testParams = @{
                    Url      = "http://sharepoint.contoso.intra"
                    Extranet = "http://sharepoint.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        HostHeaderIsSiteName = $true
                    }
                }

                Mock -CommandName Get-SPSiteUrl -MockWith {
                    return @(
                        @{
                            Url  = "http://sharepoint.contoso.intra"
                            Zone = "Default"
                        }
                    )
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified URL $($testParams.Extranet) (Zone: Extranet) is already assigned to a site collection"
                }
            }

            Context -Name "The site exists, but the specified Custom is already in use" -Fixture {
                $testParams = @{
                    Url    = "http://sharepoint.contoso.intra"
                    Custom = "http://sharepoint.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        HostHeaderIsSiteName = $true
                    }
                }

                Mock -CommandName Get-SPSiteUrl -MockWith {
                    return @(
                        @{
                            Url  = "http://sharepoint.contoso.intra"
                            Zone = "Default"
                        }
                    )
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified URL $($testParams.Custom) (Zone: Custom) is already assigned to a site collection"
                }
            }

            Context -Name "The site exists and the Internet zone should not be configured" -Fixture {
                $testParams = @{
                    Url      = "http://sharepoint.contoso.intra"
                    Intranet = "http://sharepoint.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        HostHeaderIsSiteName = $true
                    }
                }

                It "Should return values for the Intranet and Internet zones from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Intranet | Should -Be "http://sharepoint.contoso.com"
                    $result.Internet | Should -Be "https://sharepoint.contoso.com"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $global:SpDscSPSiteUrlRanOnce = $false
                It "Should configure the specified values in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPSiteUrl
                }
            }

            Context -Name "The site exists, but the Internet and Intranet zones are not configured" -Fixture {
                $testParams = @{
                    Url      = "http://sharepoint.contoso.intra"
                    Intranet = "http://sharepoint.contoso.com"
                    Internet = "http://custom.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        HostHeaderIsSiteName = $true
                    }
                }

                Mock -CommandName Get-SPSiteUrl -MockWith {
                    if ($global:SpDscSPSiteUrlRanOnce -eq $false)
                    {
                        $global:SpDscSPSiteUrlRanOnce = $true
                        return @(
                            @{
                                Url  = "http://sharepoint.contoso.intra"
                                Zone = "Default"
                            },
                            @{
                                Url  = "http://sharepoint.contoso.com"
                                Zone = "Extranet"
                            },
                            @{
                                Url  = "https://sharepoint.contoso.com"
                                Zone = "Custom"
                            }
                        )
                    }
                    else
                    {
                        return $null
                    }
                }

                $global:SpDscSPSiteUrlRanOnce = $false
                It "Should return values for the Intranet and Internet zones from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Extranet | Should -Be "http://sharepoint.contoso.com"
                    $result.Custom | Should -Be "https://sharepoint.contoso.com"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $global:SpDscSPSiteUrlRanOnce = $false
                It "Should configure the specified values in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPSiteUrl
                    Assert-MockCalled Set-SPSiteUrl
                }
            }

            Context -Name "The site exists, but the Extranet and Custom zones are not configured" -Fixture {
                $testParams = @{
                    Url      = "http://sharepoint.contoso.intra"
                    Extranet = "http://sharepoint.contoso.com"
                    Custom   = "http://custom.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        HostHeaderIsSiteName = $true
                    }
                }

                Mock -CommandName Get-SPSiteUrl -MockWith {
                    if ($global:SpDscSPSiteUrlRanOnce -eq $false)
                    {
                        $global:SpDscSPSiteUrlRanOnce = $true
                        return @(
                            @{
                                Url  = "http://sharepoint.contoso.intra"
                                Zone = "Default"
                            },
                            @{
                                Url  = "http://sharepoint.contoso.com"
                                Zone = "Intranet"
                            },
                            @{
                                Url  = "https://sharepoint.contoso.com"
                                Zone = "Internet"
                            }
                        )
                    }
                    else
                    {
                        return $null
                    }
                }

                $global:SpDscSPSiteUrlRanOnce = $false
                It "Should return values for the Intranet and Internet zones from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Intranet | Should -Be "http://sharepoint.contoso.com"
                    $result.Internet | Should -Be "https://sharepoint.contoso.com"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $global:SpDscSPSiteUrlRanOnce = $false
                It "Should configure the specified values in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPSiteUrl
                    Assert-MockCalled Set-SPSiteUrl
                }
            }

            Context -Name "The site exists and all zones are configured correctly" -Fixture {
                $testParams = @{
                    Url      = "http://sharepoint.contoso.intra"
                    Intranet = "http://sharepoint.contoso.com"
                    Internet = "https://sharepoint.contoso.com"
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        HostHeaderIsSiteName = $true
                    }
                }

                $global:SpDscSPSiteUrlRanOnce = $false
                It "Should return values for the Intranet and Internet zones from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Intranet | Should -Be "http://sharepoint.contoso.com"
                    $result.Internet | Should -Be "https://sharepoint.contoso.com"
                }

                $global:SpDscSPSiteUrlRanOnce = $false
                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
